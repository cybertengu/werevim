package main

import "core:testing"
import "core:slice"

@(test)
test_write_be_two_bytes :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    write_be(&buf, 300, 2)

    expected := []u8{0x01, 0x2c}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_write_be_one_byte :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    write_be(&buf, 5, 1)

    expected := []u8{0x05}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_write_be_four_bytes_max :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    write_be(&buf, 0xffffffff, 4)

    expected := []u8{0xff, 0xff, 0xff, 0xff}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_write_be_eight_bytes :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    write_be(&buf, 0x0102030405060708, 8)

    expected := []u8{0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_write_be_leading_zeros :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    write_be(&buf, 300, 4)

    expected := []u8{0x00, 0x00, 0x01, 0x2c}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_write_be_zero :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 0)

    expected := []u8{0x00}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}


@(test)
test_encode_int_127 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 127)

    expected := []u8{0x7f}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_128 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 128)

    expected := []u8{0xcc, 0x80}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_255 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 255)

    expected := []u8{0xcc, 0xff}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_256 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 256)

    expected := []u8{0xcd, 0x01, 0x00}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_65535 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 65535)

    expected := []u8{0xcd, 0xff, 0xff}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_65536 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 65536)

    expected := []u8{0xce, 0x00, 0x01, 0x00, 0x00}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_one :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -1)

    expected := []u8{0xff}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_32 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -32)

    expected := []u8{0xe0}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_33 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -33)

    expected := []u8{0xd0, 0xdf}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_128 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -128)

    expected := []u8{0xd0, 0x80}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_129 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -129)

    expected := []u8{0xd1, 0xff, 0x7f}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_32768 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -32768)

    expected := []u8{0xd1, 0x80, 0x00}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_32769 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -32769)

    expected := []u8{0xd2, 0xff, 0xff, 0x7f, 0xff}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_4294967295 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 4294967295)

    expected := []u8{0xce, 0xff, 0xff, 0xff, 0xff}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_4294967296 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 4294967296)

    expected := []u8{0xcf, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_2147483648 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -2147483648)

    expected := []u8{0xd2, 0x80, 0x00, 0x00, 0x00}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_negative_2147483649 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -2147483649)

    expected := []u8{0xd3, 0xff, 0xff, 0xff, 0xff, 0x7f, 0xff, 0xff, 0xff}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_max_i64 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, 9223372036854775807)

    expected := []u8{0xcf, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}

@(test)
test_encode_int_min_i64 :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)

    encode_int(&buf, -9223372036854775808)

    expected := []u8{0xd3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}
