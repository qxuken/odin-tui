#+build darwin, linux
package events

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sys/windows"
import "core:time"
import "core:unicode/utf8"

in_stream: io.Stream
in_buf: [128]u8

_init_event_poller :: proc() {
    in_stream = os.stream_from_handle(os.stdin)
}

_destroy_event_poller :: proc() {
    io.destroy(in_stream)
}

_poll_event :: proc(allocator := context.temp_allocator) -> ([]Event, bool) {
    n, err := io.read(in_stream, in_buf[:])
    if err != nil {
        return nil, false
    }
    evts := process_input(in_buf[:n], allocator)
    return evts, true
}


process_input :: proc(buf: []u8, allocator := context.temp_allocator) -> []Event {
    res := make([dynamic]Event, allocator = allocator)
    s := strings.clone_from_bytes(buf[:], allocator = allocator)

    for p in strings.split_iterator(&s, "\x1B") {
        if len(p) == 0 {
            continue
        }

        switch {
        case len(p) > 6 && p[0] == '[' && p[1] == '<':
            evt := parse_sgr_mouse(p[2:], allocator) or_continue
            append(&res, evt)
        case len(p) > 0:
            append(&res, Key{utf8.rune_at(p, 0)})
        case true:
            append(&res, Unknown{})
        }
    }
    return res[:]
}

parse_sgr_mouse :: proc(s: string, allocator := context.temp_allocator) -> (evt: MouseEvent, ok: bool) {
    parts := strings.split(s, ";", allocator = allocator)
    if len(parts) != 3 {
        return
    }
    mouse_event_type := cast(MouseEventType)strconv.atoi(parts[0])
    if parts[2][len(parts[2]) - 1] == 'm' {
        mouse_event_type = .Release
    }
    return MouseEvent{mouse_event_type, strconv.atoi(parts[1]), strconv.atoi(parts[2])}, true
}
