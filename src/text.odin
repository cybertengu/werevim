package main

import "core:os"
import "core:strings"
import "core:fmt"
import "vendor:sdl2"
import "vendor:sdl2/ttf"

FONT_SIZE :: 16
FONT_TEXTURE_SIZE :: 1024
FONT_FILENAME :: "assets/fonts/JetBrainsMonoNerdFontMono-Regular.ttf"
DEAFAULT_FALLBACK_FONT_FILENAME :: "/usr/share/fonts/google-noto-sans-mono-cjk-vf-fonts/NotoSansMonoCJK-VF.ttc"

font : ^ttf.Font
fallback_font : ^ttf.Font
white : sdl2.Color = {255, 255, 255, 255}
fontTexture : ^sdl2.Texture
glyphs : map[rune]sdl2.Rect
atlas_x, atlas_y, atlas_row_h : i32
cell_width, cell_height : i32

initFont :: proc(filename : string)
{
    font = open_font(filename)
    if font == nil
    {
        sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong trying to open a font file: %s", sdl2.GetError())
        os.exit(1)
    }

    backup_font, ok := find_fallback_font()
    if ok
    {
        fallback_font = open_font(backup_font)
        if fallback_font == nil
        {
            sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong trying to open a backup font file: %s", sdl2.GetError())
        }
    }
    else
    {
        fallback_font = open_font(DEAFAULT_FALLBACK_FONT_FILENAME)
        if fallback_font == nil
        {
            sdl2.LogMessage(i32(sdl2.LogCategory.APPLICATION), sdl2.LogPriority.CRITICAL, "Something went wrong trying to open a backup font file: %s", sdl2.GetError())
        }
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
    update_cell_size()
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
            clear_glyph_atlas()
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

find_fallback_font :: proc() -> (path : string, ok : bool)
{
    desc := os.Process_Desc{
        command = []string{"fc-match", "-f", "%{file}", "monospace:lang=ja"},
    }
    state, stdout, stderr, err := os.process_exec(desc, context.temp_allocator)
    text := strings.trim_space(string(stdout))
    if err != nil
    {
        fmt.eprintfln("Something went wrong trying to find a fallback font: %v", err)
        ok = false
    }

    if state.exit_code != 0
    {
        if len(stderr) > 0
        {
            fmt.eprintfln("fc-match failed (exit %d): %s", state.exit_code, strings.trim_space(string(stderr)))
        }
        fmt.eprintfln("Something went wrong trying to get a font: %d", state.exit_code)
    }

    if text == ""
    {
        fmt.eprintln("No fallback font found. Will try to go to default fallback font.")
        ok = false
        path = DEAFAULT_FALLBACK_FONT_FILENAME
    }
    else
    {
        path = text
        ok = true
    }

    return
}

resize_font :: proc(size : i32)
{
    if size < 1
    {
        fmt.eprintfln("Ignoring invalid font size: %d", size)
        return
    }

    ok := ttf.SetFontSize(font, size)
    if ok == -1
    {
        fmt.eprintfln("Cannot set the font size: %d", size)
        return
    }

    if fallback_font != nil
    {
        ttf.SetFontSize(fallback_font, size)
    }

    clear_glyph_atlas()
    update_cell_size()
}

clear_glyph_atlas :: proc()
{
    clear(&glyphs)   
    atlas_x = 0
    atlas_y = 0
    atlas_row_h = 0
}

update_cell_size :: proc()
{
    advance : i32
    ttf.GlyphMetrics32(font, 'M', nil, nil, nil, nil, &advance)
    cell_width = max(advance, 1)
    cell_height = max(ttf.FontLineSkip(font), 1)
}

