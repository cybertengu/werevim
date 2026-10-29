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

    sdl2.RenderPresent(app.renderer)
}
