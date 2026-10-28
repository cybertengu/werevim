package main

import "core:fmt"

// Decodes every complete message at the front of pending into messages,
// then removes those bytes. A partial message stays in pending.
drain_messages :: proc(pending : ^[dynamic]u8, messages : ^[dynamic]Value) -> Decode_Status
{
    offset := 0
    decode_status : Decode_Status = .Invalid
    loop: for
    {
        value, consumed, status := decode(pending[offset:])
        
        switch status
        {
            case .Invalid, .Need_More:
                decode_status = status
                break loop
            case .Ok:
                append(messages, value)
                offset += consumed
        }
    }
    
    remove_range(pending, 0, offset)
    return decode_status
}

handle_message :: proc(grid : ^Grid, table : ^Highlights, msg : Value)
{
    array, ok := msg.(Array)
    if !ok
    {
        fmt.eprintln("Message isn't an array.")
        return
    }
    
    if len(array) < 3
    {
        fmt.eprintfln("Response has too few elements: %v", len(array))
        return
    }

    kind, is_i64 := array[0].(i64)
    if !is_i64
    {
        fmt.eprintfln("Message kind is not a number.")
        return
    }
    
    switch kind
    {
        case 1:
            if len(array) < 4
            {
                fmt.eprintfln("Message has too few elements: %v", len(array))
                return
            }
            else
            {
                fmt.printfln("Response to: %v", array[1])
            }
            
            _, is_nil := array[2].(Nil)
            if !is_nil
            {
                fmt.eprintfln("This is an error, saw: %v", array[2])   
                return
            }
        case 2:
            method, is_string := array[1].(string)
            if !is_string
            {
                fmt.eprintln("Not a valid method name.")
                return
            }

            if method == "redraw"
            {
                params, is_array2 := array[2].(Array)   
                
                if !is_array2
                {
                    fmt.eprintfln("Not an array, saw: %v", array[2])
                    return
                }

                for item in params
                {
                    batch, is_array3 := item.(Array)
                    if !is_array3
                    {
                        fmt.eprintfln("Item is not an array: %v", item)
                        return
                    }

                    if len(batch) < 1
                    {
                        fmt.eprintln("Batch has too few elements.")
                        return
                    }

                    name, is_name_string := batch[0].(string)
                    if !is_name_string
                    {
                        fmt.eprintfln("Name wasn't a string: %v", batch[0])
                        return
                    }
                    
                    for element in batch[1:]
                    {
                        args, is_array := element.(Array)
                        if !is_array
                        {
                            continue
                        }
                        
                        switch name
                        {
                            case "grid_resize":
                                if len(args) < 3
                                {
                                    continue
                                }
                                
                                width, is_width := args[1].(i64)
                                height, is_height := args[2].(i64)
                                if !is_width || !is_height
                                {
                                    continue   
                                }
                                
                                grid_resize(grid, int(width), int(height))
                            case "grid_line":
                                if len(args) < 4
                                {
                                    continue
                                }
                                
                                row, is_row_i64 := args[1].(i64)
                                col, is_col_i64 := args[2].(i64)
                                cells, is_cells := args[3].(Array)
                                if !is_row_i64 || !is_col_i64 || !is_cells
                                {
                                    continue
                                }

                                grid_line(grid, int(row), int(col), cells)
                            case "grid_clear":
                                grid_clear(grid)
                            case "flush":
                                grid_dump(grid)
                                index := (grid.height - 2) * grid.width + 0
                                id := grid.cells[index].highlight_id
                                fg, bg := highlight_colors(&app.table, id)
                            case "grid_scroll":
                                if len(args) < 6
                                {
                                    continue
                                }

                                top, is_top_i64 := args[1].(i64)
                                bot, is_bot_i64 := args[2].(i64)
                                left, is_left_i64 := args[3].(i64)
                                right, is_right_i64 := args[4].(i64)
                                rows, is_rows_i64 := args[5].(i64)
                                if !is_top_i64 || !is_bot_i64 || !is_left_i64 || !is_right_i64 || !is_rows_i64
                                {
                                    continue
                                }
                                
                                grid_scroll(grid, int(top), int(bot), int(left), int(right), int(rows))
                            case "grid_cursor_goto":
                                if len(args) < 3
                                {
                                    continue
                                }
                                
                                row, is_row := args[1].(i64)
                                col, is_col := args[2].(i64)
                                if !is_row || !is_col
                                {
                                    continue
                                }
                                
                                grid.cursor_row = int(row)
                                grid.cursor_col = int(col)
                            case "default_colors_set":
                                if len(args) < 2
                                {
                                    continue
                                }
                                
                                foreground, is_fg := args[0].(i64)
                                background, is_bg := args[1].(i64)
                                if !is_fg || !is_bg
                                {
                                    continue
                                }
                                
                                table.default_bg = u32(background)
                                table.default_fg = u32(foreground)
                            case "hl_attr_define":
                                if len(args) < 2
                                {
                                    continue
                                }

                                id, is_id := args[0].(i64)
                                attrs, is_attrs := args[1].(Map)
                                if !is_id || !is_attrs
                                {
                                    continue
                                }
                                
                                hl_attr_define(table, int(id), attrs)
                            case "option_set", "set_icon", "set_title", "chdir", "hl_group_set", "update_menu", "win_viewport", "mode_info_set", "mode_change", "mouse_on":
                            case:
                                fmt.printfln("Didn't handle this name for messages: %s", name)
                        }
                    }
                }
            }
            else
            {
                fmt.eprintfln("Unknown notification: %v", method)
                return
            }
        case:
            fmt.eprintfln("Unknown message kind: %v", kind)
            return
    }
}
