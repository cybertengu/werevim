package main

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
