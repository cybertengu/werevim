package main

import "core:thread"
import "core:sync"
import "core:os"
import "vendor:sdl2"

Reader :: struct
{
    mutex : sync.Mutex,
    bytes : [dynamic]u8,
    nvim : ^Nvim,
    thread : ^thread.Thread, // Keep the handle, so reader_stop can join it
    event_type : u32,
}

reader_start :: proc(reader : ^Reader, nvim : ^Nvim, event_type : u32)
{
    reader.nvim = nvim
    reader.event_type = event_type
    reader.thread = thread.create_and_start_with_poly_data(reader, reader_proc)
}

reader_stop :: proc(reader : ^Reader)
{
    if reader.thread == nil
    {
        return
    }

    thread.join(reader.thread)
    thread.destroy(reader.thread)
    delete(reader.bytes)
}

reader_proc :: proc(reader : ^Reader)
{
    chunk : [4096]u8
    for
    {
        n, err := os.read(reader.nvim.from_nvim, chunk[:])
        if err != nil || n == 0
        {
            // Neovim exited.
            event : sdl2.Event
            event.type = sdl2.EventType(reader.event_type)
            event.user.code = NVIM_EXITED
            sdl2.PushEvent(&event)
            return
        }
        
        sync.lock(&reader.mutex)
        append(&reader.bytes, ..chunk[:n])
        sync.unlock(&reader.mutex)
        event : sdl2.Event
        event.type = sdl2.EventType(reader.event_type)
        sdl2.PushEvent(&event)
    }
}

reader_take_bytes :: proc(reader : ^Reader, pending : ^[dynamic]u8)
{
    sync.lock(&reader.mutex)
    append(pending, ..reader.bytes[:])
    clear(&reader.bytes)
    sync.unlock(&reader.mutex)
}
