package main

import "core:fmt"
import "core:unicode/utf8"

Cell :: struct
{
    character : rune,
    highlight_id : int,
}

Grid :: struct
{
    width, height : int,
    cells : []Cell, // One flat array: index = row * width + col,
}

grid_resize :: proc(grid : ^Grid, width, height : int)
{
    if width < 0 || height < 0
    {
        return
    }
    delete(grid.cells)
    grid.cells = make([]Cell, width * height)
    grid.width = width
    grid.height = height
    grid_clear(grid)
}

grid_line :: proc(grid : ^Grid, row, col_start : int, cells : Array)
{
    if row < 0 || row >= grid.height
    {
        return
    }

    col := col_start
    highlight := 0
    for cell in cells
    {
        character : rune
        cell_array, ok := cell.(Array)
        if !ok || len(cell_array) < 1
        {
            continue
        }
        
        text, ok_string := cell_array[0].(string)
        if !ok_string
        {
            continue
        }

        if text == ""
        {
            character = 0 // Right half of a wide character.
        }
        else
        {
            character, _ = utf8.decode_rune_in_string(text)
        }
        
        if len(cell_array) >= 2
        {
            id, is_i64_ok := cell_array[1].(i64)
            if is_i64_ok
            {
                highlight = int(id)
            }
        }
    
        repeat := 1
        if len(cell_array) >= 3
        {
            value, is_i64_ok := cell_array[2].(i64)
            if is_i64_ok
            {
                repeat = int(value)
            }
        }    
    
        for _ in 0..<repeat
        {
            if col >= 0 && col < grid.width
            {
                grid.cells[row * grid.width + col] = Cell{character, highlight}
            }

            col += 1
            
            if col >= grid.width
            {
                return
            }
        }
    }
}

grid_clear :: proc(grid : ^Grid)
{
    for &cell in grid.cells
    {
        cell = Cell{' ', 0}
    }
}

grid_dump :: proc(grid : ^Grid)
{
    for row := 0; row < grid.height; row += 1
    {
        for height := 0; height < grid.width; height += 1
        {
            cell := grid.cells[row * grid.width + height]
            if cell.character == 0
            {
                continue
            }
            
            fmt.print(cell.character)
        }

        fmt.println()
    }
}
