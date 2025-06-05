package main

import "core:fmt"
import "core:io"
import "core:mem"
import "core:mem/virtual"
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
import "tui:term_sys"

TARGET_FPS :: 60

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

    term_sys.set_utf8_terminal()
    term_sys.enable_raw_mode()
    term_sys.enable_mouse_capture()
    term_sys.enter_alternate_mode()
    term_sys.hide_cursor()
    defer term_sys.restore_terminal()
    defer term_sys.exit_alternate_mode()
    defer term_sys.show_cursor()

    out_stream := os.stream_from_handle(os.stdout)
    defer io.destroy(out_stream)

    events.init_event_poller()
    defer events.destroy_event_poller()

    ren := renderer.make_renderer({})
    frame_time := time.now()
    fps := 0
    frames_counter_value := 0
    frames_counter_delta: time.Duration
    history := make([dynamic]events.Event, 0, 1024)
    defer {
        when events.DEBUG_EVENTS {
            for event_raw in history {
                switch e in event_raw {
                case events.Unknown:
                    delete(e.raw)
                case events.Mouse_Event:
                    delete(e.raw)
                case events.Key:
                    delete(e.raw)
                }
            }
        }
        delete(history)
    }
    for {
        defer free_all(context.temp_allocator)
        size := term_sys.get_size()
        renderer.clean_renderer_cycle(&ren, {size.width, size.height})

        evts, ok := events.poll_event()
        if ok {
            for evt in evts {
                inject_at_elems(&history, 0, evt)
            }
            for evt in evts {
                if v, ok := evt.(events.Key); ok && unicode.to_lower(v.val) == 'q' {
                    return
                }
            }
        }
        if len(history) > 256 {
            when events.DEBUG_EVENTS {
                for i in 256 ..< len(history) {
                    switch e in history[i] {
                    case events.Unknown:
                        delete(e.raw)
                    case events.Mouse_Event:
                        delete(e.raw)
                    case events.Key:
                        delete(e.raw)
                    }
                }
            }
            resize(&history, 256)
        }

        for i in 0 ..< min(size.height, len(history)) {
            event := history[i]
            event_str := fmt.tprint(event)
            renderer.render_text(&ren, {0, i, len(event_str), 1}, event_str, mode = .None, fg = .White)
        }

        fps_str := fmt.tprint(fps)
        renderer.render_text(&ren, {size.width - len(fps_str), 0, len(fps_str), 1}, fps_str, fg = .Green, bg = .Black, style = .Bold)

        arena_allocator := virtual.arena_allocator(&ren.arena)
        out_builder := strings.builder_make(arena_allocator)
        term_sys.start_sync_update(&out_builder)
        term_sys.clear_screen(&out_builder)
        renderer.render_to_builder(&ren, &out_builder)
        term_sys.end_sync_update(&out_builder)

        io.write_string(out_stream, strings.to_string(out_builder))
        io.flush(out_stream)

        curr_time := time.now()
        delta_time := time.diff(frame_time, curr_time)
        frames_counter_delta += delta_time
        if frames_counter_delta >= time.Second {
            fps = frames_counter_value
            frames_counter_value = 0
            frames_counter_delta = 0
        } else {
            frames_counter_value += 1
        }
        time.sleep(max(time.Nanosecond, time.Second / TARGET_FPS - delta_time))
        frame_time = curr_time
    }

    fmt.print("\nPress ENTER to exit...")
}
