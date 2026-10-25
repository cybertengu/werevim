package main

import "core:testing"

round_trip :: proc(t : ^testing.T, original : Value, loc := #caller_location)
{
    defer free_all(context.temp_allocator)
    buf : [dynamic]u8
    defer delete(buf)
    encode_value(&buf, original)
    actual, consumed, ok := decode(buf[:])

    testing.expect_value(t, ok, .Ok)
    testing.expect_value(t, consumed, len(buf))
    expect_values_equal(t, actual, original, loc = loc)
}

@(test)
test_round_trip_int :: proc(t : ^testing.T)
{
    round_trip(t, Value(i64(300)))
}

@(test)
test_round_trip_string :: proc(t : ^testing.T)
{
    round_trip(t, Value(string("bye")))
}

@(test)
test_round_trip_array :: proc(t : ^testing.T)
{
    arr := Array{Value(string("hi")), Value(i64(345)), Value(bool(true))}
    round_trip(t, arr)
}

@(test)
test_round_trip_array_inner_array :: proc(t : ^testing.T)
{
    inner := Array{Value(i64(300))}
    arr := Array{inner, Value(i64(2))}
    round_trip(t, arr)
}

@(test)
test_round_trip_Map :: proc(t : ^testing.T)
{
    mapp := Map{
        Pair{Value(string("a")), Value(i64(1))},
        Pair{Value(string("b")), Value(i64(2))},
    }
    round_trip(t, mapp)
}

@(test)
test_round_trip_Map_innerMap :: proc(t : ^testing.T)
{
    inner := Map{
        Pair{Value(string("c")), Value(i64(3))}
    }
    mapp := Map{
        Pair{Value(string("a")), Value(i64(1))},
        Pair{Value(string("b")), Value(inner)},
    }
    round_trip(t, mapp)
}

@(test)
test_round_trip_uint64_max :: proc(t : ^testing.T)
{
    round_trip(t, Value(u64(max(u64))))
}

@(test)
test_round_trip_uint64_to_i64 :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    buf : [dynamic]u8
    defer delete(buf)
    original : u64 = 5
    encode_value(&buf, original)
    actual, consumed, ok := decode(buf[:])

    testing.expect_value(t, ok, .Ok)
    testing.expect_value(t, consumed, len(buf))

    // This is expected behavior to get back a i64 version
    // of the original if smaller that the size of an i64.
    expect_values_equal(t, actual, i64(original))
}

@(test)
test_round_trip_Map_with_array :: proc(t : ^testing.T)
{
    list := Array{Value(i64(1)), Value(string("x"))}
    mapp := Map{
        Pair{Value(string("list")), Value(list)},
    }
    round_trip(t, mapp)
}

@(test)
test_round_trip_array_with_Map :: proc(t : ^testing.T)
{
    inner := Map{
        Pair{Value(string("k")), Value(bool(true))},
    }
    arr := Array{Value(i64(7)), Value(inner)}
    round_trip(t, arr)
}
