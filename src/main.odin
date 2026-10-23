package main

import "vendor:sdl2"
import "vendor:sdl2/ttf"
import "core:os"
import "core:fmt"

SCREEN_WIDTH :: 1024
SCREEN_HEIGHT :: 768

app : App

main :: proc()
{
    running : bool = true
    event : sdl2.Event
    nvim, ok := nvim_start()
    if !ok
    {
        fmt.eprintln("Couldn't set up Neovim.")
        os.exit(1)
    }
    defer nvim_stop(&nvim)

    initSDL()
    defer cleanup()

    initFont(FONT_FILENAME)

    args := Array{Value(i64(80)), Value(i64(24)), Map{
        Pair{Value(string("ext_linegrid")), Value(bool(true))},
        Pair{Value(string("rgb")), Value(bool(true))},
    },}
    msgid, result := nvim_request(&nvim, "nvim_ui_attach", args)
    if !result
    {
        fmt.eprintln("Couldn't set a request to Neovim")
        os.exit(1)
    }
    fmt.println(msgid)
    chunk : [4096]byte
    pending : [dynamic]u8
    defer delete(pending)
    counter : int
    for counter < 10
    {
        counter += 1
        n, err := os.read(nvim.from_nvim, chunk[:])
        if err != nil
        {
            fmt.eprintfln("%v", err)
            break
        }

        append(&pending, ..chunk[:n])
        value, consumed, ok := decode(pending[:])
        if ok
        {
            fmt.printfln("%v", value)
            copy(pending[:], pending[consumed:])
            resize(&pending, len(pending) - consumed)
        }
        else
        {
            break
        }
        free_all(context.temp_allocator)
    }

    for running
    {
        for sdl2.PollEvent(&event)
        {
            #partial switch event.type
            {
                case sdl2.EventType.QUIT:
                    running = false

                case sdl2.EventType.KEYDOWN:
                    if event.key.keysym.sym == sdl2.Keycode.ESCAPE
                    {
                        running = false
                    }
            }
        }
        
        sdl2.SetRenderDrawColor(app.renderer, 8, 8, 8, 255)
        sdl2.RenderClear(app.renderer)

        dst := sdl2.Rect{x = 20, y = 20, w = FONT_TEXTURE_SIZE, h = FONT_TEXTURE_SIZE}
        sdl2.RenderCopy(app.renderer, fontTexture, nil, &dst)

        sdl2.RenderPresent(app.renderer)
    }
}

App :: struct
{
    window : ^sdl2.Window,
    renderer : ^sdl2.Renderer,
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
