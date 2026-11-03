package main

import "vendor:sdl2"
import "vendor:sdl2/ttf"
import "core:os"
import "core:fmt"
import "core:strings"
@(require) import "core:mem"

// TODO(David): Live resize on Wayland. Look into making a release version and storing it in github. nvim_get_option_info2 was_set instead of comparing against nvim's default guifont string.

SCREEN_WIDTH :: 1024
SCREEN_HEIGHT :: 768

NVIM_BYTES :: 0
NVIM_EXITED :: 1

app : App
NVIM_EVENT : u32
current_font_size : i32
bundled_font_path : string

main :: proc()
{
    when ODIN_DEBUG
    {
        track : mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer
        {
            for _, entry in track.allocation_map
            {
                fmt.eprintfln("%v leaked %v bytes", entry.location, entry.size)
            }
            
            mem.tracking_allocator_destroy(&track)
        }
    }

    app = {}
    app.mouse.enabled = true
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

    bundled_font_path = strings.clone(font_full_path)
    initFont(font_full_path)
    current_font_size = FONT_SIZE

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

    is_set_title, _ := nvim_command(&app.nvim, "set title")
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

        app.last_nvim_message_at = sdl2.GetTicks()
        if app.showing_not_responding
        {
            set_window_title(app.window, app.nvim_title)
            app.showing_not_responding = false
        }

        return
    }

    #partial switch event.type
    {
        case sdl2.EventType.QUIT:
            nvim_silent := app.last_nvim_message_at < app.quit_requested_at
            waited_long := sdl2.GetTicks() - app.quit_requested_at >= 2000

            if app.quit_msgid != 0
            {
                if nvim_silent && waited_long
                {
                    app.is_running = false
                    app.force_quit = true
                }
                else if nvim_silent
                {
                    set_window_title(app.window, "Werevim (not responding, click X again to force quit)")
                    app.showing_not_responding = true
                }
            }
            else
            {
                is_confirm_qa, msgid := nvim_command(&app.nvim, "confirm qa")
                app.quit_msgid = msgid
                if !is_confirm_qa
                {
                    app.is_running = false
                }
                app.quit_requested_at = sdl2.GetTicks()
            }

        case sdl2.EventType.KEYDOWN:
            mod := event.key.keysym.mod
            sym := event.key.keysym.sym
            if (.LCTRL in mod || .RCTRL in mod) && (.LSHIFT in mod || .RSHIFT in mod) && sym == .v
            {
                result := paste_clipboard(&app.nvim)
                if !result
                {
                    fmt.eprintln("Couldn't send paste to nvim.")
                }

                break
            }

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
                    resize_grid_to_window()
            }
        case .MOUSEBUTTONDOWN, .MOUSEBUTTONUP:
            action := event.type == sdl2.EventType.MOUSEBUTTONDOWN ? "press" : "release"
            x := event.button.x
            y := event.button.y
            row, col := pixel_to_cell(x, y)
            name, is_name := mouse_button_name(event.button.button)
            if !is_name
            {
                break
            }

            app.mouse.last_row = row
            app.mouse.last_col = col
            if event.type == sdl2.EventType.MOUSEBUTTONDOWN
            {
                if app.mouse.held_button == ""
                {
                    app.mouse.held_button = name
                }
            }
            else
            {
                if name == app.mouse.held_button
                {
                    app.mouse.held_button = ""
                }
            }

            prefix := modifier_prefix(sdl2.GetModState(), true)
            if app.mouse.enabled
            {
                nvim_input_mouse(&app.nvim, name, action, prefix, row, col)
            }
        case .MOUSEMOTION:
            if app.mouse.held_button == ""
            {
                break
            }

            x := event.motion.x
            y := event.motion.y
            row, col := pixel_to_cell(x, y)
            if app.mouse.last_row != row || app.mouse.last_col != col
            {
                prefix := modifier_prefix(sdl2.GetModState(), true)
                if app.mouse.enabled
                {
                    nvim_input_mouse(&app.nvim, app.mouse.held_button, "drag", prefix, row, col)
                }
                app.mouse.last_row = row
                app.mouse.last_col = col
            }
        case .MOUSEWHEEL:
            vertical_direction, horizontal_direction : string
            x := event.wheel.x
            y := event.wheel.y
            if y > 0
            {
                vertical_direction = "up"
            }
            else if y < 0
            {
                vertical_direction = "down"
            }

            if x > 0
            {
                horizontal_direction = "right"
            }
            else if x < 0
            {
                horizontal_direction = "left"
            }

            mx, my : i32
            sdl2.GetMouseState(&mx, &my)
            if app.mouse.enabled
            {
                row, col := pixel_to_cell(mx, my)
                prefix := modifier_prefix(sdl2.GetModState(), true)
                for _ in 0..<abs(y)
                {
                   nvim_input_mouse(&app.nvim, "wheel", vertical_direction, prefix, row, col)
                }

                for _ in 0..<abs(x)
                {
                    nvim_input_mouse(&app.nvim, "wheel", horizontal_direction, prefix, row, col)
                }
            }
    }
}

