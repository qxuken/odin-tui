package main

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sys/windows"
import "core:time"
import "core:unicode"
import "core:unicode/utf8"
import "tui:events"
import "tui:renderer"
import "tui:sys"
import "tui:widgets"

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	sys.set_utf8_terminal()
	sys.enable_raw_mode()
	sys.enable_mouse_capture()
	sys.enter_alternate_mode()
	sys.hide_cursor()
	defer sys.restore_terminal()
	defer sys.exit_alternate_mode()
	defer sys.show_cursor()

	out_stream := os.stream_from_handle(os.stdout)
	defer io.destroy(out_stream)

	events.init_event_poller()
	defer events.destroy_event_poller()

	ren := renderer.make_renderer({})
	for {
		defer free_all(context.temp_allocator)
		size := sys.get_size()
		renderer.clean_renderer_cycle(&ren, {size.width, size.height})

		evts, ok := events.poll_event()
		if ok {
			for evt in evts {
				if v, ok := evt.(events.Key); ok && unicode.to_lower(v.val) == 'q' {
					return
				}
			}
		}

		renderer.render_text(
			&ren,
			{0, 0, 16, 1},
			"Enter something:",
			fg = .BrightGreen,
			bg = .Red,
			style = .Blinking,
		)
		size_str := fmt.tprint(size)
		renderer.render_text(
			&ren,
			{1, 2, len(size_str), 1},
			size_str,
			fg = .Black,
			bg = .White,
			style = .Bold,
		)
		renderer.render_border(&ren, {3, 3, 8, 4}, {1, 1, 1, 1}, .BrightRed)
		renderer.render_box(&ren, {4, 4, 7, 3}, .BrightYellow)

		sys.clear_screen(out_stream)
		io.write_string(out_stream, renderer.to_string(&ren))
		io.flush(out_stream)

		time.sleep(1.667e+7)
	}

	fmt.print("\nPress ENTER to exit...")
}
