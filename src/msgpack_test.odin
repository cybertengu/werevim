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
    expect_values_equal(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_negative_fixint :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xff})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(-1)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_Nil :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xc0})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(Nil{}))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_booleans :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xc2})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(bool(false)))
    testing.expect_value(t, consumed, 1)
    
    value, consumed, ok = decode([]u8{0xc3})
    testing.expect(t, ok)
    expect_values_equal(t, value, Value(bool(true)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_uint16 :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xcd, 0x01, 0x2c})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(300)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_int16_negative :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0xff, 0x9c})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(-100)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_smallest_int8 :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd0, 0x80})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(-128)))
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
    expect_values_equal(t, value, Value(i64(127)))
    testing.expect_value(t, consumed, 2)
}

@(test)
test_decode_int16_just_below_int8_min :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0xff, 0x7f})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(-129)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_int16_smallest_value :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0x80, 0x00})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(-32768)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_int16_largest_value :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0x7f, 0xff})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(32767)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_int16_small_positive :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xd1, 0x00, 0x05})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_bottom_positive_range :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0x00})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(0)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_top_positive_range :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0x7f})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(127)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_bottom_negative_range :: proc(t : ^testing.T)
{
    value, consumed, ok := decode([]u8{0xe0})

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(-32)))
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
    expect_values_equal(t, value, Value(i64(-100)))
    testing.expect_value(t, consumed, 2)

    value, consumed, ok = decode(data[consumed:])

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_fixstring_empty :: proc(t : ^testing.T)
{
    data := []u8{0xa0}
    defer free_all(context.temp_allocator)

    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(string("")))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_fixstring :: proc(t : ^testing.T)
{
    data := []u8{0xa2, 0x68, 0x69}
    defer free_all(context.temp_allocator)
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(string("hi")))
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
    expect_values_equal(t, value, Value(string("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")))
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
    expect_values_equal(t, value, Value(string("hi")))
    testing.expect_value(t, consumed, 3)

    value, consumed, ok = decode(data[consumed:])

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_str8 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xd9, 0x02, 0x68, 0x69}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(string("hi")))
    testing.expect_value(t, consumed, 4)
}

@(test)
test_decode_str8_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xd9, 0x00}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(string("")))
    testing.expect_value(t, consumed, 2)
}

@(test)
test_decode_str8_trailing_bytes :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xd9, 0x02, 0x68, 0x69, 0x06}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(string("hi")))
    testing.expect_value(t, consumed, 4)

    value, consumed, ok = decode(data[consumed:])

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(6)))
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
    expect_values_equal(t, value, Value("hi"))
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
    expect_values_equal(t, value, Value("hi"))
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
    expect_values_equal(t, value, Value(string("é")))
    testing.expect_value(t, consumed, 3)
}

@(test)
test_decode_fixarray_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x90}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 0)
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_fixarray_failing :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x92, 0xcd, 0x01}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_fixarray_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x92, 0x01}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_fixarray :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x92, 0x01, 0x02}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)
    expected := Array{Value(i64(1)), Value(i64(2))}

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 2)
    testing.expect_value(t, consumed, 3)
    expect_values_equal(t, arr, expected)
}

@(test)
test_decode_fixarray_different_elements :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x93, 0xa2, 0x68, 0x69, 0xcd, 0x01, 0x2c, 0xc3}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)
    expected := Array{Value(string("hi")), Value(i64(300)), Value(bool(true))}

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 3)
    testing.expect_value(t, consumed, 8)
    expect_values_equal(t, arr, expected)
}

@(test)
test_decode_fixarray_array_in_array :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x92, 0x91, 0x01, 0x02}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)
    expected := Array{Array{Value(i64(1))}, Value(i64(2))}

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 2)
    testing.expect_value(t, consumed, 4)
    expect_values_equal(t, arr, expected)
}

@(test)
test_decode_array_16 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdc, 0x00, 0x02, 0x01, 0x02}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)
    expected := Array{Value(i64(1)), Value(i64(2))}

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 2)
    testing.expect_value(t, consumed, 5)
    expect_values_equal(t, arr, expected)
}

@(test)
test_decode_array_16_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdc, 0x00, 0x00}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)
    expected := Array{}

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 0)
    testing.expect_value(t, consumed, 3)
    expect_values_equal(t, arr, expected)
}

