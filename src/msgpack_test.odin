package main

import "core:testing"

@(test)
test_read_be :: proc(t : ^testing.T)
{
    testing.expect_value(t, read_be([]u8{0x01, 0x2c}, 2), 300)
}

@(test)
test_decode_positive_fixint :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0x05})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_negative_fixint :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xff})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(-1)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_Nil :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xc0})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(Nil{}))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_booleans :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xc2})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(bool(false)))
    testing.expect_value(t, consumed, 1)
    
    value, consumed, ok = decode([]u8{0xc3})
    testing.expect(t, ok)
    testing.expect_value(t, value, Value(bool(true)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_uint16 :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xcd, 0x01, 0x2c})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(300)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_int16_negative :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0xff, 0x9c})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(-100)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_smallest_int8 :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd0, 0x80})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(-128)))
    testing.expect_value(t, consumed, 2)
}

@(test)
test_decode_truncated_uint16 :: proc(t : ^testing.T)
{
    _, _, ok := decode([]u8{0xcd, 0x01})

    testing.expect(t, !ok)
}

@(test)
test_decode_empty :: proc(t : ^testing.T)
{
    _, _, ok := decode([]u8{})

    testing.expect(t, !ok)
}

@(test)
test_decode_largest_int8 :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd0, 0x7f})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(127)))
    testing.expect_value(t, consumed, 2)
}

@(test)
test_decode_int16_just_below_int8_min :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0xff, 0x7f})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(-129)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_int16_smallest_value :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0x80, 0x00})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(-32768)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_int16_largest_value :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0x7f, 0xff})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(32767)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_int16_small_positive :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0x00, 0x05})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_bottom_positive_range :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0x00})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(0)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_top_positive_range :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0x7f})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(127)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_bottom_negative_range :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xe0})

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(-32)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_truncated_signed :: proc(t : ^testing.T)
{
    _, _, ok := decode([]u8{0xd0})

    testing.expect(t, !ok)

    _, _, ok = decode([]u8{0xd1, 0xff})
    testing.expect(t, !ok)
}

@(test)
test_decode_trailing_bytes :: proc(t : ^testing.T)
{
    data := []u8{0xd0, 0x9c, 0x05}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(-100)))
    testing.expect_value(t, consumed, 2)

    value, consumed, ok = decode(data[consumed:])

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_fixstring_empty :: proc(t : ^testing.T)
{
    data := []u8{0xa0}
    defer free_all(context.temp_allocator)

    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(string("")))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_fixstring :: proc(t : ^testing.T)
{
    data := []u8{0xa2, 0x68, 0x69}
    defer free_all(context.temp_allocator)
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(string("hi")))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_fixstr_max_length :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)

    data := make([]u8, 32, context.temp_allocator)
    data[0] = 0xbf
    for i in 1..<32
    {
        data[i] = 'a'
    }

    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(string("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")))
    testing.expect_value(t, consumed, 32)
}

@(test)
test_decode_fixstr_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    
    data := []u8{0xa2, 0x68}

    _, _, ok := decode(data)

    testing.expect(t, !ok)

    data = []u8{0xa5}

    _, _, ok = decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_fixstr_trailing_bytes :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xa2, 0x68, 0x69, 0x05}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(string("hi")))
    testing.expect_value(t, consumed, 3)

    value, consumed, ok = decode(data[consumed:])

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_str8 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xd9, 0x02, 0x68, 0x69}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(string("hi")))
    testing.expect_value(t, consumed, 4)
}

@(test)
test_decode_str8_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xd9, 0x00}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(string("")))
    testing.expect_value(t, consumed, 2)
}

@(test)
test_decode_str8_trailing_bytes :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xd9, 0x02, 0x68, 0x69, 0x06}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(string("hi")))
    testing.expect_value(t, consumed, 4)

    value, consumed, ok = decode(data[consumed:])

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(i64(6)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_str8_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xd9, 0x02, 0x68}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
    
    data = []u8{0xd9}
    _, _, ok = decode(data)
    
    testing.expect(t, !ok)
}

@(test)
test_decode_str16 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xda, 0x00, 0x02, 0x68, 0x69}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value("hi"))
    testing.expect_value(t, consumed, 5)
}

@(test)
test_decode_str16_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xda, 0x02, 0x68}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
    
    data = []u8{0xda}
    _, _, ok = decode(data)
    
    testing.expect(t, !ok)

    data = []u8{0xda, 0x00, 0x02}
    _, _, ok = decode(data)
    testing.expect(t, !ok)
}

@(test)
test_decode_str32 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdb, 0x00, 0x00, 0x00, 0x02, 0x68, 0x69}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value("hi"))
    testing.expect_value(t, consumed, 7)
}

@(test)
test_decode_str32_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdb, 0x02, 0x68}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
    
    data = []u8{0xdb, 0x00}
    _, _, ok = decode(data)
    
    testing.expect(t, !ok)
    
    data = []u8{0xdb, 0x00, 0x02, 0x68}
    _, _, ok = decode(data)
    testing.expect(t, !ok)
}

@(test)
test_decode_fixstr_multibyte_utf8 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xa2, 0xc3, 0xa9}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, value, Value(string("é")))
    testing.expect_value(t, consumed, 3)
}
