// Renderer showcase. Also shows how to combine a blocking event loop with a
// periodic redraw: the clock in the corner ticks once a second and the rest
// of the screen is only redrawn when something happens.
//
//   q / Esc     quit
//   arrows      move the cursor box
//   mouse       drag the cursor box
package main

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:time"
import "tui:events"
import "tui:renderer"
import "tui:term_sys"

TICK :: time.Second

State :: struct {
    cursor:   [2]int,
    mouse:    [2]int,
    dragging: bool,
    redraws:  int,
}

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

    state := State {
        cursor = {40, 5},
    }
    for running := true; running; {
        defer free_all(context.temp_allocator)

        size, _ := term_sys.get_size()
        renderer.clean_renderer_cycle(&ren, {size.cols, size.rows})
        draw(&ren, &state, size)

        term_sys.push_begin_sync_update(&frame)
        term_sys.push_cursor_home(&frame)
        renderer.render_to_builder(&ren, &frame)
        term_sys.push_end_sync_update(&frame)
        term_sys.flush_builder(&frame)

        // Wake up at most once a second for the clock; any input wakes us
        // earlier and is handled straight away.
        for evt in events.poll(TICK) {
            switch e in evt {
            case events.Key:
                switch {
                case events.is_char(evt, 'q'), events.is_key(evt, .Escape), events.is_char(evt, 'c', {.Ctrl}):
                    running = false
                case e.code == .Up:
                    state.cursor.y -= 1
                case e.code == .Down:
                    state.cursor.y += 1
                case e.code == .Left:
                    state.cursor.x -= 1
                case e.code == .Right:
                    state.cursor.x += 1
                }
            case events.Mouse:
                state.mouse = {e.col, e.row}
                switch e.action {
                case .Press:
                    state.dragging = e.button == .Left
                case .Release:
                    state.dragging = false
                case .Drag:
                    if state.dragging {
                        state.cursor = state.mouse
                    }
                case .Move, .Scroll:
                }
            case events.Resize, events.Paste, events.Focus, events.Unknown:
            }
        }
    }
}

draw :: proc(ren: ^renderer.Renderer, state: ^State, size: term_sys.Window_Size) {
    state.redraws += 1

    // Rulers along the edges.
    for col := 0; col < size.cols; col += 10 {
        label := fmt.tprint(col)
        renderer.render_text(ren, {col, 0, len(label), 1}, label, fg = .White, style = .Dim)
    }
    for row in 1 ..< size.rows {
        label := fmt.tprint(row)
        renderer.render_text(ren, {0, row, len(label), 1}, label, fg = .White, style = .Dim)
    }

    // Status line.
    now, _ := time.time_to_datetime(time.now())
    status := fmt.tprintf("%02d:%02d:%02d UTC  size %dx%d  redraws %d  mouse %v", now.hour, now.minute, now.second, size.cols, size.rows, state.redraws, state.mouse)
    renderer.render_text(ren, {size.cols - len(status), 0, len(status), 1}, status, mode = .None, fg = .Green, bg = .Black, style = .Bold)

    // Styled text.
    renderer.render_text(ren, {4, 2, 40, 1}, "Blinking bright green on red", fg = .BrightGreen, bg = .Red, style = .Blinking)
    renderer.render_text(ren, {4, 3, 40, 1}, "Italic true colour", fg = renderer.RBG_Color{255, 160, 60}, style = .Italic)
    renderer.render_text(ren, {4, 4, 40, 1}, "Inverse", fg = renderer.RBG_Color{42, 42, 42}, style = .Inverse)

    // Borders, frames and boxes.
    renderer.render_border(ren, {4, 6, 8, 4}, {1, 1, 1, 1}, .Magenta)
    renderer.render_border(ren, {14, 6, 12, 6}, {2, 4, 2, 2}, .Magenta)
    renderer.render_box(ren, {16, 8, 6, 2}, .BrightYellow)
    renderer.render_frame(ren, {28, 6, 14, 6}, fg = .Cyan)
    renderer.render_frame(ren, {30, 7, 10, 4}, fg = .BrightCyan, rounded = true)
    renderer.render_text(ren, {31, 8, 8, 2}, "framed text", fg = .White)
    renderer.render_frame(ren, {44, 6, 1, 6}, fg = .Yellow)
    renderer.render_frame(ren, {46, 6, 10, 1}, fg = .Yellow)

    // Graphemes: single emoji, ZWJ family, and a flag are each one cluster.
    renderer.render_text(ren, {4, 12, 20, 1}, "👪 👨‍👩‍👧 🇯🇵 ok", mode = .None)

    // Wrapping modes.
    sample := "Wrap Words.\nAfter newline.\tAfter Tab.\nElevenletterword Elevenlette"
    renderer.render_text(ren, {4, 14, 30, 1}, "No wrap text.\nAfter newline.\tAfter Tab", mode = .None, fg = .White, bg = .Magenta)
    renderer.render_text(ren, {4, 15, 27, 2}, "Wrap Line.\nAfter newline.\tAfter Tab", mode = .Line, fg = .Yellow, bg = .Red)
    renderer.render_text(ren, {4, 18, 11, 8}, sample, mode = .Word, fg = .White, bg = .Blue)
    renderer.render_text(ren, {17, 18, 20, 8}, sample, mode = .Word, fg = .White, bg = .Blue)

    // Scissors: the text is clipped to the frame.
    renderer.render_frame(ren, {40, 14, 20, 6}, fg = .BrightBlack)
    renderer.start_scissors(ren, {41, 15, 18, 4})
    renderer.render_text(ren, {41, 15, 40, 10}, "This paragraph is longer than the frame it lives in and gets clipped by the scissors instead of spilling over.", fg = .White)
    renderer.end_scissors(ren)

    // Movable cursor box.
    state.cursor.x = clamp(state.cursor.x, 0, size.cols - 3)
    state.cursor.y = clamp(state.cursor.y, 0, size.rows - 3)
    renderer.render_frame(ren, {state.cursor.x, state.cursor.y, 3, 3}, fg = .BrightRed, rounded = true)
    renderer.render_text(ren, {state.cursor.x + 1, state.cursor.y + 1, 1, 1}, "x", fg = .BrightRed, style = .Bold)
}
