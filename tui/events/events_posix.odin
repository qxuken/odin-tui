#+build darwin, linux, netbsd, openbsd, freebsd
#+private
package events

import "base:runtime"
import "core:c"
import psx "core:sys/posix"
import "core:time"
import "tui:term_sys"

// How long a lone ESC may sit in the buffer before it is reported as the
// Escape key rather than the start of a sequence.
ESC_TIMEOUT :: 30 * time.Millisecond

@(private = "file")
parser: Parser

// Self-pipe: the SIGWINCH handler writes a byte so `poll` wakes up.
@(private = "file")
wake_fds: [2]psx.FD = {-1, -1}

@(private = "file")
partial_since: time.Tick

_init :: proc() -> bool {
    parser.buf = make([dynamic]u8, 0, 256)
    if psx.pipe(&wake_fds) != .OK {
        return false
    }
    for fd in wake_fds {
        psx.fcntl(fd, .SETFD, psx.FD_CLOEXEC)
        flags := psx.fcntl(fd, .GETFL)
        psx.fcntl(fd, .SETFL, flags | psx.O_NONBLOCK)
    }

    act: psx.sigaction_t
    act.sa_handler = winch_handler
    psx.sigemptyset(&act.sa_mask)
    act.sa_flags = {.RESTART}
    psx.sigaction(psx.Signal(psx.SIGWINCH), &act, nil)
    return true
}

_destroy :: proc() {
    act: psx.sigaction_t
    act.sa_handler = cast(proc "c" (psx.Signal))psx.SIG_DFL
    psx.sigemptyset(&act.sa_mask)
    psx.sigaction(psx.Signal(psx.SIGWINCH), &act, nil)

    for &fd in wake_fds {
        if fd >= 0 {
            psx.close(fd)
            fd = -1
        }
    }
    delete(parser.buf)
    parser = {}
}

@(private = "file")
winch_handler :: proc "c" (_: psx.Signal) {
    b: u8 = 1
    psx.write(wake_fds[1], ([^]u8)(&b), 1)
}

_poll :: proc(timeout: time.Duration, allocator: runtime.Allocator) -> []Event {
    out := make([dynamic]Event, allocator)

    // Something may be left over from the previous call.
    drain(&out, false, allocator)
    if len(out) > 0 {
        return out[:]
    }

    start := time.tick_now()
    for {
        remaining := timeout
        if timeout >= 0 {
            remaining = max(timeout - time.tick_since(start), 0)
        }

        // A pending ESC only waits for the escape timeout, not the caller's.
        wait := remaining
        if parser_has_partial(&parser) {
            esc_left := max(ESC_TIMEOUT - time.tick_since(partial_since), 0)
            if wait < 0 || esc_left < wait {
                wait = esc_left
            }
        }

        readable, woken := wait_input(wait)
        if woken {
            drain_wake_pipe()
            size, _ := term_sys.get_size()
            append(&out, Resize{cols = size.cols, rows = size.rows})
        }
        if readable {
            read_stdin()
        }

        flush := parser_has_partial(&parser) && time.tick_since(partial_since) >= ESC_TIMEOUT
        drain(&out, flush, allocator)
        if len(out) > 0 {
            return out[:]
        }
        if timeout >= 0 && time.tick_since(start) >= timeout {
            return out[:]
        }
    }
}

@(private = "file")
drain :: proc(out: ^[dynamic]Event, flush: bool, allocator: runtime.Allocator) {
    had_partial := parser_has_partial(&parser)
    parser_drain(&parser, out, flush, allocator)
    if parser_has_partial(&parser) && !had_partial {
        partial_since = time.tick_now()
    }
}

@(private = "file")
wait_input :: proc(timeout: time.Duration) -> (readable, woken: bool) {
    fds := [2]psx.pollfd{{fd = psx.STDIN_FILENO, events = {.IN}}, {fd = wake_fds[0], events = {.IN}}}

    ms: c.int = -1
    if timeout >= 0 {
        // Round up so a 1ns wait does not become a busy loop.
        whole := (timeout + time.Millisecond - 1) / time.Millisecond
        ms = c.int(min(whole, time.Duration(max(c.int))))
    }

    n := psx.poll(raw_data(fds[:]), 2, ms)
    if n <= 0 {
        return false, false
    }
    readable = fds[0].revents & {.IN, .HUP, .ERR} != {}
    woken = fds[1].revents & {.IN} != {}
    return
}

@(private = "file")
drain_wake_pipe :: proc() {
    tmp: [64]u8
    for psx.read(wake_fds[0], raw_data(tmp[:]), len(tmp)) > 0 {}
}

@(private = "file")
read_stdin :: proc() {
    tmp: [4096]u8
    for {
        n := psx.read(psx.STDIN_FILENO, raw_data(tmp[:]), len(tmp))
        if n < 0 && psx.errno() == .EINTR {
            continue
        }
        if n > 0 {
            append(&parser.buf, ..tmp[:n])
        }
        return
    }
}
