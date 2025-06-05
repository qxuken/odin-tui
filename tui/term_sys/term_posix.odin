#+build darwin, linux
package term_sys

import "core:c/libc"
import "core:fmt"
import psx "core:sys/posix"

@(private = "file")
orig_mode: psx.termios

_set_utf8_terminal :: proc() {}

_enable_raw_mode :: proc() {
    res := psx.tcgetattr(psx.STDIN_FILENO, &orig_mode)
    ensure(res == .OK)

    psx.atexit(restore_terminal)
    psx.signal(.SIGINT, proc "c" (_: psx.Signal) {_restore_terminal()})

    raw := orig_mode
    raw.c_iflag -= {.IGNBRK, .BRKINT, .PARMRK, .ISTRIP, .INLCR, .IGNCR, .ICRNL, .IXON}
    raw.c_oflag += {.OPOST, .ONLCR}
    raw.c_lflag -= {.ECHO, .ECHONL, .ICANON, .ISIG, .IEXTEN}
    raw.c_cflag -= {.PARENB}
    raw.c_cflag += {.CS8}
    raw.c_cc[.VMIN] = 0
    raw.c_cc[.VTIME] = 1
    res = psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &raw)
    ensure(res == .OK)
}

_enable_mouse_capture :: proc() {}

_restore_terminal :: proc "c" () {
    psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &orig_mode)
}
