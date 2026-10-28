package main

import "core:testing"

@(test)
test_highlight_fg_bg_set :: proc(t : ^testing.T)
{
    attrs := Map{
        Pair{Value(string("foreground")), Value(i64(0x111111))},
        Pair{Value(string("background")), Value(i64(0x222222))},
    }
    table : Highlights = {default_fg = 0xffffff, default_bg = 0x000000}
    defer delete(table.attrs)
    hl_attr_define(&table, 1, attrs)    
    fg, bg := highlight_colors(&table, 1)
    
    testing.expect_value(t, fg, u32(0x111111))
    testing.expect_value(t, bg, u32(0x222222))
}

@(test)
test_highlight_fg_missing :: proc(t : ^testing.T)
{
    attrs := Map{
        Pair{Value(string("background")), Value(i64(0x222222))},
    }
    table : Highlights = {default_fg = 0xffffff, default_bg = 0x000000}
    defer delete(table.attrs)
    hl_attr_define(&table, 1, attrs)    
    fg, bg := highlight_colors(&table, 1)
    
    testing.expect_value(t, fg, u32(0xffffff))
    testing.expect_value(t, bg, u32(0x222222))
}

@(test)
test_highlight_unknown_id :: proc(t : ^testing.T)
{
    table : Highlights = {default_fg = 0xffffff, default_bg = 0x000000}
    defer delete(table.attrs)
    fg, bg := highlight_colors(&table, 99)
    
    testing.expect_value(t, fg, u32(0xffffff))
    testing.expect_value(t, bg, u32(0x000000))
}

// Id 0 is never defined; it always means defaults.
@(test)
test_highlight_id_zero :: proc(t : ^testing.T)
{
    table : Highlights = {default_fg = 0xffffff, default_bg = 0x000000}
    defer delete(table.attrs)
    fg, bg := highlight_colors(&table, 0)
    
    testing.expect_value(t, fg, u32(0xffffff))
    testing.expect_value(t, bg, u32(0x000000))
}

@(test)
test_highlight_reverse :: proc(t : ^testing.T)
{
    attrs := Map{
        Pair{Value(string("reverse")), Value(bool(true))},
    }
    table : Highlights = {default_fg = 0xffffff, default_bg = 0x000000}
    defer delete(table.attrs)
    hl_attr_define(&table, 1, attrs)
    fg, bg := highlight_colors(&table, 1)
    
    testing.expect_value(t, bg, u32(0xffffff))
    testing.expect_value(t, fg, u32(0x000000))
}

@(test)
test_highlight_reverse_with_colors :: proc(t : ^testing.T)
{
    attrs := Map{
        Pair{Value(string("foreground")), Value(i64(0x111111))},
        Pair{Value(string("background")), Value(i64(0x222222))},
        Pair{Value(string("reverse")), Value(bool(true))},
    }
    table : Highlights = {default_fg = 0xffffff, default_bg = 0x000000}
    defer delete(table.attrs)
    hl_attr_define(&table, 1, attrs)
    fg, bg := highlight_colors(&table, 1)
    
    testing.expect_value(t, bg, u32(0x111111))
    testing.expect_value(t, fg, u32(0x222222))
}

@(test)
test_highlight_unknown_key :: proc(t : ^testing.T)
{
    attrs := Map{
        Pair{Value(string("bold")), Value(bool(true))},
        Pair{Value(string("background")), Value(i64(0x222222))},
        Pair{Value(string("blend")), Value(i64(50))},
    }
    table : Highlights = {default_fg = 0xffffff, default_bg = 0x000000}
    defer delete(table.attrs)
    hl_attr_define(&table, 1, attrs)
    fg, bg := highlight_colors(&table, 1)
    
    testing.expect_value(t, bg, u32(0x222222))
    testing.expect_value(t, fg, u32(0xffffff))
}

@(test)
test_highlight_redefine :: proc(t : ^testing.T)
{
    attrs := Map{
        Pair{Value(string("foreground")), Value(i64(0x111111))},
        Pair{Value(string("reverse")), Value(bool(true))},
    }
    table : Highlights = {default_fg = 0xffffff, default_bg = 0x000000}
    defer delete(table.attrs)
    hl_attr_define(&table, 1, attrs)
    attrs = Map{
        Pair{Value(string("background")), Value(i64(0x222222))},
    }
    hl_attr_define(&table, 1, attrs)
    fg, bg := highlight_colors(&table, 1)
    
    testing.expect_value(t, fg, u32(0xffffff))
    testing.expect_value(t, bg, u32(0x222222))
}
