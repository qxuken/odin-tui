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
import "tui:sys"
import "tui:widgets"

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
    frame_time := time.now()
    fps := 0
    frames_counter_value := 0
    frames_counter_delta: time.Duration
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
        renderer.render_text(&ren, {0, 0, 16, 1}, "Enter something:", fg = .BrightGreen, bg = .Red, style = .Blinking)
        size_str := fmt.tprint(size)
        renderer.render_text(&ren, {2, 2, len(size_str), 1}, size_str, fg = .Black, bg = .White, style = .Bold)
        renderer.render_border(&ren, {2, 4, 6, 4}, {1, 1, 1, 1}, .Magenta)
        renderer.render_border(&ren, {10, 4, 8, 3}, {1, 1, 1, 1}, .Magenta)
        renderer.render_box(&ren, {11, 5, 7, 2}, .BrightYellow)
        renderer.render_box(&ren, {1, 10, 6, 6}, .BrightYellow)
        renderer.render_border(&ren, {19, 9, 11, 8}, {2, 4, 2, 2}, .Magenta)
        renderer.render_box(&ren, {21, 10, 6, 6}, .BrightYellow)
        renderer.render_box(&ren, {23, 11, 5, 5}, .Red)
        renderer.render_box(&ren, {19, 13, 6, 4}, .Blue)
        renderer.render_text(&ren, {19, 14, 6, 2}, "Sample Text", fg = .Red, style = .Inverse)
        renderer.render_box(&ren, {24, 12, 6, 3}, .Cyan)
        renderer.render_text(&ren, {21, 12, 6, 1}, "Text", fg = renderer.RBGColor{69, 69, 69}, style = .Italic)

        fps_str := fmt.tprint(fps)
        renderer.render_text(&ren, {size.width - len(fps_str), 0, len(fps_str), 1}, fps_str, fg = .Green, bg = .Black, style = .Bold)

        arena_allocator := virtual.arena_allocator(&ren.arena)
        out_builder := strings.builder_make(arena_allocator)
        sys.clear_screen(&out_builder)
        renderer.render_to_builder(&ren, &out_builder)
        rendered := strings.to_string(out_builder)
        io.write_string(out_stream, rendered)
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
