package main

import "core:fmt"
import "core:strings"
import "core:slice"

decode :: proc(data : []u8) -> (value : Value, consumed : int, ok : bool)
{
    if len(data) == 0
    {
        ok = false
        return
    }

    switch data[0]
    {
        case 0x00..=0x7f:
            // positive fixint
            value = i64(data[0])
            consumed = 1
            ok = true
        case 0xe0..=0xff:
            // negative fixint
            value = i64(i8(data[0]))
            consumed = 1
            ok = true
        case 0xc0:
            // nil
            value = Value(Nil{})
            consumed = 1
            ok = true
        case 0xc2:
            // boolean
            value = Value(bool(false))
            consumed = 1
            ok = true
        case 0xc3:
            // boolean
            value = Value(bool(true))
            consumed = 1
            ok = true
        case 0xcd:
            if len(data) >= 3
            {
                raw := read_be(data[1:], 2)
                value = i64(raw)
                consumed = 3
                ok = true
            }
        case 0xd0:
            // int8
            if len(data) >= 2
            {
                raw := read_be(data[1:], 1)
                value = i64(i8(raw))
                consumed = 2
                ok = true
            }
        case 0xd1:
            // int16
            if len(data) >= 3
            {
                raw := read_be(data[1:], 2)
                value = i64(i16(raw))
                consumed = 3
                ok = true
            }
        case 0xa0..=0xbf:
            // fixstr
            n := int(data[0] & 0x1f)
            if len(data) < n + 1
            {
                ok = false
                return
            }

            s := string(data[1:n + 1])
            value = strings.clone(s, context.temp_allocator)
            consumed = n + 1
            ok = true
        case 0xd9:
            // str 8
            headerSize := 2
            if len(data) < headerSize
            {
                ok = false
                return
            }

            n := int(read_be(data[1:], headerSize - 1))
            if len(data) < headerSize + n
            {
                ok = false
                return
            }

            s := string(data[headerSize : headerSize + n])
            value = strings.clone(s, context.temp_allocator)
            consumed = headerSize + n
            ok = true
        case 0xda:
            // str 16
            headerSize := 3
            if len(data) < headerSize
            {
                ok = false
                return
            }

            n := int(read_be(data[1:], headerSize - 1))
            if len(data) < headerSize + n
            {
                ok = false
                return
            }

            s := string(data[headerSize : headerSize + n])
            value = strings.clone(s, context.temp_allocator)
            consumed = headerSize + n
            ok = true
        case 0xdb:
            // str 32
            headerSize := 5
            if len(data) < headerSize
            {
                ok = false
                return
            }
            
            n := int(read_be(data[1:], headerSize - 1))
            if len(data) < headerSize + n
            {
                ok = false
                return
            }
            
            s := string(data[headerSize : headerSize + n])
            value = strings.clone(s, context.temp_allocator)
            consumed = headerSize + n
            ok = true
        case 0x90..=0x9f:
            // fixarray
            n := int(data[0] & 0x0f)
            headerSize := 1
            if n > len(data) - headerSize
            {
                ok = false
                return 
            }

            value, consumed, ok = decode_array_body(data, headerSize, n)
        case 0xdc:
            // array 16
            headerSize := 3
            if len(data) < headerSize
            {
                ok = false
                return
            }

            n := int(read_be(data[1:], headerSize - 1))
            if n > len(data) - headerSize
            {
                ok = false
                return 
            }

            value, consumed, ok = decode_array_body(data, headerSize, n)
        case 0xdd:
            // array 32
            headerSize := 5
            if len(data) < headerSize
            {
                ok = false
                return
            }

            n := int(read_be(data[1:], headerSize - 1))
            if n > len(data) - headerSize
            {
                ok = false
                return 
            }

            value, consumed, ok = decode_array_body(data, headerSize, n)
        case 0x80..=0x8f:
            // fixmap
            // For now, we will have a defined order.
            headerSize := 1
            if len(data) < headerSize
            {
                ok = false
                return
            }

            n := int(data[0] & 0x0f)
            if n > (len(data) - headerSize) / 2
            {
                ok = false
                return 
            }

            value, consumed, ok = decode_Map_body(data, headerSize, n)
        case 0xde:
            // map 16
            headerSize := 3
            if len(data) < headerSize
            {
                ok = false
                return
            }

            n := int(read_be(data[1:], headerSize - 1))
            if n > (len(data) - headerSize) / 2
            {
                ok = false
                return 
            }

            value, consumed, ok = decode_Map_body(data, headerSize, n)
        case 0xdf:
            // map 32
            headerSize := 5
            if len(data) < headerSize
            {
                ok = false
                return
            }

            n := int(read_be(data[1:], headerSize - 1))
            if n > (len(data) - headerSize) / 2
            {
                ok = false
                return 
            }

            value, consumed, ok = decode_Map_body(data, headerSize, n)
        case 0xcc:
            // uint8
            payload := 1
            if len(data) < 1 + payload
            {
                ok = false
                return
            }

            value = i64(read_be(data[1:], payload))
            consumed = 2
            ok = true
        case 0xce:
            // uint32
            payload := 4
            if len(data) < 1 + payload
            {
                ok = false
                return
            }
            
            value = i64(read_be(data[1:], payload))
            consumed = 5
            ok = true
        case 0xcf:
            // uint64 - will be tricky, since I use i64.
            payload := 8
            if len(data) < 1 + payload
            {
                    ok = false
                    return
            }
            
            raw := read_be(data[1:], payload)

            if raw <= u64(max(i64))
            {
                value = i64(raw)
            }
            else
            {
                value = raw
            }

            consumed = 9
            ok = true
        case 0xd2:
            // int32
            payload := 4
            if len(data) < 1 + payload
            {
                ok = false
                return
            }
            
            raw := read_be(data[1:], payload)
            value = i64(i32(raw))
            consumed = 5
            ok = true
        case 0xd3:
            // int64
            payload := 8
            if len(data) < 1 + payload
            {
                ok = false
                return
            }
            
            value = i64(read_be(data[1:], payload))
            consumed = 9
            ok = true
        case 0xc7:
            // ext 8
            headerSize := 3
            if len(data) < headerSize
            {
                ok = false
                return
            }
            
            n := int(read_be(data[1:], headerSize - 2))
            if len(data) < headerSize + n
            {
                ok = false
                return
            }

            raw := slice.clone(data[headerSize : headerSize + n], context.temp_allocator)
            value = Ext{i8(data[headerSize - 1]), raw}
            consumed = headerSize + n
            ok = true
        case 0xc8:
            // ext 16
            headerSize := 4
            if len(data) < headerSize
            {
                ok = false
                return
            }
            
            n := int(read_be(data[1:], headerSize - 2))
            if len(data) < headerSize + n
            {
                ok = false
                return
            }

            raw := slice.clone(data[headerSize : headerSize + n], context.temp_allocator)
            value = Ext{i8(data[headerSize - 1]), raw}
            consumed = headerSize + n
            ok = true
        case 0xc9:
            // ext 32
            headerSize := 6
            if len(data) < headerSize
            {
                ok = false
                return
            }
            
            n := int(read_be(data[1:], headerSize - 2))
            if len(data) < headerSize + n
            {
                ok = false
                return
            }

            raw := slice.clone(data[headerSize : headerSize + n], context.temp_allocator)
            value = Ext{i8(data[headerSize - 1]), raw}
            consumed = headerSize + n
            ok = true
        case 0xd4..=0xd8:
            // fixext
            headerSize := 2
            if len(data) < headerSize
            {
                ok = false
                return
            }
            
            n := 1 << uint(data[0] - 0xd4)
            if len(data) < headerSize + n
            {
                ok = false
                return
            }

            raw := slice.clone(data[headerSize : headerSize + n], context.temp_allocator)
            value = Ext{i8(data[1]), raw}
            consumed = headerSize + n
            ok = true
        case:
            fmt.eprintfln("decode did not handle this case: 0x%02x", data[0])
            ok = false
    }
    
    return
}

