// Package term_sys puts the controlling terminal into the state a full-screen
// application needs (raw input, alternate screen, mouse reporting, ...) and
// guarantees it is restored on exit, on fatal signals, on panics and around
// job-control suspension.
//
// Typical use:
//
//     term_sys.init() or_else panic
//     defer term_sys.shutdown()
//     context.assertion_failure_proc = term_sys.assertion_failure_proc
//
// Everything that produces output goes through `write` / `flush_builder`, which
// write directly to the terminal file descriptor without any libc buffering.
package term_sys

import "ansi"
import "base:runtime"
import "core:strings"

Window_Size :: struct {
    cols:   int,
    rows:   int,
    xpixel: int, // 0 when the terminal does not report it
    ypixel: int,
}

Options :: struct {
    alternate_screen: bool,
    hide_cursor:      bool,
    mouse:            bool,
    bracketed_paste:  bool,
    focus_events:     bool,
}

DEFAULT_OPTIONS :: Options {
    alternate_screen = true,
    hide_cursor      = true,
    mouse            = true,
    bracketed_paste  = true,
    focus_events     = true,
}

Error :: enum {
    None,
    Already_Initialized,
    Not_A_Terminal,
    Get_Mode_Failed,
    Set_Mode_Failed,
}

State :: enum {
    Inactive,
    Active,
    Suspended,
}

@(private)
state: State

@(private)
options: Options

// Escape sequences that switch the terminal into / out of the configured modes.
// Stored in fixed buffers so they can be written from signal handlers.
@(private)
enter_seq_buf: [256]u8
@(private)
enter_seq_len: int
@(private)
leave_seq_buf: [256]u8
@(private)
leave_seq_len: int

// Switches the terminal into raw mode and applies `opts`. Installs hooks that
// restore the terminal on exit and on fatal signals. Safe to call once.
init :: proc(opts := DEFAULT_OPTIONS) -> Error {
    if state != .Inactive {
        return .Already_Initialized
    }
    options = opts
    build_mode_sequences(opts)

    err := _init()
    if err != .None {
        return err
    }
    state = .Active
    return .None
}

// Restores the terminal to the state it had before `init`. Idempotent, and
// safe to call from `atexit` hooks and signal handlers.
shutdown :: proc "c" () {
    if state == .Inactive {
        return
    }
    if state == .Active {
        _leave_modes()
    }
    state = .Inactive
}

is_active :: proc "contextless" () -> bool {
    return state == .Active
}

// Restores the terminal and stops the process (like Ctrl-Z in a cooked
// terminal). When the process is continued the terminal modes are re-applied
// and a resize signal is raised so the application redraws.
// A no-op on platforms without job control.
suspend :: proc() {
    if state != .Active {
        return
    }
    _suspend()
}

get_size :: proc() -> (size: Window_Size, ok: bool) {
    return _get_size()
}

// Writes the whole string to the terminal, retrying on partial writes.
write :: proc(s: string) {
    _write(transmute([]u8)s)
}

write_bytes :: proc(b: []u8) {
    _write(b)
}

// Writes the builder's contents to the terminal and empties it.
flush_builder :: proc(b: ^strings.Builder) {
    _write(b.buf[:])
    strings.builder_reset(b)
}

// Drop-in `context.assertion_failure_proc` that restores the terminal before
// printing the panic message, so the message lands on the normal screen.
assertion_failure_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
    shutdown()
    runtime.default_assertion_failure_proc(prefix, message, loc)
}

// -- Frame building helpers -------------------------------------------------
// These only append escape sequences to a builder; nothing reaches the
// terminal until the builder is flushed.

push_clear_screen :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_CLEAR_SCREEN)
    strings.write_string(out, ansi.CSI_CURSOR_MOVE_HOME)
}

push_erase_below :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_ERASE_BELOW)
}

push_erase_line_right :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_ERASE_LINE_RIGHT)
}

push_cursor_home :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_CURSOR_MOVE_HOME)
}

// Zero based column / row.
push_move_cursor :: proc(out: ^strings.Builder, col, row: int) {
    strings.write_string(out, "\x1b[")
    strings.write_int(out, row + 1)
    strings.write_byte(out, ';')
    strings.write_int(out, col + 1)
    strings.write_byte(out, 'H')
}

push_show_cursor :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_SHOW_CURSOR)
}

push_hide_cursor :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_HIDE_CURSOR)
}

push_reset_style :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_STYLE_RESET)
}

push_begin_sync_update :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_SYNC_UPDATE_UP)
}

push_end_sync_update :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_SYNC_UPDATE_DOWN)
}

// -- Internals ---------------------------------------------------------------

@(private)
build_mode_sequences :: proc(opts: Options) {
    enter := strings.builder_from_bytes(enter_seq_buf[:])
    leave := strings.builder_from_bytes(leave_seq_buf[:])

    if opts.alternate_screen {
        strings.write_string(&enter, ansi.CSI_ALTERNATE_MODE_UP)
        strings.write_string(&enter, ansi.CSI_CLEAR_SCREEN)
        strings.write_string(&enter, ansi.CSI_CURSOR_MOVE_HOME)
    }
    if opts.hide_cursor {
        strings.write_string(&enter, ansi.CSI_HIDE_CURSOR)
    }
    if opts.mouse {
        strings.write_string(&enter, ansi.CSI_MOUSE_TRACKING_UP)
        strings.write_string(&enter, ansi.CSI_MOUSE_DRAGING_UP)
        strings.write_string(&enter, ansi.CSI_MOUSE_ALL_MOTION_TRACKING_UP)
        strings.write_string(&enter, ansi.CSI_MOUSE_EXTENDING_MODE_UP)
        strings.write_string(&enter, ansi.CSI_MOUSE_EXTENDING_TRACKING_UP)
    }
    if opts.bracketed_paste {
        strings.write_string(&enter, ansi.CSI_BRACKETED_PASTE_UP)
    }
    if opts.focus_events {
        strings.write_string(&enter, ansi.CSI_FOCUS_EVENTS_UP)
    }

    // Leave in reverse order, and always reset styling first so nothing
    // leaks onto the normal screen.
    strings.write_string(&leave, ansi.CSI_STYLE_RESET)
    if opts.focus_events {
        strings.write_string(&leave, ansi.CSI_FOCUS_EVENTS_DOWN)
    }
    if opts.bracketed_paste {
        strings.write_string(&leave, ansi.CSI_BRACKETED_PASTE_DOWN)
    }
    if opts.mouse {
        strings.write_string(&leave, ansi.CSI_MOUSE_EXTENDING_TRACKING_DOWN)
        strings.write_string(&leave, ansi.CSI_MOUSE_EXTENDING_MODE_DOWN)
        strings.write_string(&leave, ansi.CSI_MOUSE_ALL_MOTION_TRACKING_DOWN)
        strings.write_string(&leave, ansi.CSI_MOUSE_DRAGING_DOWN)
        strings.write_string(&leave, ansi.CSI_MOUSE_TRACKING_DOWN)
    }
    if opts.hide_cursor {
        strings.write_string(&leave, ansi.CSI_SHOW_CURSOR)
    }
    if opts.alternate_screen {
        strings.write_string(&leave, ansi.CSI_ALTERNATE_MODE_DOWN)
    }

    enter_seq_len = len(enter.buf)
    leave_seq_len = len(leave.buf)
}

@(private)
enter_seq :: proc "contextless" () -> []u8 {
    return enter_seq_buf[:enter_seq_len]
}

@(private)
leave_seq :: proc "contextless" () -> []u8 {
    return leave_seq_buf[:leave_seq_len]
}
