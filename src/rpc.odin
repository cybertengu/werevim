package main

// Decodes every complete message at the front of pending into messages,
// then removes those bytes. A partial message stays in pending.
drain_messages :: proc(pending : ^[dynamic]u8, messages : ^[dynamic]Value) -> Decode_Status
{
    return .Invalid
}
