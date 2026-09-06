#+private
package term_sys

import "core:sys/linux"

@(private = "file")
winsize :: struct {
    ws_row:    u16,
    ws_col:    u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

_get_size :: proc() -> (size: Window_Size, ok: bool) {
    ws: winsize
    if linux.ioctl(linux.STDOUT_FILENO, linux.TIOCGWINSZ, uintptr(&ws)) != 0 {
        if linux.ioctl(linux.STDIN_FILENO, linux.TIOCGWINSZ, uintptr(&ws)) != 0 {
            return
        }
    }
    return Window_Size{cols = int(ws.ws_col), rows = int(ws.ws_row), xpixel = int(ws.ws_xpixel), ypixel = int(ws.ws_ypixel)}, true
}
