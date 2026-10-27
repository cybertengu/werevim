package main

import "core:testing"

@(test)
test_grid_resize :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 4, 3)
    defer delete(grid.cells)
    
    testing.expect_value(t, grid.width, 4)
    testing.expect_value(t, grid.height, 3)
    
    for cell in grid.cells
    {
        testing.expect_value(t, cell, Cell{' ', 0})
    }
}

@(test)
test_grid_resize_twice :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 4, 3)
    defer delete(grid.cells)
    grid.cells[0] = Cell{'x', 5}

    grid_resize(&grid, 2, 5)
    
    testing.expect_value(t, len(grid.cells), 10)
    testing.expect_value(t, grid.width, 2)
    testing.expect_value(t, grid.height, 5)
    
    for cell in grid.cells
    {
        testing.expect_value(t, cell, Cell{' ', 0})
    }

}

@(test)
test_grid_simple_line :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 5, 2)   
    defer delete(grid.cells)
    
    cells := Array{
        Value(Array{Value(string("h")), Value(i64(1))}),
        Value(Array{Value(string("i")), Value(i64(1))}),
    }
    
    grid_line(&grid, 0, 0, cells)
    
    testing.expect_value(t, grid.cells[0], Cell{'h', 1})
    testing.expect_value(t, grid.cells[1], Cell{'i', 1})
    testing.expect_value(t, grid.cells[2], Cell{' ', 0}) // Untouched.
}

@(test)
test_grid_line_col_start :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 5, 2)   
    defer delete(grid.cells)
    
    cells := Array{
        Value(Array{Value(string("h")), Value(i64(1))}),
        Value(Array{Value(string("i")), Value(i64(1))}),
    }
    
    grid_line(&grid, 0, 2, cells)
    
    testing.expect_value(t, grid.cells[1], Cell{' ', 0})
    testing.expect_value(t, grid.cells[2], Cell{'h', 1})
    testing.expect_value(t, grid.cells[3], Cell{'i', 1})
    testing.expect_value(t, grid.cells[4], Cell{' ', 0})
}

@(test)
test_grid_line_second_row :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 5, 2)   
    defer delete(grid.cells)
    
    cells := Array{
        Value(Array{Value(string("h")), Value(i64(1))}),
        Value(Array{Value(string("i")), Value(i64(1))}),
    }
    
    grid_line(&grid, 1, 0, cells)
    
    testing.expect_value(t, grid.cells[4], Cell{' ', 0})
    testing.expect_value(t, grid.cells[5], Cell{'h', 1})
    testing.expect_value(t, grid.cells[6], Cell{'i', 1})
    testing.expect_value(t, grid.cells[7], Cell{' ', 0})
}

@(test)
test_grid_line_hl_carry_over :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 5, 2)   
    defer delete(grid.cells)
    
    cells := Array{
        Value(Array{Value(string("h")), Value(i64(1))}),
        Value(Array{Value(string("i"))}),
    }
    
    grid_line(&grid, 1, 0, cells)
    
    testing.expect_value(t, grid.cells[4], Cell{' ', 0})
    testing.expect_value(t, grid.cells[5], Cell{'h', 1})
    testing.expect_value(t, grid.cells[6], Cell{'i', 1})
    testing.expect_value(t, grid.cells[7], Cell{' ', 0})
}

@(test)
test_grid_line_repeat :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 5, 2)   
    defer delete(grid.cells)
    
    cells := Array{
        Value(Array{Value(string("-")), Value(i64(1)), Value(i64(3))}),
    }
    
    grid_line(&grid, 1, 0, cells)
    
    testing.expect_value(t, grid.cells[4], Cell{' ', 0})
    testing.expect_value(t, grid.cells[5], Cell{'-', 1})
    testing.expect_value(t, grid.cells[6], Cell{'-', 1})
    testing.expect_value(t, grid.cells[7], Cell{'-', 1})
}

