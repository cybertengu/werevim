package main

import "vendor:sdl2"
import "vendor:sdl2/ttf"
import "core:os"
import "core:fmt"

SCREEN_WIDTH :: 1024
SCREEN_HEIGHT :: 768

NVIM_BYTES :: 0
NVIM_EXITED :: 1

app : App
NVIM_EVENT : u32

main :: proc()
{
    app = {}
    defer delete(app.grid.cells)
    defer reader_stop(&app.reader)
    defer delete(app.table.attrs)
    event : sdl2.Event
    nvim, ok := nvim_start()
    if !ok
    {
        fmt.eprintln("Couldn't set up Neovim.")
        os.exit(1)
    }
    app.nvim = nvim
    defer nvim_stop(&app.nvim)

    initSDL()
    defer cleanup()
    NVIM_EVENT = sdl2.RegisterEvents(1) // Return my own event type number.

    initFont(FONT_FILENAME)

    args := Array{Value(i64(80)), Value(i64(24)), Map{
        Pair{Value(string("ext_linegrid")), Value(bool(true))},
        Pair{Value(string("rgb")), Value(bool(true))},
    },}
    _, result := nvim_request(&app.nvim, "nvim_ui_attach", args)
    if !result
    {
        fmt.eprintln("Couldn't send a request to Neovim")
        os.exit(1)
    }

    reader_start(&app.reader, &app.nvim, NVIM_EVENT)
    app.is_running = true
    defer delete(app.pending)
    if app.reader.thread == nil
    {
        fmt.eprintln("Couldn't start the thread.")
        return
    }
    
    app.needs_redraw = true

    for app.is_running
    {
        sdl2.WaitEvent(&event)
        handle_event(event, &app)

        for sdl2.PollEvent(&event)
        {
            handle_event(event, &app)
        }
        
        if app.needs_redraw
        {
            sdl2.SetRenderDrawColor(app.renderer, 8, 8, 8, 255)
            sdl2.RenderClear(app.renderer)

            dst := sdl2.Rect{x = 20, y = 20, w = FONT_TEXTURE_SIZE, h = FONT_TEXTURE_SIZE}
            sdl2.RenderCopy(app.renderer, fontTexture, nil, &dst)

            sdl2.RenderPresent(app.renderer)
            app.needs_redraw = false
        }
    }
}

handle_event :: proc(event : sdl2.Event, app : ^App)
{
    if u32(event.type) == NVIM_EVENT
    {
        if event.user.code == NVIM_EXITED
        {
            app.nvim.exited = true
            app.is_running = false
            return
        }

        // TODO(David): Finish this up.
        reader_take_bytes(&app.reader, &app.pending)
        
        messages : [dynamic]Value
        defer delete(messages)
        status := drain_messages(&app.pending, &messages)

        for msg in messages
        {
            handle_message(&app.grid, &app.table, msg)
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
            app.is_running = false

        case sdl2.EventType.KEYDOWN:
            if event.key.keysym.sym == sdl2.Keycode.ESCAPE
            {
                app.is_running = false
            }
        case sdl2.EventType.WINDOWEVENT:
            #partial switch event.window.event
            {
                case .EXPOSED, .SIZE_CHANGED, .SHOWN, .RESTORED:
                    app.needs_redraw = true
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
}

initSDL :: proc()
{
    rendererFlag : sdl2.RendererFlags = {sdl2.RendererFlag.ACCELERATED, sdl2.RendererFlag.PRESENTVSYNC}
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

    ttf.Quit()

    sdl2.DestroyRenderer(app.renderer)

    sdl2.DestroyWindow(app.window)

    sdl2.Quit()
}
