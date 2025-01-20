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

// TODO: Add states and unify windows and posix
Key :: struct {
	val: rune,
}

// TODO: Simplify types to clicked or not
MouseEventType :: enum {
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

MouseEvent :: struct {
	m: MouseEventType,
	x: int,
	y: int,
}

Unknown :: struct {}

Event :: union #no_nil {
	Unknown,
	Key,
	MouseEvent,
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
