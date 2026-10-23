package main

import "core:fmt"
import "core:os"
import "core:time"
import win "core:sys/windows"

Nvim :: struct
{
    process : os.Process,
    to_nvim : ^os.File, // Write end of pipe A.
    from_nvim : ^os.File, // Read end of pipe B.
    next_id : int,
}

encode_request :: proc(buf : ^[dynamic]u8, msgid : int, method : string, args : Array)
{
    encode_array_header(buf, 4)
    encode_int(buf, 0)
    encode_int(buf, i64(msgid))
    encode_string(buf, method)
    encode_value(buf, Value(args))
}

nvim_start :: proc() -> (nvim : Nvim, ok : bool)
{
    nvim.next_id = 1
    a_r, a_w, a_error := os.pipe()
    if a_error != nil
    {
        fmt.eprintfln("Something went wrong starting a pipe A: %v", a_error)
        ok = false
        return
    }

    b_r, b_w, b_error := os.pipe()
    if b_error != nil
    {
        fmt.eprintfln("Something went wrong starting a pipe B: %v", b_error)
        os.close(a_r)
        os.close(a_w)
        ok = false

        return
    }
    
    when ODIN_OS == .Windows
    {
        win.SetHandleInformation(win.HANDLE(os.fd(a_w)), win.HANDLE_FLAG_INHERIT, 0)
        win.SetHandleInformation(win.HANDLE(os.fd(b_r)), win.HANDLE_FLAG_INHERIT, 0)
    }

    outcome : os.Error
    nvim.process, outcome = os.process_start(os.Process_Desc{command = {"nvim", "--embed"}, stdin = a_r, stdout = b_w, stderr = os.stderr})
    if outcome != nil
    {
        fmt.eprintfln("Something went wrong starting a process: %v", outcome)
        os.close(a_r)
        os.close(a_w)
        os.close(b_w)
        os.close(b_r)
        ok = false

        return
    }

    nvim.to_nvim = a_w
    nvim.from_nvim = b_r
    os.close(a_r)
    os.close(b_w)
    ok = true

    return
}

nvim_stop :: proc(nvim : ^Nvim)
{
    error_to := os.close(nvim.to_nvim)
    if error_to != nil
    {
        fmt.eprintfln("Something went wrong closing the to-nvim pipe: %v", error_to)
    }

    error_from := os.close(nvim.from_nvim)
    if error_from != nil
    {
        fmt.eprintfln("Something went wrong closing the from-nvim pipe: %v", error_from)
    }

    timeout := time.Second * 2
    state1, err1 := os.process_wait(nvim.process, timeout)
    if err1 == os.General_Error.Timeout
    {
        fmt.eprintfln("Neovim didn't exit by itself in time, so will kill process: %v", err1)
        kill_error := os.process_kill(nvim.process)
        if kill_error != nil
        {
            fmt.eprintfln("Something went wrong killing the process: %v", kill_error)
        }

        _, err3 := os.process_wait(nvim.process, timeout)
        if err3 == os.General_Error.Timeout
        {
            fmt.eprintfln("Something went wrong waiting for the kill process step: %v", err3)
        }
    }
    else if err1 != nil
    {
        fmt.eprintfln("Waiting for process to close failed: %v", err1)
    }
    else if state1.exit_code != 0
    {
        fmt.eprintfln("Neovim exited with code %d", state1.exit_code)
    }
}

nvim_request :: proc(nvim : ^Nvim, method : string, args : Array) -> (msgid : int, ok : bool)
{
    msgid = nvim.next_id
    nvim.next_id += 1
    buf : [dynamic]u8
    defer delete(buf)
    encode_request(&buf, msgid, method, args)
    n : int
    err : os.Error
    counter : int
    for
    {
        n, err = os.write(nvim.to_nvim, buf[counter:])
        if err != nil
        {
            fmt.eprintfln("Did not write to Neovim for request: %v", err)
            ok = false
            break
        }

        if n == 0
        {
            fmt.eprintfln("Nothing to write.")
            ok = false
            break
        }

        counter += n
        if counter >= len(buf)
        {
            ok = true
            break
        }
    }

    return
}