@(test)
test_decode_array_16_missing_element :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdc, 0x00, 0x02, 0x01}
    value, consumed, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_array_16_element_failing :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdc, 0x00, 0x02, 0xcd, 0x01}
    value, consumed, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_array_16_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdc, 0x00}
    value, consumed, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_array_16_trailing_byte :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdc, 0x00, 0x02, 0x01, 0x02, 0x05}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)
    expected := Array{Value(i64(1)), Value(i64(2))}

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 2)
    testing.expect_value(t, consumed, 5)
    expect_values_equal(t, arr, expected)

    value, consumed, ok = decode(data[consumed:])

    testing.expect(t, ok)
    expect_values_equal(t, value, Value(i64(5)))
    testing.expect_value(t, consumed, 1)
}

@(test)
test_decode_array_32 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdd, 0x00, 0x00, 0x00, 0x02, 0x01, 0x02}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)
    expected := Array{Value(i64(1)), Value(i64(2))}

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 2)
    testing.expect_value(t, consumed, 7)
    expect_values_equal(t, arr, expected)
}

@(test)
test_decode_array_32_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdd, 0x00, 0x00}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_array_32_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdd, 0x00, 0x00, 0x00, 0x00}
    value, consumed, ok := decode(data)
    arr, is_array := value.(Array)
    expected := Array{}

    testing.expect(t, ok)
    testing.expect(t, is_array)
    testing.expect_value(t, len(arr), 0)
    testing.expect_value(t, consumed, 5)
    expect_values_equal(t, arr, expected)
}

@(test)
test_decode_array_32_guard_large_request :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdd, 0xff, 0xff, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_Map_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x80}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{}

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 0)
    testing.expect_value(t, consumed, 1) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_one_pair :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x81, 0xa1, 0x61, 0x01}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{Pair{Value(string("a")), Value(i64(1))}}

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 1)
    testing.expect_value(t, consumed, 4) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_two_pairs :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x82, 0xa1, 0x61, 0x01, 0xa1, 0x62, 0x02}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{
        Pair{Value(string("a")), Value(i64(1))},
        Pair{Value(string("b")), Value(i64(2))}
    }

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 2)
    testing.expect_value(t, consumed, 7) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_boundary :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x82, 0x01, 0x02, 0x03, 0x04}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{
        Pair{Value(i64(1)), Value(i64(2))},
        Pair{Value(i64(3)), Value(i64(4))}
    }

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 2)
    testing.expect_value(t, consumed, 5) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_boundary_byte_short :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x82, 0x01, 0x02, 0x03}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_Map_array :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x81, 0xa1, 0x61, 0x91, 0x01}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{
        Pair{Value(string("a")), Array{Value(i64(1))}}
    }

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 1)
    testing.expect_value(t, consumed, 5) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_inner_Map :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x81, 0xa1, 0x61, 0x81, 0xa1, 0x62, 0x02}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    inner := Map{Pair{Value(string("b")), Value(i64(2))}}
    expected := Map{Pair{Value(string("a")), Value(inner)}}

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 1)
    testing.expect_value(t, consumed, 7) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_value_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x81, 0xa1, 0x61}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_Map_key_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x81, 0xa1}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_Map_key_fails :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x81, 0xcd, 0x01}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_Map_value_fails :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x81, 0x01, 0xcd, 0x01}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_Map_trailing_bytes :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0x81, 0xa1, 0x61, 0x01, 0x05}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{Pair{Value(string("a")), Value(i64(1))}}

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 1)
    testing.expect_value(t, consumed, 4) 
    expect_values_equal(t, mapp, expected)

    value, consumed, ok = decode(data[consumed:])

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 1)
    expect_values_equal(t, value, Value(i64(5)))
}

@(test)
test_decode_Map_16 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xde, 0x00, 0x01, 0xa1, 0x61, 0x01}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{Pair{Value(string("a")), Value(i64(1))}}

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 1)
    testing.expect_value(t, consumed, 6) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_32 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdf, 0x00, 0x00, 0x00, 0x01, 0xa1, 0x61, 0x01}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{Pair{Value(string("a")), Value(i64(1))}}

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 1)
    testing.expect_value(t, consumed, 8) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_16_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xde, 0x00, 0x00}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{}

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 0)
    testing.expect_value(t, consumed, 3) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_16_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xde, 0x00}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_Map_32_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdf, 0x00, 0x00, 0x00, 0x00}
    value, consumed, ok := decode(data)
    mapp, is_map := value.(Map)
    expected := Map{}

    testing.expect(t, ok)
    testing.expect(t, is_map)
    testing.expect_value(t, len(mapp), 0)
    testing.expect_value(t, consumed, 5) 
    expect_values_equal(t, mapp, expected)
}

@(test)
test_decode_Map_32_truncated :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdf, 0x00, 0x00}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_Map_hostile_prevent :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    data := []u8{0xdf, 0xff, 0xff, 0xff, 0xff}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_uint8 :: proc(t : ^testing.T)
{
    data := []u8{0xcc, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 2)
    expect_values_equal(t, value, Value(i64(255)))
}

