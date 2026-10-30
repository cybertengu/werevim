package main

import "vendor:sdl2"
import "core:fmt"

key_name :: proc(sym : sdl2.Keycode) -> (name : string, ok : bool)
{
    #partial switch sym
    {
        case .ESCAPE:
            ok = true
            name = "Esc"
        case .RETURN:
            ok = true
            name = "CR"
        case .BACKSPACE:
            ok = true
            name = "BS"
        case .DELETE:
            ok = true
            name = "Del"
        case .INSERT:
            ok = true
            name = "Insert"
        case .PAGEUP:
            ok = true
            name = "PageUp"
        case .PAGEDOWN:
            ok = true
            name = "PageDown"
        case .UP:
            ok = true
            name = "Up"
        case .DOWN:
            ok = true
            name = "Down"
        case .LEFT:
            ok = true
            name = "Left"
        case .RIGHT:
            ok = true
            name = "Right"
        case .TAB:
            ok = true
            name = "Tab"
        case .KP_ENTER:
            ok = true
            name = "CR"
        case .HOME:
            ok = true
            name = "Home"
        case .END:
            ok = true
            name = "End"
        case .F1:
            ok = true
            name = "F1"
        case .F2:
            ok = true
            name = "F2"
        case .F3:
            ok = true
            name = "F3"
        case .F4:
            ok = true
            name = "F4"
        case .F5:
            ok = true
            name = "F5"
        case .F6:
            ok = true
            name = "F6"
        case .F7:
            ok = true
            name = "F7"
        case .F8:
            ok = true
            name = "F8"
        case .F9:
            ok = true
            name = "F9"
        case .F10:
            ok = true
            name = "F10"
        case .F11:
            ok = true
            name = "F11"
        case .F12:
            ok = true
            name = "F12"
        case:
            ok = false
            name = ""
    }

    return
}

modifier_prefix :: proc(mod : sdl2.Keymod, with_shift : bool) -> string
{
    result := ""
    if .LCTRL in mod || .RCTRL in mod
    {
        result = "C-"
    }
    
    if .LALT in mod
    {
        result = fmt.tprintf("%sM-", result)
    }

    if with_shift && (.LSHIFT in mod || .RSHIFT in mod)
    {
        result = fmt.tprintf("%sS-", result)
    }

    return result
}
