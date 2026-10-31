package main

import "core:os"
import "core:strings"
import "core:fmt"
import "vendor:sdl2"
import "vendor:sdl2/ttf"

FONT_SIZE :: 16
FONT_TEXTURE_SIZE :: 1024
FONT_FILENAME :: "assets/fonts/JetBrainsMonoNerdFontMono-Regular.ttf"
FALLBACK_FONT_FILENAME :: "/usr/share/fonts/google-noto-sans-mono-cjk-vf-fonts/NotoSansMonoCJK-VF.ttc"

font : ^ttf.Font
fallback_font : ^ttf.Font
white : sdl2.Color = {255, 255, 255, 255}
fontTexture : ^sdl2.Texture
glyphs : map[rune]sdl2.Rect
atlas_x, atlas_y, atlas_row_h : i32
advance, cell_width, cell_height : i32

initFont :: proc(filename : string)
{
    font = open_font(filename)
    if font == nil
    {
        sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong trying to open a font file: %s", sdl2.GetError())
        os.exit(1)
    }

    fallback_font = open_font(FALLBACK_FONT_FILENAME)
    if fallback_font == nil
    {
        sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.WARN, "Something went wrong trying to get the backup font file: %s", sdl2.GetError())
    }
    
    surface : ^sdl2.Surface
    surface = sdl2.CreateRGBSurface(0, FONT_TEXTURE_SIZE, FONT_TEXTURE_SIZE, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000)

    if surface == nil
    {
        sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong to create a surface.\n")
        os.exit(1)
    }

    fontTexture = sdl2.CreateTextureFromSurface(app.renderer, surface)
    sdl2.SetTextureBlendMode(fontTexture, .BLEND)
    
    if fontTexture == nil
    {
        sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong getting a font texture: %s\n", sdl2.GetError())
        os.exit(1)
    }

    sdl2.FreeSurface(surface)
    ttf.GlyphMetrics32(font, 'M', nil, nil, nil, nil, &advance)
    cell_width = advance
    cell_height = ttf.FontLineSkip(font)
}

get_glyph :: proc(ch : rune) -> (rect : sdl2.Rect, ok :  bool)
{
    if cache, found := glyphs[ch]; found
    {
        return cache, cache.w > 0
    }
    
    use := font
    if ttf.GlyphIsProvided32(font, ch) == 0 && fallback_font != nil && ttf.GlyphIsProvided32(fallback_font, ch) != 0
    {
        use = fallback_font
    }

    text := ttf.RenderGlyph32_Blended(use, ch, white) 
    if text == nil
    {
        glyphs[ch] = {}
        fmt.eprintfln("Can't render U+%04X: %s", ch, ttf.GetError())
        return {}, false
    }
    
    if atlas_x + text.w >= FONT_TEXTURE_SIZE
    {
        atlas_x = 0
        atlas_y += atlas_row_h + 1
        atlas_row_h = 0

        if atlas_y + text.h >= FONT_TEXTURE_SIZE
        {
            clear(&glyphs)   
            atlas_x = 0
            atlas_y = 0
            atlas_row_h = 0
        }
    }
    
    dest := sdl2.Rect{atlas_x, atlas_y, text.w, text.h}
    sdl2.UpdateTexture(fontTexture, &dest, text.pixels, text.pitch)
    glyphs[ch] = dest
    atlas_x += text.w
    atlas_row_h = max(atlas_row_h, text.h)
    sdl2.FreeSurface(text)
    return dest, true
}

open_font :: proc(filename : string) -> ^ttf.Font
{
    cFilename := strings.clone_to_cstring(filename)
    defer delete(cFilename)
    f := ttf.OpenFont(cFilename, FONT_SIZE)
    return f
}
