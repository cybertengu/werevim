package main

import "core:testing"
import "vendor:sdl2"

@(test)
test_input_key_name_return :: proc(t : ^testing.T)
{
    name, ok := key_name(sdl2.Keycode.RETURN)

    testing.expect(t, ok)
    testing.expect_value(t, name, "CR")
}

@(test)
test_input_key_name_esc :: proc(t : ^testing.T)
{
    name, ok := key_name(sdl2.Keycode.ESCAPE)

    testing.expect(t, ok)
    testing.expect_value(t, name, "Esc")
}

@(test)
test_input_key_name_letter :: proc(t : ^testing.T)
{
    _, ok := key_name(sdl2.Keycode.A)

    testing.expect(t, !ok)
}

