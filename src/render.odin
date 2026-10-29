package main

import "vendor:sdl2"

render :: proc(app : ^App)
{
    r, g, b := color_rgb(app.table.default_bg)
    sdl2.SetRenderDrawColor(app.renderer, r, g, b, 255)
    sdl2.RenderClear(app.renderer)

    for row in 0..<app.grid.height
    {
        for col in 0..<app.grid.width
        {
            dst := sdl2.Rect{i32(col) * cell_width, i32(row) * cell_height, cell_width, cell_height}
            cell := app.grid.cells[row * app.grid.width + col]
            _, bg := highlight_colors(&app.table, cell.highlight_id)
            if bg != app.table.default_bg
            {
                r, g, b = color_rgb(bg)
                sdl2.SetRenderDrawColor(app.renderer, r, g, b, 255)
                sdl2.RenderFillRect(app.renderer, &dst)
            }
        }
    }
    
    for row in 0..<app.grid.height
    {
        for col in 0..<app.grid.width
        {
            cell := app.grid.cells[row * app.grid.width + col]
            c := cell.character
            if c > ' ' && c <= '~'
            {
                fg, _ := highlight_colors(&app.table, cell.highlight_id)
                r, g, b = color_rgb(fg)
                src := glyphs[c]
                dst := sdl2.Rect{i32(col) * cell_width, i32(row) * cell_height, src.w, src.h}
                sdl2.SetTextureColorMod(fontTexture, r, g, b)
                sdl2.RenderCopy(app.renderer, fontTexture, &src, &dst)
            }
        }
    }
    
    draw_cursor(app)
    
    sdl2.RenderPresent(app.renderer)
}

draw_cursor :: proc(app : ^App)
{
    x := i32(app.cursor.col) * cell_width
    y := i32(app.cursor.row) * cell_height
    if app.cursor.row < 0 || app.cursor.row >= app.grid.height || app.cursor.col < 0 || app.cursor.col >= app.grid.width
    {
        return
    }

    cursor_color, text_color : u32
    info := current_mode_info(&app.cursor)
    cell := app.grid.cells[app.cursor.row * app.grid.width + app.cursor.col]
    if info.attr_id == 0
    {
        fg, bg := highlight_colors(&app.table, cell.highlight_id)
        cursor_color = fg
        text_color = bg
    }
    else
    {
        fg, bg := highlight_colors(&app.table, info.attr_id)
        cursor_color = bg
        text_color = fg
    }

    r, g, b := color_rgb(cursor_color)
    dst := sdl2.Rect{x, y, cell_width, cell_height}
    pct := i32(info.cell_percentage)
    switch info.shape
    {
        case .Block:
        case .Vertical:
            dst.w = max(cell_width * pct / 100, 1)
        case .Horizontal:
            dst.h = max(cell_height * pct / 100, 1)
            dst.y = y + cell_height - dst.h
    }

    sdl2.SetRenderDrawColor(app.renderer, r, g, b, 255)
    sdl2.RenderFillRect(app.renderer, &dst)
    c := cell.character
    if c > ' ' && c <= '~' && info.shape == .Block
    {
        r, g, b = color_rgb(text_color)
        src := glyphs[c]
        dst_glyph := sdl2.Rect{x, y, src.w, src.h}
        sdl2.SetTextureColorMod(fontTexture, r, g, b)
        sdl2.RenderCopy(app.renderer, fontTexture, &src, &dst_glyph)
    }
}
