package main

write_be :: proc(buf : ^[dynamic]u8, value : u64, n : int)
{
    shift : uint
    val : u8

    for i := 0; i < n; i += 1
    {
        shift = uint(8 * (n - 1 - i))
        val = u8((value >> shift) & 0xff)
        append(buf, val)
    }
}

encode_nil :: proc(buf : ^[dynamic]u8)
{
    append(buf, 0xc0)
}

encode_bool :: proc(buf : ^[dynamic]u8, b : bool)
{
    if b
    {
        append(buf, 0xc3)
    }
    else
    {
        append(buf, 0xc2)
    }
}

encode_int :: proc(buf : ^[dynamic]u8, v : i64)
{
    switch v
    {
        case 0..=127:
            append(buf, u8(v))
        case -32..=-1:
            append(buf, u8(v))
        case 128..=255:
            append(buf, 0xcc)
            write_be(buf, u64(v), 1)
        case 256..=65535:
            append(buf, 0xcd)
            write_be(buf, u64(v), 2)
        case 65536..=4294967295:
            append(buf, 0xce)
            write_be(buf, u64(v), 4)
        case 4294967296..=9223372036854775807:
            append(buf, 0xcf)
            write_be(buf, u64(v), 8)
        case -128..=-33:
            append(buf, 0xd0)
            write_be(buf, u64(v), 1)
        case -32768..=-129:
            append(buf, 0xd1)
            write_be(buf, u64(v), 2)
        case -2147483648..=-32769:
            append(buf, 0xd2)
            write_be(buf, u64(v), 4)
        case:
            append(buf, 0xd3)
            write_be(buf ,u64(v), 8)
    }
}

encode_string :: proc(buf : ^[dynamic]u8, s : string)
{
    switch len(s)
    {
        case 0..=31:
            append(buf, 0xa0 | u8(len(s)))
            append_string(buf, s)
        case 32..=255:
            append(buf, 0xd9)
            write_be(buf, u64(len(s)), 1)
            append_string(buf, s)
        case 256..=65535:
            append(buf, 0xda)
            write_be(buf, u64(len(s)), 2)
            append_string(buf, s)
        case:
            append(buf, 0xdb)
            write_be(buf, u64(len(s)), 4)
            append_string(buf, s)
    }
}

encode_array_header :: proc(buf : ^[dynamic]u8, count : int)
{
    assert(count >= 0, "encode_array_header: negative count")

    switch count
    {
        case 0..=15:
            append(buf, u8(0x90 | count))
        case 16..=65535:
            append(buf, 0xdc)
            write_be(buf, u64(count), 2)
        case:
            append(buf, 0xdd)
            write_be(buf, u64(count), 4)
    }
}

encode_Map_header :: proc(buf : ^[dynamic]u8, count : int)
{
    assert(count >= 0, "encode_Map_header: negative count")

    switch count
    {
        case 0..=15:
            append(buf, u8(0x80 | count))
        case 16..=65535:
            append(buf, 0xde)
            write_be(buf, u64(count), 2)
        case:
            append(buf, 0xdf)
            write_be(buf, u64(count), 4)
    }
}

encode_value :: proc(buf : ^[dynamic]u8, v : Value)
{
    switch value in v
    {
        case Nil:
            encode_nil(buf)
        case bool:
            encode_bool(buf, value)
        case i64:
            encode_int(buf, value)
        case u64:
            if value <= u64(max(i64))
            {
                encode_int(buf, i64(value))
            }
            else
            {
                append(buf, 0xcf)
                write_be(buf, value, 8)
            }
        case f64:
            assert(false, "encode_value: encoding f64 is not supported yet.")
        case string:
            encode_string(buf, v.(string))
        case Array:
            encode_array_header(buf, len(value))
            for element in value
            {
                encode_value(buf, element)
            }
        case Map:
            encode_Map_header(buf, len(value))
            for pair in value
            {
                encode_value(buf, pair.key)
                encode_value(buf, pair.value)
            }
        case Ext:
            assert(false, "encode_value: encoding Ext is not supported yet.")
        case Bin:
            assert(false, "enocde_value: encoding to binary is not supported yet.")
        case:
            assert(false, "encode_value: empty Value.")
    }
}
