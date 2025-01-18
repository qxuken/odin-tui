package main

import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sys/windows"
import "core:time"
import "core:unicode/utf8"
import "term"
import "widgets"

main :: proc() {
	term.set_utf8_terminal()
	term.enable_raw_mode()
	term.enter_alternate_mode()
	term.enable_mouse_capture()
	term.hide_cursor()
	defer term.restore_terminal()
	defer term.exit_alternate_mode()
	defer term.show_cursor()

	in_stream := os.stream_from_handle(os.stdin)
	defer io.destroy(in_stream)
	out_stream := os.stream_from_handle(os.stdout)
	defer io.destroy(out_stream)

	buf: [128]u8
	n: int
	err: io.Error
	history := make([dynamic]DebugEvent)
	for {
		defer free_all(context.temp_allocator)
		size := term.get_size()
		term.clear_screen(out_stream)

		io.write_string(out_stream, "Enter something:\r\n")
		io.write_string(out_stream, fmt.tprintln(buf[:n]))
		for h in history[:len(history)] {
			io.write_string(out_stream, fmt.tprintln(h))
		}
		io.flush(out_stream)

		n, err = io.read(in_stream, buf[:])
		if err == nil {
			evts := process_input(buf[:n])
			for evt in evts {
				if v, ok := evt.event.(Key); ok && v.val == 'q' {
					return
				}
				inject_at_elem(&history, 0, evt)
			}
			if diff := (len(history) - cast(int)size.height + 10); diff > 0 {
				for _ in 0 ..< diff {
					el := pop(&history)
					delete(el.raw)
				}
			}
		}
		time.sleep(1.667e+7)
	}

	fmt.print("\nPress ENTER to exit...")
}

Key :: struct {
	val: rune,
}

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

DebugEvent :: struct {
	raw:   string,
	bytes: []u8,
	event: Event,
}

process_input :: proc(buf: []u8) -> []DebugEvent {
	res := make([dynamic]DebugEvent, allocator = context.temp_allocator)
	s := strings.clone_from_bytes(buf[:], allocator = context.temp_allocator)

	for p in strings.split_iterator(&s, "\x1B") {
		if len(p) == 0 {
			continue
		}
		sc := strings.clone(p)
		rb := cast([]u8)sc

		switch {
		case len(p) > 6 && p[0] == '[' && p[1] == '<':
			evt := parse_sgr_mouse(p[2:]) or_continue
			append(&res, DebugEvent{sc, rb, evt})
		case len(p) > 0:
			append(&res, DebugEvent{sc, rb, Key{rune(p[0])}})
		case true:
			append(&res, DebugEvent{sc, rb, Unknown{}})
		}
	}
	return res[:]
}
parse_sgr_mouse :: proc(s: string) -> (evt: MouseEvent, ok: bool) {
	parts := strings.split(s, ";", allocator = context.temp_allocator)
	if len(parts) != 3 {
		return
	}
	mouse_event_type := cast(MouseEventType)strconv.atoi(parts[0])
	if parts[2][len(parts[2]) - 1] == 'm' {
		mouse_event_type = .Release
	}
	return MouseEvent{mouse_event_type, strconv.atoi(parts[1]), strconv.atoi(parts[2])}, true
}
