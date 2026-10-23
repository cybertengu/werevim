package main

import "core:testing"
import "core:slice"

@(test)
test_encode_request :: proc(t : ^testing.T)
{
    buf : [dynamic]u8
    defer delete(buf)
    defer free_all(context.temp_allocator)
    args := Array{Value(i64(80)), Value(i64(24)), Map{
        Pair{Value(string("ext_linegrid")), Value(bool(true))},
        Pair{Value(string("rgb")), Value(bool(true))}
    }}
    encode_request(&buf, 1, "nvim_ui_attach", args)

    expected := []u8{
        0x94, 0x00, 0x01, 0xae,
        0x6e, 0x76, 0x69, 0x6d, 0x5f, 0x75, 0x69, 0x5f, 0x61, 0x74, 0x74, 0x61, 0x63,
        0x68, 0x93, 0x50, 0x18, 0x82, 0xac, 0x65, 0x78, 0x74, 0x5f, 0x6c, 0x69, 0x6e,
        0x65, 0x67, 0x72, 0x69, 0x64, 0xc3, 0xa3, 0x72, 0x67, 0x62, 0xc3,
    }
    
    testing.expectf(t, slice.equal(buf[:], expected), "expected %x, got %x", expected, buf[:])
}
