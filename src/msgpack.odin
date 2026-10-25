package main

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
    u64,
    f64,
    string,
    Array,
    Map,
    Ext,
    Bin,
}

Nil :: struct
{

}

Array :: []Value
Map :: []Pair
Bin :: distinct []u8

Pair :: struct
{
    key, value : Value,
}

Ext :: struct
{
    type : i8,
    data : []u8,
}

Decode_Status :: enum
{
    Invalid,    
    Ok,
    Need_More,
}

MAX_LENGTH :: 64 * 1024 * 1024
