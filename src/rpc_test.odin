package main

import "core:testing"
import "core:slice"

@(test)
test_rpc_empty :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    pending := [dynamic]u8{}
    defer delete(pending)
    messages := [dynamic]Value{}
    defer delete(messages)
    actual_status := drain_messages(&pending, &messages)
    
    testing.expect_value(t, actual_status, .Need_More)
    testing.expect_value(t, len(messages), 0)
    testing.expect_value(t, len(pending), 0)
}

@(test)
test_rpc_one_message :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    pending := [dynamic]u8{}
    append(&pending, 0x01)
    defer delete(pending)
    messages := [dynamic]Value{}
    defer delete(messages)
    actual_status := drain_messages(&pending, &messages)
    expected := [dynamic]Value{}
    defer delete(expected)
    append(&expected, Value(i64(1)))
    
    testing.expect_value(t, actual_status, .Need_More)
    testing.expect_value(t, len(messages), 1)
    expect_values_equal(t, Value(Array(messages[:])), Value(Array(expected[:])))
    testing.expect_value(t, len(pending), 0)
}

@(test)
test_rpc_two_together :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    pending := [dynamic]u8{}
    append(&pending, 0x01, 0x02)
    defer delete(pending)
    messages := [dynamic]Value{}
    defer delete(messages)
    actual_status := drain_messages(&pending, &messages)
    expected_messages := [dynamic]Value{}
    defer delete(expected_messages)
    append(&expected_messages, Value(i64(1)), Value(i64(2)))
    
    testing.expect_value(t, actual_status, .Need_More)
    expect_values_equal(t, Value(Array(messages[:])), Value(Array(expected_messages[:])))
    testing.expect_value(t, len(pending), 0)
}

@(test)
test_rpc_one_and_a_half :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    pending := [dynamic]u8{}
    append(&pending, 0x01, 0x0cd, 0x01)
    defer delete(pending)
    messages := [dynamic]Value{}
    defer delete(messages)
    actual_status := drain_messages(&pending, &messages)
    expected_messages := [dynamic]Value{}
    defer delete(expected_messages)
    append(&expected_messages, Value(i64(1)))
    expected_pending := [dynamic]u8{}
    defer delete(expected_pending)
    append(&expected_pending, 0xcd, 0x01)
    
    testing.expect_value(t, actual_status, .Need_More)
    expect_values_equal(t, Value(Array(messages[:])), Value(Array(expected_messages[:])))
    testing.expect_value(t, len(pending), 2)
    testing.expectf(t, slice.equal(pending[:], expected_pending[:]), "expected pending %x, got %x", expected_pending[:], pending[:])
}

@(test)
test_rpc_split_two_calls :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    pending := [dynamic]u8{}
    append(&pending, 0xcd, 0x01)
    defer delete(pending)
    messages := [dynamic]Value{}
    defer delete(messages)
    actual_status := drain_messages(&pending, &messages)
    
    testing.expect_value(t, actual_status, .Need_More)
    testing.expect_value(t, len(messages), 0)
    testing.expectf(t, slice.equal(pending[:], []u8{0xcd, 0x01}), "expected pending %x, got %x", []u8{0xcd, 0x01}, pending[:])
    
    append(&pending, 0x2c)
    actual_status = drain_messages(&pending, &messages)
    testing.expect_value(t, actual_status, .Need_More)
    expect_values_equal(t, Value(Array(messages[:])), Value(Array{Value(i64(300))}))
    testing.expect_value(t, len(pending), 0)
}

@(test)
test_rpc_invalid :: proc(t : ^testing.T)
{
    defer free_all(context.temp_allocator)
    pending := [dynamic]u8{}
    append(&pending, 0x01, 0xc1)
    defer delete(pending)
    messages := [dynamic]Value{}
    defer delete(messages)
    actual_status := drain_messages(&pending, &messages)
    
    testing.expect_value(t, actual_status, .Invalid)
    expect_values_equal(t, Value(Array(messages[:])), Value(Array{Value(i64(1))}))
}
