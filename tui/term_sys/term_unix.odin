#+build netbsd, openbsd, freebsd, haiku
#+private
package term_sys

import "core:sys/unix"

winsize :: struct {
    ws_row:    u16,
    ws_col:    u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

TIOCGWINSZ :: 0x40087468

_get_size :: proc() -> Maybe(Window_Size) {
    // https://rosettacode.org/wiki/Terminal_control/Dimensions#Library:_BSD_libc
    fd, ok := unix.sys_open("/dev/tty", {.RDWR}, {})
    if !ok {
        return nil
    }
    defer unix.syscall_close(fd)

    ws: winsize
    if unix.syscall_ioctl(fd, TIOCGWINSZ, rawptr(&ws)) != 0 {
        return nil
    }

    return Window_Size{row = cast(int)ws.ws_row, col = cast(int)ws.ws_col, xpixel = cast(int)ws.ws_xpixel, ypixel = cast(int)ws.ws_ypixel}
}
