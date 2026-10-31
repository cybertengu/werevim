package main

import "vendor:sdl2"
import "vendor:sdl2/ttf"
import "core:os"
import "core:fmt"
import "core:strings"

// TODO(David): force quit on second x click. Mouse. Font size / guifont. Find the fallback font. Live resize on Wayland. Look into making a release version and storing it in github.

SCREEN_WIDTH :: 1024
SCREEN_HEIGHT :: 768

NVIM_BYTES :: 0
NVIM_EXITED :: 1

app : App
NVIM_EVENT : u32

main :: proc()
{
    app = {}
    event : sdl2.Event
    nvim, ok := nvim_start(os.args[1:])
    if !ok
    {
        fmt.eprintln("Couldn't set up Neovim.")
        os.exit(1)
    }
    app.nvim = nvim

    initSDL()
    NVIM_EVENT = sdl2.RegisterEvents(1) // Return my own event type number.

    executable_directory, find_dir_error := os.get_executable_directory(context.temp_allocator)
    if find_dir_error != nil
    {
        fmt.eprintfln("Couldn't find the executable directory: %v", find_dir_error)
        os.exit(1)
    }
    font_full_path, full_dir_error := os.join_path([]string{executable_directory, FONT_FILENAME}, context.temp_allocator)
    if full_dir_error != nil
    {
        fmt.eprintfln("Couldn't create the full path to the font file: %s", full_dir_error)
        os.exit(1)
    }

    initFont(font_full_path)

    cols, rows := window_grid_size()
    app.ui_cols = cols
    app.ui_rows = rows
    args := Array{Value(i64(cols)), Value(i64(rows)), Map{
        Pair{Value(string("ext_linegrid")), Value(bool(true))},
        Pair{Value(string("rgb")), Value(bool(true))},
    },}
    _, result := nvim_request(&app.nvim, "nvim_ui_attach", args)
    if !result
    {
        fmt.eprintln("Couldn't send a request to Neovim.")
        os.exit(1)
    }

    is_set_title := nvim_command(&app.nvim, "set title")
    if !is_set_title
    {
        fmt.eprintln("Couldn't set up the title.")
    }

    nvim_ui_try_resize(&app.nvim, app.ui_cols, app.ui_rows)
    reader_start(&app.reader, &app.nvim, NVIM_EVENT)
    app.is_running = true
    if app.reader.thread == nil
    {
        fmt.eprintln("Couldn't start the thread.")
        return
    }
    
    app.needs_redraw = true
    defer shutdown()

    for app.is_running
    {
        sdl2.WaitEvent(&event)
        handle_event(&event, &app)

        for sdl2.PollEvent(&event)
        {
            handle_event(&event, &app)
        }
        
        if app.needs_redraw
        {
            render(&app)
            app.needs_redraw = false
        }
    }
}

