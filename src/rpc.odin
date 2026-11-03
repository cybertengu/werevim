package main

import "core:fmt"
import "core:strings"
import "core:strconv"

NVIM_DEFAULT_GUIFONT :: "Source Code Pro,DejaVu Sans Mono,Courier New,monospace"

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

handle_message :: proc(app : ^App, msg : Value)
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
            
            _, is_nil := array[2].(Nil)
            if !is_nil
            {
                fmt.eprintfln("This is an error, saw: %v", array[2])   
                return
            }

            app.quit_msgid = 0
            app.quit_requested_at = 0
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
                                
                                grid_resize(&app.grid, int(width), int(height))
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

                                grid_line(&app.grid, int(row), int(col), cells)
                            case "grid_clear":
                                grid_clear(&app.grid)
                            case "flush":
                                app.needs_redraw = true
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
                                
                                grid_scroll(&app.grid, int(top), int(bot), int(left), int(right), int(rows))
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
                                
                                app.cursor.row = int(row)
                                app.cursor.col = int(col)
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
                                
                                app.table.default_bg = u32(background)
                                app.table.default_fg = u32(foreground)
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
                                
                                hl_attr_define(&app.table, int(id), attrs)
                            case "mode_info_set":
                                if len(args) < 2
                                {
                                    continue
                                }
                                
                                style_enable, is_style_enabled  := args[0].(bool)
                                list, is_list := args[1].(Array)
                                if !is_style_enabled || !is_list
                                {
                                    continue
                                }
                                
                                app.cursor.style_enabled = style_enable
                                mode_info_set(&app.cursor, list)
                            case "mode_change":
                                if len(args) < 2
                                {
                                    continue
                                }
                                
                                index, is_index := args[1].(i64)
                                if !is_index
                                {
                                    continue
                                }

                                mode_change(&app.cursor, int(index))
                            case "set_title":
                                if len(args) < 1
                                {
                                    continue
                                }

                                title, is_title := args[0].(string)
                                if !is_title
                                {
                                    continue
                                }

                                if title == ""
                                {
                                    title = "Werevim"
                                }

                                delete(app.nvim_title)
                                app.nvim_title = strings.clone(title)
                                set_window_title(app.window, app.nvim_title)
                            case "option_set":
                                if len(args) < 2
                                {
                                    continue
                                }

                                method_name, is_name := args[0].(string)
                                size_name, is_size_name := args[1].(string)
                                if !is_name || !is_size_name || method_name != "guifont"
                                {
                                    continue
                                }

                                names, size, has_size := parse_guifont(size_name)
                                if len(names) > 0
                                {
                                    swapped := false
                                    for font_name in names
                                    {
                                        if try_font_name(font_name) 
                                        {
                                            swapped = true
                                            break
                                        }
                                    }

                                    if !swapped
                                    {
                                        fmt.eprintfln("Font not found: %v", names)
                                    }
                                }
 
                                if has_size
                                {
                                    resize_font(size)
                                }

                                resize_grid_to_window()
                            case "mouse_on":
                                app.mouse.enabled = true
                            case "mouse_off":
                                app.mouse.enabled = false
                            case "busy_start":
                                app.cursor.busy = true
                            case "busy_stop":
                                app.cursor.busy = false
                            case "set_icon", "chdir", "hl_group_set", "update_menu", "win_viewport":
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

try_font_name :: proc(name : string) -> bool
{
    if name == ""
    {
        return false
    }

    for a_font in BUNDLED_FONT_NAMES
    {
        if strings.equal_fold(a_font, name)
        {
            swap_font(bundled_font_path)
            return true
        }
    }
    
    family, official_font, found := find_font(name)
    if found && official_font != ""
    {
        split_family := strings.split(family, ",", context.temp_allocator)
        for a_family in split_family
        {
            if strings.equal_fold(strings.trim_space(a_family), name)
            {
                swap_font(official_font)
                return true
            }
        }
    }

    return false
}

parse_guifont :: proc(value : string) -> (names : []string, size : i32, has_size : bool)
{
    results := strings.split(value, ":", context.temp_allocator)
    if results[0] != "" && results[0] != NVIM_DEFAULT_GUIFONT
    {
        names = strings.split(results[0], ",", context.temp_allocator)
        for i in 0..<len(names)
        {
            names[i] = strings.trim_space(names[i])
        }
    }

    for a_string in results[1:]
    {
        if strings.has_prefix(a_string, "h")
        {
            number, is_number := strconv.parse_int(a_string[1:])
            if is_number
            {
                size = i32(number)
                if size > 0
                {
                    has_size = true
                }
            }
            break
        }
    }

    return
}

