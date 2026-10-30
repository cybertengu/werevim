package main

import "core:testing"

@(test)
test_cursor_parse :: proc(t : ^testing.T)
{
    mode_info := Array{
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("block"))},
            Pair{Value(string("cell_percentage")), Value(i64(100))},
        }),
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("vertical"))},
            Pair{Value(string("cell_percentage")), Value(i64(25))},
        })
    }
    cursor : Cursor
    defer delete(cursor.modes)
    mode_info_set(&cursor, mode_info)
    
    if !testing.expect_value(t, len(cursor.modes), 2) {return}
    testing.expect_value(t, cursor.modes[0], Mode_Info{.Block, 100, 0})
    testing.expect_value(t, cursor.modes[1], Mode_Info{.Vertical, 25, 0})
}

@(test)
test_cursor_mode_change :: proc(t : ^testing.T)
{
    mode_info := Array{
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("block"))},
            Pair{Value(string("cell_percentage")), Value(i64(100))},
        }),
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("vertical"))},
            Pair{Value(string("cell_percentage")), Value(i64(25))},
        })
    }
    cursor : Cursor
    defer delete(cursor.modes)
    mode_info_set(&cursor, mode_info)
    mode_change(&cursor, 1)
    cursor.style_enabled = true
    
    testing.expect_value(t, current_mode_info(&cursor), Mode_Info{.Vertical, 25, 0})

    mode_change(&cursor, 0)
    testing.expect_value(t, current_mode_info(&cursor), Mode_Info{.Block, 100, 0})
}

@(test)
test_cursor_mode_style_disabled_is_block :: proc(t : ^testing.T)
{
    mode_info := Array{
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("block"))},
            Pair{Value(string("cell_percentage")), Value(i64(100))},
        }),
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("vertical"))},
            Pair{Value(string("cell_percentage")), Value(i64(25))},
        })
    }
    cursor : Cursor
    defer delete(cursor.modes)
    mode_info_set(&cursor, mode_info)
    mode_change(&cursor, 1)
    cursor.style_enabled = false
    
    testing.expect_value(t, current_mode_info(&cursor), Mode_Info{.Block, 100, 0})
}

@(test)
test_cursor_missing_keys :: proc(t : ^testing.T)
{
    mode_info := Array{
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("vertical"))},
        }),
    }
    cursor : Cursor
    defer delete(cursor.modes)
    mode_info_set(&cursor, mode_info)
    
    if !testing.expect_value(t, len(cursor.modes), 1) {return}
    testing.expect_value(t, cursor.modes[0], Mode_Info{.Vertical, 100, 0})
}

@(test)
test_cursor_bad_index :: proc(t : ^testing.T)
{
    cursor : Cursor
    defer delete(cursor.modes)
    info := current_mode_info(&cursor)
    
    testing.expect_value(t, info, Mode_Info{.Block, 100, 0})
    
    mode_info := Array{
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("block"))},
            Pair{Value(string("cell_percentage")), Value(i64(100))},
        }),
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("vertical"))},
            Pair{Value(string("cell_percentage")), Value(i64(25))},
        })
    }
    cursor2 : Cursor
    defer delete(cursor2.modes)
    mode_info_set(&cursor2, mode_info)
    mode_change(&cursor2, 99)
    
    testing.expect_value(t, current_mode_info(&cursor2), Mode_Info{.Block, 100, 0})
}

@(test)
test_cursor_set_twice :: proc(t : ^testing.T)
{   
    mode_info := Array{
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("block"))},
            Pair{Value(string("cell_percentage")), Value(i64(100))},
        }),
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("vertical"))},
            Pair{Value(string("cell_percentage")), Value(i64(25))},
        })
    }
    cursor : Cursor
    defer delete(cursor.modes)
    mode_info_set(&cursor, mode_info)
    
    mode_info = Array{
        Value(Map{
            Pair{Value(string("cursor_shape")), Value(string("horizontal"))},
            Pair{Value(string("cell_percentage")), Value(i64(20))},
        }),
    }
    mode_info_set(&cursor, mode_info)
    
    if !testing.expect_value(t, len(cursor.modes), 1) {return}
    testing.expect_value(t, cursor.modes[0], Mode_Info{.Horizontal, 20, 0})
}
