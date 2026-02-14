#+private
package term_sys

import "core:sys/darwin"

winsize :: struct {
    ws_row:    u16,
    ws_col:    u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

_get_size :: proc() -> Maybe(Window_Size) {
    // https://rosettacode.org/wiki/Terminal_control/Dimensions#Library:_BSD_libc
    fd, ok := darwin.sys_open("/dev/tty", {.RDWR}, {})
    if !ok {
        return nil
    }
    defer darwin.syscall_close(fd)

    ws: winsize
    if darwin.syscall_ioctl(fd, darwin.TIOCGWINSZ, rawptr(&ws)) != 0 {
        return nil
    }

    return Window_Size{row = cast(int)ws.ws_row, col = cast(int)ws.ws_col, xpixel = cast(int)ws.ws_xpixel, ypixel = cast(int)ws.ws_ypixel}
}