handle_event :: proc(event : ^sdl2.Event, app : ^App)
{
    if u32(event.type) == NVIM_EVENT
    {
        if event.user.code == NVIM_EXITED
        {
            app.nvim.exited = true
            app.is_running = false
            return
        }

        reader_take_bytes(&app.reader, &app.pending)
        
        messages : [dynamic]Value
        defer delete(messages)
        status := drain_messages(&app.pending, &messages)

        for msg in messages
        {
            handle_message(app, msg)
        }

        free_all(context.temp_allocator)
        
        if status == .Invalid
        {
            fmt.eprintfln("Byte stream is broken.")
        }
        return
    }

    #partial switch event.type
    {
        case sdl2.EventType.QUIT:
            if !nvim_command(&app.nvim, "confirm qa")
            {
                app.is_running = false
            }

        case sdl2.EventType.KEYDOWN:
            mod := event.key.keysym.mod
            sym := event.key.keysym.sym
            ch := rune(sym)
            name, ok := key_name(sym)   
            if ok
            {
                prefix := modifier_prefix(mod, true)
                value := fmt.tprintf("<%s%s>", prefix, name)
                nvim_input(&app.nvim, value)
            }
            else if (.LCTRL in mod || .RCTRL in mod || .LALT in mod) && ch >= ' ' && ch <= '~'
            {
                char_name : string
                if ch == '<'
                {
                    char_name = "lt"
                }
                else if ch == ' '
                {
                    char_name = "Space"
                }
                else
                {
                    char_name = fmt.tprintf("%c", ch)
                }

                prefix := modifier_prefix(mod, false)
                value := fmt.tprintf("<%s%s>", prefix, char_name)
                nvim_input(&app.nvim, value)
            }
        case sdl2.EventType.TEXTINPUT:
            mod := sdl2.GetModState()
            if .LCTRL in mod || .RCTRL in mod || .LALT in mod
            {
                break
            }

            text := string(cstring(&event.text.text[0]))
            fixed_keys, allocated := strings.replace_all(text, "<", "<lt>")
            defer if allocated do delete(fixed_keys)
            nvim_input(&app.nvim, fixed_keys)
        case sdl2.EventType.WINDOWEVENT:
            #partial switch event.window.event
            {
                case .EXPOSED, .SHOWN, .RESTORED:
                    app.needs_redraw = true
                // TODO(David): Resize is laggy on Wayland (events only arrive after the drap; smooth on X11).
                // If changes are made, update run_and_build.sh file.
                // Ideas: sdl2.AddEventWatch to render from inside SDL's event callback; check newer SDL3/sdl2-compat
                // versions; native SDL3 port.
                case .SIZE_CHANGED:
                    app.needs_redraw = true
                    cols, rows := window_grid_size()
                    if cols != app.ui_cols || rows != app.ui_rows
                    {
                        nvim_ui_try_resize(&app.nvim, cols, rows)
                        app.ui_cols = cols
                        app.ui_rows = rows
                    }
            }
    }
}

App :: struct
{
    window : ^sdl2.Window,
    renderer : ^sdl2.Renderer,
    reader : Reader,
    nvim : Nvim,
    is_running : bool,
    pending : [dynamic]u8,
    needs_redraw : bool,
    grid : Grid,
    table : Highlights,
    cursor : Cursor,
    ui_cols, ui_rows : int,
}

initSDL :: proc()
{
    rendererFlag : sdl2.RendererFlags = {sdl2.RendererFlag.ACCELERATED}
    windowFlags : sdl2.WindowFlags = {sdl2.WindowFlag.RESIZABLE, sdl2.WindowFlag.ALLOW_HIGHDPI}

    if sdl2.Init(sdl2.INIT_VIDEO) < 0
    {
        fmt.printf("Couldn't initialize SDL: %s\n", sdl2.GetError())
        os.exit(1)
    }

    app.window = sdl2.CreateWindow("Werevim", sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, windowFlags)

    if app.window == nil
    {
        fmt.printf("Couldn't initialize window: %s\n", sdl2.GetError())
        os.exit(1)
    }

    app.renderer = sdl2.CreateRenderer(app.window, -1, rendererFlag)
    
    if app.renderer == nil
    {
        fmt.printf("Couldn't initialize renderer: %s\n", sdl2.GetError())
        os.exit(1)
    }

    if ttf.Init() < 0
    {
        fmt.printf("Couldn't initialize SDL TTF: %s\n", ttf.GetError())
        os.exit(1)
    }
}

cleanup :: proc()
{
    ttf.CloseFont(font)
    if fallback_font != nil
    {
        ttf.CloseFont(fallback_font)
    }

    ttf.Quit()

    sdl2.DestroyRenderer(app.renderer)

    sdl2.DestroyWindow(app.window)

    sdl2.Quit()
}

shutdown :: proc()
{
    nvim_quit(&app.nvim)
    reader_stop(&app.reader)
    nvim_close(&app.nvim)
    delete(app.cursor.modes)
    delete(app.grid.cells)
    delete(app.table.attrs)
    delete(app.pending)
    cleanup()
}

window_grid_size :: proc() -> (cols, rows : int)
{
    w, h : i32
    sdl2.GetRendererOutputSize(app.renderer, &w, &h)    
    cols = max(int(w) / int(cell_width), 1)
    rows = max(int(h) / int(cell_height), 1)
    return
}

set_window_title :: proc(window : ^sdl2.Window, title : cstring)
{
    sdl2.SetWindowTitle(window, title)
}
