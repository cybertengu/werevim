package main

import "core:testing"
import "core:slice"

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
        case Ext:
            y, ok := b.(Ext)
            if !ok
            {
                return false
            }

            return slice.equal(x.data, y.data) && x.type == y.type
        case:
            return b == nil
    }
}
