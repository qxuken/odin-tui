#+private
package term_sys

import "core:sys/darwin"

@(private = "file")
winsize :: struct {
    ws_row:    u16,
    ws_col:    u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

_get_size :: proc() -> (size: Window_Size, ok: bool) {
    ws: winsize
    if darwin.syscall_ioctl(1, darwin.TIOCGWINSZ, rawptr(&ws)) != 0 {
        // stdout may be redirected; fall back to the controlling terminal.
        fd, open_ok := darwin.sys_open("/dev/tty", {.RDWR}, {})
        if !open_ok {
            return
        }
        defer darwin.syscall_close(fd)
        if darwin.syscall_ioctl(fd, darwin.TIOCGWINSZ, rawptr(&ws)) != 0 {
            return
        }
    }
    return Window_Size{cols = int(ws.ws_col), rows = int(ws.ws_row), xpixel = int(ws.ws_xpixel), ypixel = int(ws.ws_ypixel)}, true
}
