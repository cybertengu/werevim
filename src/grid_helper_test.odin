package main

import "core:testing"

fill_row :: proc(grid : ^Grid, row : int, character : rune)
{
    for col in 0..<grid.width
    {
        grid.cells[row * grid.width + col] = Cell{character, 0}
    }
}

expect_row :: proc(t : ^testing.T, grid : ^Grid, row : int, expected : string, loc := #caller_location)
{
    col := 0
    for character in expected
    {
        if !testing.expect(t, col < grid.width, "String too long.", loc = loc)
        {
            return
        }

        testing.expect_value(t, grid.cells[row * grid.width + col].character, character, loc = loc)
        col += 1
    }
}