@(test)
test_grid_line_off_the_edge :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 5, 2)   
    defer delete(grid.cells)
    
    cells := Array{
        Value(Array{Value(string("x")), Value(i64(1)), Value(i64(4))}),
    }
    
    grid_line(&grid, 0, 3, cells)
    
    testing.expect_value(t, grid.cells[2], Cell{' ', 0})
    testing.expect_value(t, grid.cells[3], Cell{'x', 1})
    testing.expect_value(t, grid.cells[4], Cell{'x', 1})
    testing.expect_value(t, grid.cells[5], Cell{' ', 0})
}

@(test)
test_grid_line_bad_row :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 5, 2)   
    defer delete(grid.cells)
    
    cells := Array{
        Value(Array{Value(string("x")), Value(i64(1)), Value(i64(4))}),
    }
    
    grid_line(&grid, 2, 0, cells)
    
    testing.expect_value(t, grid.cells[2], Cell{' ', 0})
    testing.expect_value(t, grid.cells[3], Cell{' ', 0})
    testing.expect_value(t, grid.cells[4], Cell{' ', 0})
    testing.expect_value(t, grid.cells[5], Cell{' ', 0})
}

@(test)
test_grid_line_wide_char :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 5, 2)   
    defer delete(grid.cells)
    
    cells := Array{
        Value(Array{Value(string("\u6f22")), Value(i64(1))}),
        Value(Array{Value(string(""))}),

    }
    
    grid_line(&grid, 0, 0, cells)
    
    testing.expect_value(t, grid.cells[0], Cell{'\u6f22', 1})
    testing.expect_value(t, grid.cells[1], Cell{0, 1})
}

@(test)
test_grid_scroll_up_by_1 :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 3, 4)
    defer delete(grid.cells)

    fill_row(&grid, 0, 'a')
    fill_row(&grid, 1, 'b')
    fill_row(&grid, 2, 'c')
    fill_row(&grid, 3, 'd')

    grid_scroll(&grid, 0, 4, 0, 3, 1)
    
    expect_row(t, &grid, 0, "bbb")
    expect_row(t, &grid, 1, "ccc")
    expect_row(t, &grid, 2, "ddd")
}

@(test)
test_grid_scroll_down_by_1 :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 3, 4)
    defer delete(grid.cells)

    fill_row(&grid, 0, 'a')
    fill_row(&grid, 1, 'b')
    fill_row(&grid, 2, 'c')
    fill_row(&grid, 3, 'd')

    grid_scroll(&grid, 0, 4, 0, 3, -1)
    
    expect_row(t, &grid, 1, "aaa")
    expect_row(t, &grid, 2, "bbb")
    expect_row(t, &grid, 3, "ccc")
}

@(test)
test_grid_scroll_up_by_2 :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 3, 4)
    defer delete(grid.cells)

    fill_row(&grid, 0, 'a')
    fill_row(&grid, 1, 'b')
    fill_row(&grid, 2, 'c')
    fill_row(&grid, 3, 'd')

    grid_scroll(&grid, 0, 4, 0, 3, 2)
    
    expect_row(t, &grid, 0, "ccc")
    expect_row(t, &grid, 1, "ddd")
}

@(test)
test_grid_scroll_inner_region :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 3, 4)
    defer delete(grid.cells)

    fill_row(&grid, 0, 'a')
    fill_row(&grid, 1, 'b')
    fill_row(&grid, 2, 'c')
    fill_row(&grid, 3, 'd')

    grid_scroll(&grid, 1, 3, 0, 3, 1)
    
    expect_row(t, &grid, 0, "aaa")
    expect_row(t, &grid, 1, "ccc")
    expect_row(t, &grid, 3, "ddd")
}

@(test)
test_grid_scroll_partial_width :: proc(t : ^testing.T)
{
    grid : Grid
    grid_resize(&grid, 3, 4)
    defer delete(grid.cells)

    fill_row(&grid, 0, 'a')
    fill_row(&grid, 1, 'b')
    fill_row(&grid, 2, 'c')
    fill_row(&grid, 3, 'd')

    grid_scroll(&grid, 0, 4, 1, 3, 1)
    
    expect_row(t, &grid, 0, "abb")
    expect_row(t, &grid, 1, "bcc")
    expect_row(t, &grid, 2, "cdd")
    expect_row(t, &grid, 3, "d")
}
