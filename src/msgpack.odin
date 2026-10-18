package main

import "core:fmt"
import "core:strings"

/*
TODO(CyberTengu):
- A minimal encoder and decoder.
- Handshake: call nvim_ui_attach(cols, rows, 
 {ext_linegrid=true, rgb=true}).
- Logging: print the redraw notifications 
(grid_resize, grid_line, hl_attr_define, flush and 
so on) as they arrive.

["hi", 300, true] "hi" encodes to 0xa26869. 300 is 0xcd012c. true is 0xc3
0x93
*/

Value :: union
{
    Nil,
    bool,
    i64,
    //f64,
    string,
    //Array,
    //Map,
}

Nil :: struct
{

}

Array :: []Value
Map :: []Pair

Pair :: struct
{
    key, value : Value,
}

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
