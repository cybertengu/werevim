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

}

encode_bool :: proc(buf : ^[dynamic]u8, b : bool)
{

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

}

encode_array_header :: proc(buf : ^[dynamic]u8, count : int)
{

}

encode_Map_header :: proc(buf : ^[dynamic]u8, count : int)
{

}
