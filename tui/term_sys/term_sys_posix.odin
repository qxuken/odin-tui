#+build darwin, linux, netbsd, openbsd, freebsd
#+private
package term_sys

import psx "core:sys/posix"

@(private = "file")
orig_termios: psx.termios

@(private = "file")
hooks_installed: bool

_init :: proc() -> Error {
    if !psx.isatty(psx.STDIN_FILENO) || !psx.isatty(psx.STDOUT_FILENO) {
        return .Not_A_Terminal
    }
    if psx.tcgetattr(psx.STDIN_FILENO, &orig_termios) != .OK {
        return .Get_Mode_Failed
    }
    if !apply_raw_mode() {
        return .Set_Mode_Failed
    }
    install_hooks()
    _write(enter_seq())
    return .None
}

_leave_modes :: proc "contextless" () {
    _write(leave_seq())
    psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &orig_termios)
}

_suspend :: proc() {
    // The SIGTSTP handler below restores the terminal, and the SIGCONT handler
    // re-applies the modes once the shell continues us.
    psx.raise(.SIGTSTP)
    // The kernel discards stop signals for orphaned process groups (no job
    // control shell). Then no SIGCONT ever arrives, so resume ourselves.
    if state == .Suspended {
        resume()
    }
}

_write :: proc "contextless" (data: []u8) {
    rest := data
    for len(rest) > 0 {
        n := psx.write(psx.STDOUT_FILENO, raw_data(rest), len(rest))
        if n < 0 {
            #partial switch psx.errno() {
            case .EINTR, .EAGAIN:
                continue
            }
            return
        }
        rest = rest[n:]
    }
}

@(private = "file")
apply_raw_mode :: proc "contextless" () -> bool {
    raw := orig_termios
    // No break -> SIGINT, no CR/NL translation, no XON/XOFF, no 8th bit stripping.
    raw.c_iflag -= {.IGNBRK, .BRKINT, .PARMRK, .ISTRIP, .INLCR, .IGNCR, .ICRNL, .IXON}
    // Keep output processing so a stray "\n" still moves to column 0.
    raw.c_oflag += {.OPOST, .ONLCR}
    // No echo, no line buffering, no signal characters (Ctrl-C/Z arrive as bytes).
    raw.c_lflag -= {.ECHO, .ECHONL, .ICANON, .ISIG, .IEXTEN}
    raw.c_cflag -= {.PARENB}
    raw.c_cflag += {.CS8}
    // Blocking reads returning as soon as one byte is available; timeouts are
    // done with poll(2) by the events package.
    raw.c_cc[.VMIN] = 1
    raw.c_cc[.VTIME] = 0
    return psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &raw) == .OK
}

@(private = "file")
install_hooks :: proc() {
    if hooks_installed {
        return
    }
    hooks_installed = true

    psx.atexit(shutdown)

    // Anything that kills the process must leave the terminal usable.
    set_handler(.SIGINT, fatal_signal_handler)
    set_handler(.SIGTERM, fatal_signal_handler)
    set_handler(.SIGHUP, fatal_signal_handler)
    set_handler(.SIGQUIT, fatal_signal_handler)
    set_handler(.SIGABRT, fatal_signal_handler)
    set_handler(.SIGSEGV, fatal_signal_handler)
    set_handler(.SIGBUS, fatal_signal_handler)
    set_handler(.SIGILL, fatal_signal_handler)
    set_handler(.SIGFPE, fatal_signal_handler)
    set_handler(.SIGTRAP, fatal_signal_handler)

    // Job control.
    set_handler(.SIGTSTP, tstp_signal_handler)
    set_handler(.SIGCONT, cont_signal_handler)
}

@(private = "file")
set_handler :: proc "contextless" (sig: psx.Signal, handler: proc "c" (psx.Signal)) {
    act: psx.sigaction_t
    act.sa_handler = handler
    psx.sigemptyset(&act.sa_mask)
    act.sa_flags = {}
    psx.sigaction(sig, &act, nil)
}

@(private = "file")
reset_handler :: proc "contextless" (sig: psx.Signal) {
    act: psx.sigaction_t
    act.sa_handler = cast(proc "c" (psx.Signal))psx.SIG_DFL
    psx.sigemptyset(&act.sa_mask)
    act.sa_flags = {}
    psx.sigaction(sig, &act, nil)
}

@(private = "file")
fatal_signal_handler :: proc "c" (sig: psx.Signal) {
    shutdown()
    reset_handler(sig)
    psx.raise(sig)
}

@(private = "file")
tstp_signal_handler :: proc "c" (sig: psx.Signal) {
    if state == .Active {
        _leave_modes()
        state = .Suspended
    }
    // Let the default action stop the process.
    reset_handler(.SIGTSTP)
    psx.raise(.SIGTSTP)
}

@(private = "file")
cont_signal_handler :: proc "c" (_: psx.Signal) {
    // Re-arm: the TSTP handler resets itself to the default action.
    set_handler(.SIGTSTP, tstp_signal_handler)
    if state == .Suspended {
        resume()
    }
}

@(private = "file")
resume :: proc "contextless" () {
    apply_raw_mode()
    _write(enter_seq())
    state = .Active
    // The screen was replaced by the shell while we were stopped; tell the
    // application to redraw through the same path it uses for resizes.
    psx.raise(psx.Signal(psx.SIGWINCH))
}
