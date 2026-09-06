// Input inspector: prints every decoded event, newest first. Useful to see
// what a particular terminal sends for a key combination.
//
//   q / Esc / Ctrl-C   quit
//   Ctrl-Z             suspend to the shell (`fg` to come back)
//   Ctrl-L             clear the log
package main

import "core:fmt"
import "core:mem"
import "core:strings"
import "tui:events"
import "tui:renderer"
import "tui:term_sys"

main :: proc() {
    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)
        defer {
            for _, entry in track.allocation_map {
                fmt.eprintf("leak: %v bytes @ %v\n", entry.size, entry.location)
            }
            for entry in track.bad_free_array {
                fmt.eprintf("bad free: %p @ %v\n", entry.memory, entry.location)
            }
            mem.tracking_allocator_destroy(&track)
        }
    }

    if err := term_sys.init(); err != .None {
        fmt.eprintln("cannot initialise terminal:", err)
        return
    }
    defer term_sys.shutdown()
    context.assertion_failure_proc = term_sys.assertion_failure_proc

    if !events.init() {
        fmt.eprintln("cannot start the event poller")
        return
    }
    defer events.destroy()

    ren := renderer.make_renderer({})
    defer renderer.destroy_renderer(&ren)
    frame := strings.builder_make()
    defer strings.builder_destroy(&frame)

    // Newest event first. Strings inside events are owned by the poll
    // allocator, so anything we keep must be cloned.
    history := make([dynamic]string, 0, 256)
    defer {
        for line in history {
            delete(line)
        }
        delete(history)
    }
    remember :: proc(history: ^[dynamic]string, line: string) {
        inject_at(history, 0, line)
        for len(history) > 256 {
            delete(pop(history))
        }
    }

    total := 0
    for running := true; running; {
        defer free_all(context.temp_allocator)

        size, _ := term_sys.get_size()
        renderer.clean_renderer_cycle(&ren, {size.cols, size.rows})

        header := fmt.tprintf(" %d events  |  q quit  Ctrl-Z suspend  Ctrl-L clear ", total)
        renderer.render_box(&ren, {0, 0, size.cols, 1}, .Blue)
        renderer.render_text(&ren, {0, 0, size.cols, 1}, header, mode = .None, fg = .White, bg = .Blue, style = .Bold)
        for line, i in history {
            row := i + 1
            if row >= size.rows {
                break
            }
            fg: renderer.Color = .White if i > 0 else .BrightYellow
            renderer.render_text(&ren, {0, row, size.cols, 1}, line, mode = .None, fg = fg)
        }

        term_sys.push_begin_sync_update(&frame)
        term_sys.push_cursor_home(&frame)
        renderer.render_to_builder(&ren, &frame)
        term_sys.push_end_sync_update(&frame)
        term_sys.flush_builder(&frame)

        for evt in events.poll(events.FOREVER) {
            total += 1
            remember(&history, fmt.aprint(evt))

            switch {
            case events.is_char(evt, 'q'), events.is_key(evt, .Escape), events.is_char(evt, 'c', {.Ctrl}):
                running = false
            case events.is_char(evt, 'z', {.Ctrl}):
                term_sys.suspend()
            case events.is_char(evt, 'l', {.Ctrl}):
                for line in history {
                    delete(line)
                }
                clear(&history)
            }
        }
    }
}
