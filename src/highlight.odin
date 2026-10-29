package main

Highlight :: struct
{
    foreground : Maybe(u32),
    background : Maybe(u32),
    reverse : bool,
}

Highlights :: struct
{
    default_fg, default_bg : u32,
    attrs : map[int]Highlight,
}

hl_attr_define :: proc(table : ^Highlights, id : int, attrs : Map)
{
    hl : Highlight
    for pair in attrs
    {
        key, ok := pair.key.(string)
        if !ok
        {
            continue
        }
        
        switch key
        {
            case "foreground":
                value, is_ok := pair.value.(i64)
                if !is_ok
                {
                    continue
                }
                
                hl.foreground = u32(value)
            case "background":
                value, is_ok := pair.value.(i64)
                if !is_ok
                {
                    continue
                }
                
                hl.background = u32(value)
            case "reverse":
                value, is_ok := pair.value.(bool)
                if !is_ok
                {
                    continue
                }
                
                hl.reverse = value
        }
    }

    table.attrs[id] = hl
}

highlight_colors :: proc(table : ^Highlights, id : int) -> (fg, bg : u32)
{
    fg = table.default_fg
    bg = table.default_bg
    hl, found := table.attrs[id]
    if found
    {
        if value, ok := hl.background.?; ok
        {
            bg = value
        }
        if value, ok := hl.foreground.?; ok
        {
            fg = value
        }
        if hl.reverse
        {
            temp := fg
            fg = bg
            bg = temp
        }
    }
    
    return
}

color_rgb :: proc(color : u32) -> (r, g, b : u8)
{
    r = u8(color >> 16)
    g = u8(color >> 8)
    b = u8(color)
    
    return
}