@(test)
test_decode_uint32_large :: proc(t : ^testing.T)
{
    data := []u8{0xce, 0x00, 0xff, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 5)
    expect_values_equal(t, value, Value(i64(16777215)))
}

@(test)
test_decode_uint32_max :: proc(t : ^testing.T)
{
    data := []u8{0xce, 0xff, 0xff, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 5)
    expect_values_equal(t, value, Value(i64(4294967295)))
}

@(test)
test_decode_int32_max :: proc(t : ^testing.T)
{
    data := []u8{0xd2, 0x7f, 0xff, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 5)
    expect_values_equal(t, value, Value(i64(2147483647)))
}

@(test)
test_decode_uint16_max :: proc(t : ^testing.T)
{
    data := []u8{0xcd, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 3)
    expect_values_equal(t, value, Value(i64(65535)))
}

@(test)
test_decode_int32_negative_one :: proc(t : ^testing.T)
{
    data := []u8{0xd2, 0xff, 0xff, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 5)
    expect_values_equal(t, value, Value(i64(-1)))
}

@(test)
test_decode_int32_large_negative :: proc(t : ^testing.T)
{
    data := []u8{0xd2, 0x80, 0x00, 0x00, 0x00}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 5)
    expect_values_equal(t, value, Value(i64(-2147483648)))
}

@(test)
test_decode_int32_truncated :: proc(t : ^testing.T)
{
    data := []u8{0xd2, 0x00, 0x00, 0x00}
    value, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_int64_truncated :: proc(t : ^testing.T)
{
    data := []u8{0xd3, 0x00, 0x00, 0x00, 0x00}
    value, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_int64_large_negative :: proc(t : ^testing.T)
{
    data := []u8{0xd3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 9)
    expect_values_equal(t, value, Value(i64(-9223372036854775808)))
}

@(test)
test_decode_int64_small_negative :: proc(t : ^testing.T)
{
    data := []u8{0xd3, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 9)
    expect_values_equal(t, value, Value(i64(-1)))
}

@(test)
test_decode_uint64_normalizing_rule :: proc(t : ^testing.T)
{
    data := []u8{0xcf, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 9)
    expect_values_equal(t, value, Value(i64(5)))
}

@(test)
test_decode_uint64_large :: proc(t : ^testing.T)
{
    data := []u8{0xcf, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 9)
    expect_values_equal(t, value, Value(u64(18446744073709551615)))
}

@(test)
test_decode_uint64_boundary :: proc(t : ^testing.T)
{
    data := []u8{0xcf, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
    value, consumed, ok := decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 9)
    expect_values_equal(t, value, Value(i64(9223372036854775807)))
    
    data = []u8{0xcf, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    value, consumed, ok = decode(data)

    testing.expect(t, ok)
    testing.expect_value(t, consumed, 9)
    expect_values_equal(t, value, Value(u64(9223372036854775808)))
}

@(test)
test_decode_uint8_truncated :: proc(t : ^testing.T)
{
    data := []u8{0xcc}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_uint32_truncated :: proc(t : ^testing.T)
{
    data := []u8{0xce, 0x00, 0x00, 0x00}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

@(test)
test_decode_uint64_truncated :: proc(t : ^testing.T)
{
    data := []u8{0xcf, 0x00, 0x00, 0x00, 0x00}
    _, _, ok := decode(data)

    testing.expect(t, !ok)
}

expect_values_equal :: proc(t : ^testing.T, got, want : Value, loc := #caller_location)
{
    testing.expectf(t, values_equal(got, want), "expected: %v, got %v", want, got, loc = loc)
}

values_equal :: proc(a, b : Value) -> bool
{
    switch x in a
    {
        case Nil:
            _, ok := b.(Nil)
            return ok
        case i64:
            y, ok := b.(i64)
            return ok && x == y
        case u64:
            y, ok := b.(u64)
            return ok && x == y
        case string:
            y, ok := b.(string)
            return ok && x == y
        case bool:
            y, ok := b.(bool)
            return ok && x == y
        case Array:
            y, ok := b.(Array)
            if !ok
            {
                return false
            }
            if len(x) != len(y)
            {
                return false
            }
            
            for i in 0..<len(x)
            {
                if !values_equal(x[i], y[i])
                {
                    return false
                }
            }

            return true
        case Map:
            y, ok := b.(Map)
            if !ok || len(x) != len(y)
            {
                return false
            }

            for i in 0..<len(x)
            {
                if !values_equal(x[i].key, y[i].key) || !values_equal(x[i].value, y[i].value)
                {
                    return false
                }
            }

            return true
        case:
            return b == nil
    }
}
