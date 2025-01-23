package term

import "core:fmt"
import "core:strings"

Window_Size :: struct {
    width:  int,
    height: int,
}

csi :: "\x1B["

set_utf8_terminal :: proc() {
    _set_utf8_terminal()
}

enable_raw_mode :: proc() {
    _enable_raw_mode()
}

enable_mouse_capture :: proc() {
    _enable_mouse_capture()

    // Also enable basic mouse tracking if needed
    fmt.print(csi + "?1000h", flush = false)
    // Enable draging event
    fmt.print(csi + "?1002h", flush = false)
    // Enable all-motion tracking
    fmt.print(csi + "?1003h", flush = false)
    // Enable SGR extended mouse mode (for better coordinates, etc.)
    fmt.print(csi + "?1006h", flush = false)
    // Enable URxvt extended mouse mode >223
    fmt.print(csi + "?1015h", flush = false)
    fmt.print()
}

enter_alternate_mode :: proc() {
    fmt.print(csi + "?1049h")
}

exit_alternate_mode :: proc() {
    fmt.print(csi + "?1049l")
}

show_cursor :: proc() {
    fmt.print(csi + "?25h")
}

hide_cursor :: proc() {
    fmt.print(csi + "?25l")
}

restore_terminal :: proc "c" () {
    _restore_terminal()
}

get_size :: proc() -> Window_Size {
    return _get_size()
}

clear_screen :: proc(out: ^strings.Builder) {
    strings.write_string(out, csi + "2J") // clear screen
    strings.write_string(out, csi + "H") // move to home (row=1, col=1)
}
