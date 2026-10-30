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

@(test)
test_input_key_modifier_prefix :: proc(t : ^testing.T)
{
    name := modifier_prefix(sdl2.Keymod{.LCTRL, .LSHIFT}, true)

    testing.expect_value(t, name, "C-S-")
}

@(test)
test_input_key_modifier_prefix_shift_character :: proc(t : ^testing.T)
{
    name := modifier_prefix(sdl2.Keymod{.LCTRL, .LSHIFT}, false)

    testing.expect_value(t, name, "C-")
}

@(test)
test_input_key_modifier_prefix_AltGr_check_not_meta :: proc(t : ^testing.T)
{
    name := modifier_prefix(sdl2.Keymod{.RALT}, true)

    testing.expect_value(t, name, "")
}

@(test)
test_input_key_modifier_prefix_left_alt_meta :: proc(t : ^testing.T)
{
    name := modifier_prefix(sdl2.Keymod{.LALT}, true)

    testing.expect_value(t, name, "M-")
}

@(test)
test_input_key_modifier_prefix_nothing_held :: proc(t : ^testing.T)
{
    name := modifier_prefix(sdl2.Keymod{}, true)

    testing.expect_value(t, name, "")
}