read_be :: proc(data : []u8, n : int) -> u64
{
    accumulator : u64
    individual : u64

    for i := 0; i < n; i += 1
    {
        individual = u64(data[i])
        accumulator = accumulator << 8 | individual
    }

    return accumulator
}

decode_array_body :: proc(data : []u8, headerSize, n : int) -> (value : Value, consumed : int, ok : bool)
{
    arr := make([]Value, n, context.temp_allocator)
    offset := headerSize
    for i := 0; i < n; i += 1
    {
        element, used, element_ok := decode(data[offset:])
        if !element_ok
        {
            ok = false
            return
        }

        arr[i] = element
        offset += used
    }
    
    value = arr
    consumed = offset
    ok = true

    return
}

decode_Map_body :: proc(data : []u8, headerSize, n : int) -> (value : Value, consumed : int, ok : bool)
{
    pairs := make([]Pair, n, context.temp_allocator)
    offset := headerSize
    for i := 0; i < n; i += 1
    {
        key, used, key_ok := decode(data[offset:])
        if !key_ok
        {
            ok = false
            return
        }

        offset += used
        val, val_used, value_ok := decode(data[offset:])
        if !value_ok
        {
            ok = false
            return
        }

        pairs[i] = Pair{key, val}
        offset += val_used
    }

    value = Map(pairs)
    consumed = offset
    ok = true

    return
}
