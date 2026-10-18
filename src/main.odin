package main

import "vendor:sdl2"
import "vendor:sdl2/ttf"
import "core:os"
import "core:fmt"
import "core:strings"

SCREEN_WIDTH :: 1024
SCREEN_HEIGHT :: 768
FONT_SIZE :: 48
FONT_TEXTURE_SIZE :: 512
NUM_GLYPHS :: 128

app : App
font : ^ttf.Font
white : sdl2.Color = {255, 255, 255, 255}
fontTexture : ^sdl2.Texture
glyphs : [NUM_GLYPHS]sdl2.Rect
FONT_FILENAME :: "assets/fonts/JetBrainsMonoNerdFontMono-Regular.ttf"

main :: proc()
{
    running : bool = true
    event : sdl2.Event

    initSDL()
    defer cleanup()

    initFont(FONT_FILENAME)

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

initFont :: proc(filename : string)
{
    surface, text : ^sdl2.Surface
    dest : sdl2.Rect
    c : [2]u8
    g : ^sdl2.Rect
    cstr : cstring

    cFilename := strings.clone_to_cstring(filename)
    defer delete(cFilename)
    font = ttf.OpenFont(cFilename, FONT_SIZE)

    if font == nil
    {
        sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong to get the font file %s\n", cFilename)
        os.exit(1)
    }

    surface = sdl2.CreateRGBSurface(0, FONT_TEXTURE_SIZE, FONT_TEXTURE_SIZE, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000)

    if surface == nil
    {
        sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong to create a surface.\n")
        os.exit(1)
    }
    
    for i := ' '; i <= '~'; i += 1
    {
        c[0] = u8(i)
        c[1] = 0

        cstr = cstring(&c[0])

        text = ttf.RenderUTF8_Blended(font, cstr, white)

        if text == nil
        {
            sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong te create a text surface: %s\n", ttf.GetError())
            os.exit(1)
        }

        ttf.SizeText(font, cstr, &dest.w, &dest.h)

        if dest.x + dest.w >= FONT_TEXTURE_SIZE
        {
            dest.x = 0

            dest.y += dest.h + 1

            if dest.y + dest.h >= FONT_TEXTURE_SIZE
            {
                sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Size wasn't big enough %dx%d to address the font: %s\n", FONT_TEXTURE_SIZE, FONT_TEXTURE_SIZE, sdl2.GetError())
                os.exit(1)
            }
        }

        sdl2.SetSurfaceBlendMode(surface, sdl2.BlendMode.NONE)
        sdl2.BlitSurface(text, nil, surface, &dest)

        g = &glyphs[i]

        g.x = dest.x
        g.y = dest.y
        g.w = dest.w
        g.h = dest.h

        sdl2.FreeSurface(text)

        dest.x += dest.w
    }

    fontTexture = sdl2.CreateTextureFromSurface(app.renderer, surface)
    
    if fontTexture == nil
    {
        sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong getting a font texture: %s\n", sdl2.GetError())
        os.exit(1)
    }

    sdl2.FreeSurface(surface)
}
