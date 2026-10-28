package main

Cursor_Shape :: enum
{
    Block,
    Horizontal,
    Vertical,
}

Mode_Info :: struct
{
    shape : Cursor_Shape,
    cell_percentage : int,
    attr_id : int,
}

Cursor :: struct
{
    row, col : int,
    modes : [dynamic]Mode_Info,
    current_mode : int,
}

mode_info_set :: proc(cursor : ^Cursor, mode_info : Array)
{
    /*
        clear(&modes)
        for each entity in mode_info
            Map -> read the three keys (with defaults: Block, 100, 0)
            append to modes
    */
    clear(&cursor.modes)
    for entry in mode_info
    {
        info := Mode_Info{.Block, 100, 0}
        
        attrs, ok := entry.(Map)
        if ok
        {
            for pair in attrs
            {
                key, is_string := pair.key.(string)
                if !is_string
                {
                    continue
                }
                
                switch key
                {
                    case "cursor_shape":
                        shape, is_shape := pair.value.(string)
                        if !is_shape
                        {
                            info.shape = .Block
                        }
                        else
                        {
                            switch shape
                            {
                                case "block":
                                    info.shape = .Block
                                case "horizontal":
                                    info.shape = .Horizontal
                                case "vertical":
                                    info.shape = .Vertical
                            }
                        }
                    case "cell_percentage":
                        percentage, is_percentage := pair.value.(i64)
                        if !is_percentage
                        {
                            continue
                        }
                        
                        info.cell_percentage = int(percentage)
                    case "attr_id":
                        attr_id, is_attr_id := pair.value.(i64)
                        if !is_attr_id
                        {
                            continue
                        }
                        
                        info.attr_id = int(attr_id)
                }
            }
        }

        append(&cursor.modes, info)
    }
}

mode_change :: proc(cursor : ^Cursor, idx : int)
{
    cursor.current_mode = idx
}

current_mode_info :: proc(cursor : ^Cursor) -> Mode_Info
{
    if cursor.current_mode < len(cursor.modes) && cursor.current_mode >= 0
    {
        return cursor.modes[cursor.current_mode]
    }

    return Mode_Info{.Block, 100, 0}
}
