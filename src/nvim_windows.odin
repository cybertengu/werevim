package main

import "core:os"
import win "core/sys/windows"

// Stop the child process from inheriting the parent's ends of the pipes.
make_parent_ends_private :: proc(a_w, b_r : ^os.File)
{
    win.SetHandleInformation(win.HANDLE(os.fd(a_w)), win.HANDLE_FLAG_INHERIT, 0)
    win.SetHandleInformation(win.HANDLE(os.fd(b_r)), win.HANDLE_FLAG_INHERIT, 0)
}
