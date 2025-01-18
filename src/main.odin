package main

import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sys/windows"
import "core:time"
import "core:unicode"
import "core:unicode/utf8"
import "events"
import "term"
import "widgets"

main :: proc() {
	term.set_utf8_terminal()
	term.enable_raw_mode()
	term.enable_mouse_capture()
	term.enter_alternate_mode()
	term.hide_cursor()
	defer term.restore_terminal()
	defer term.exit_alternate_mode()
	defer term.show_cursor()

	out_stream := os.stream_from_handle(os.stdout)
	defer io.destroy(out_stream)

	events.init_event_poller()
	defer events.destroy_event_poller()

	history := make([dynamic]events.DebugEvent)
	for {
		defer free_all(context.temp_allocator)
		size := term.get_size()
		evts, ok := events.poll_event()
		if ok {
			for evt in evts {
				if v, ok := evt.event.(events.Key); ok && unicode.to_lower(v.val) == 'q' {
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
		term.clear_screen(out_stream)

		io.write_string(out_stream, "Enter something:\r\n")
		io.write_string(out_stream, fmt.tprintln(size, "\r\n"))
		for h in history {
			io.write_string(out_stream, fmt.tprintln(h))
		}
		io.flush(out_stream)

		time.sleep(1.667e+7)
	}

	fmt.print("\nPress ENTER to exit...")
}
