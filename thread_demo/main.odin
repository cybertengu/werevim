package main

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:time"

Shared :: struct
{
    mutex : sync.Mutex,
    numbers : [dynamic]int,
}

worker :: proc(shared : ^Shared)
{
    for i in 1..=5
    {
        time.sleep(100 * time.Millisecond) // Pretend this is os.read.
        sync.lock(&shared.mutex)
        append(&shared.numbers, i)
        sync.unlock(&shared.mutex)
    }
}

main :: proc()
{
    shared : Shared
    defer delete(shared.numbers)
    
    t := thread.create_and_start_with_poly_data(&shared, worker)
    
    for _ in 0..<6
    {
        time.sleep(120 * time.Millisecond) // Main thread doing other work.
        sync.lock(&shared.mutex)
        fmt.println("main sees: ", shared.numbers[:])
        clear(&shared.numbers)
        sync.unlock(&shared.mutex)
    }
    
    thread.join(t)
    thread.destroy(t)
}
