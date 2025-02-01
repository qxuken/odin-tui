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

DEBUG_EVENTS :: #config(DEBUG_EVENTS, false)

// TODO: Add states and unify windows and posix
Key :: struct {
    val: rune,
    raw: string,
}

// TODO: Simplify types to clicked or not
Mouse_Event_Type :: enum {
    LeftClick   = 0,
    MiddleClick = 1,
    RightClick  = 2,
    LeftDrag    = 32,
    MiddleDrag  = 33,
    RightDrag   = 34,
    Move        = 35,
    ScrollUp    = 64,
    ScrollDown  = 65,
    ScrollRight = 66,
    ScrollLeft  = 67,
    Release     = 120,
}

Mouse_Event :: struct {
    m:   Mouse_Event_Type,
    x:   int,
    y:   int,
    raw: string,
}

Unknown :: struct {
    raw: string,
}

Event :: union #no_nil {
    Unknown,
    Key,
    Mouse_Event,
}

init_event_poller :: proc() {
    _init_event_poller()
}

destroy_event_poller :: proc() {
    _destroy_event_poller()
}

poll_event :: proc(allocator := context.temp_allocator) -> ([]Event, bool) {
    return _poll_event(allocator)
}
