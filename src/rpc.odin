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

handle_message :: proc(msg : Value)
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

                    fmt.printfln("Message was sent: %s", name)
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
