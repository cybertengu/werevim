package main

// Decodes every complete message at the front of pending into messages,
// then removes those bytes. A partial message stays in pending.
drain_messages :: proc(pending : ^[dynamic]u8, messages : ^[dynamic]Value) -> Decode_Status
{
    offset := 0
    decode_status : Decode_Status = .Invalid
    loop: for
    {
        value, consumed, status := decode(pending[offset:])
        
        switch status
        {
            case .Invalid, .Need_More:
                decode_status = status
                break loop
            case .Ok:
                append(messages, value)
                offset += consumed
        }
    }
    
    remove_range(pending, 0, offset)
    return decode_status
}
