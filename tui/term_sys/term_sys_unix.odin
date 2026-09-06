#+build netbsd, openbsd, freebsd
#+private
package term_sys

import "core:c"
import psx "core:sys/posix"

// `core:sys/unix` exposes no ioctl for the BSDs, so bind libc's directly.
foreign import libc "system:c"
foreign libc {
    ioctl :: proc(fd: psx.FD, request: c.ulong, #c_vararg args: ..any) -> c.int ---
}

@(private = "file")
winsize :: struct {
    ws_row:    u16,
    ws_col:    u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

// _IOR('t', 104, struct winsize); the same value on every BSD.
@(private = "file")
TIOCGWINSZ :: c.ulong(0x40087468)

_get_size :: proc() -> (size: Window_Size, ok: bool) {
    ws: winsize
    if ioctl(psx.STDOUT_FILENO, TIOCGWINSZ, &ws) != 0 {
        // stdout may be redirected; fall back to the controlling terminal.
        fd := psx.open("/dev/tty", {})
        if fd < 0 {
            return
        }
        defer psx.close(fd)
        if ioctl(fd, TIOCGWINSZ, &ws) != 0 {
            return
        }
    }
    return Window_Size{cols = int(ws.ws_col), rows = int(ws.ws_row), xpixel = int(ws.ws_xpixel), ypixel = int(ws.ws_ypixel)}, true
}
