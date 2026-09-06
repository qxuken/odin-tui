// The smallest useful program: set the terminal up, sleep until something
// happens, redraw, tear down.
package main

import "core:fmt"
import "core:strings"
import "tui:events"
import "tui:renderer"
import "tui:term_sys"

main :: proc() {
    if err := term_sys.init(); err != .None {
        fmt.eprintln("cannot initialise terminal:", err)
        return
    }
    defer term_sys.shutdown()
    // Make sure a panic message lands on the normal screen.
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

    counter := 0
    for running := true; running; {
        defer free_all(context.temp_allocator)

        // -- draw ------------------------------------------------------------
        size, _ := term_sys.get_size()
        renderer.clean_renderer_cycle(&ren, {size.cols, size.rows})
        renderer.render_frame(&ren, {0, 0, size.cols, size.rows}, fg = .BrightBlack, rounded = true)
        renderer.render_text(&ren, {2, 1, size.cols - 4, 1}, "Press any key to count, q or Esc to quit.", fg = .White, style = .Bold)
        renderer.render_text(&ren, {2, 3, size.cols - 4, 1}, fmt.tprintf("events seen: %d", counter), fg = .Green)

        term_sys.push_begin_sync_update(&frame)
        term_sys.push_cursor_home(&frame)
        renderer.render_to_builder(&ren, &frame)
        term_sys.push_end_sync_update(&frame)
        term_sys.flush_builder(&frame)

        // -- wait ------------------------------------------------------------
        // Blocks until there is input or the window is resized: no polling,
        // no frame rate, zero CPU while idle.
        for evt in events.poll(events.FOREVER) {
            counter += 1
            if events.is_char(evt, 'q') || events.is_key(evt, .Escape) || events.is_char(evt, 'c', {.Ctrl}) {
                running = false
            }
        }
    }
}
