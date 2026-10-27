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