mouse_button_name :: proc(button : u8) -> (name : string, ok : bool)
{
    if button == sdl2.BUTTON_LEFT
    {
        name = "left"
        ok = true
    }
    else if button == sdl2.BUTTON_MIDDLE
    {
        name = "middle"
        ok = true
    }
    else if button == sdl2.BUTTON_RIGHT
    {
        name = "right"
        ok = true
    }
    else if button == sdl2.BUTTON_X1
    {
        name = "x1"
        ok = true
    }
    else if button == sdl2.BUTTON_X2
    {
        name = "x2"
        ok = true
    }

    return
}

pixel_to_cell :: proc(x, y : i32) -> (row, col : int)
{
    win_w, win_h : i32
    sdl2.GetWindowSize(app.window, &win_w, &win_h)
    out_w, out_h : i32
    sdl2.GetRendererOutputSize(app.renderer, &out_w, &out_h)
    px, py : i32
    if win_w > 0 && win_h > 0
    {
        px = x * out_w / win_w
        py = y * out_h / win_h
    }
    else
    {
        px = x
        py = y
    }

    col = int(px / cell_width)
    row = int(py / cell_height)
    col = clamp(col, 0, app.ui_cols - 1)
    row = clamp(row, 0, app.ui_rows - 1)

    return
}

resize_grid_to_window :: proc()
{
    app.needs_redraw = true
    cols, rows := window_grid_size()
    if cols != app.ui_cols || rows != app.ui_rows
    {
        nvim_ui_try_resize(&app.nvim, cols, rows)
        app.ui_cols = cols
        app.ui_rows = rows
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
    quit_requested_at, last_nvim_message_at : u32,
    quit_msgid : int,
    force_quit : bool,
    nvim_title : string,
    showing_not_responding : bool,
    mouse : Mouse,
}

Mouse :: struct
{
    enabled : bool,
    held_button : string,
    last_row, last_col : int,
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
    sdl2.HideWindow(app.window)
    nvim_quit(&app.nvim, app.force_quit)
    reader_stop(&app.reader)
    nvim_close(&app.nvim)
    delete(app.cursor.modes)
    delete(app.grid.cells)
    delete(app.table.attrs)
    delete(app.pending)
    delete(app.nvim_title)
    delete(glyphs)
    delete(bundled_font_path)
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

set_window_title :: proc(window : ^sdl2.Window, title : string)
{
    c_title := strings.clone_to_cstring(title, context.temp_allocator)
    sdl2.SetWindowTitle(window, c_title)
}

paste_clipboard :: proc(nvim : ^Nvim) -> bool
{
    text := sdl2.GetClipboardText()
    defer sdl2.free(rawptr(text))
    output := string(text)
    ok : bool = true
    if len(output) > 0
    {
        ok = nvim_paste(nvim, output, true, -1)
    }
    return ok
}

