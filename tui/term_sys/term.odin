package term_sys

import "core:fmt"
import "core:strings"
import "core:terminal/ansi"

Window_Size :: struct {
    width:  int,
    height: int,
}

set_utf8_terminal :: proc() {
    _set_utf8_terminal()
}

enable_raw_mode :: proc() {
    _enable_raw_mode()
}

enable_mouse_capture :: proc() {
    _enable_mouse_capture()

    fmt.print(CSI_MOUSE_TRACKING_UP, flush = false)
    fmt.print(CSI_MOUSE_DRAGING_UP, flush = false)
    fmt.print(CSI_MOUSE_ALL_MOTION_TRACKING_UP, flush = false)
    fmt.print(CSI_MOUSE_EXTENDING_MODE_UP, flush = false)
    fmt.print(CSI_MOUSE_EXTENDING_MODE_UP, flush = false)
    fmt.print()
}

enter_alternate_mode :: proc() {
    fmt.print(CSI_ALTERNATE_MODE_UP)
}

exit_alternate_mode :: proc() {
    fmt.print(CSI_ALTERNATE_MODE_DOWN)
}

show_cursor :: proc() {
    fmt.print(CSI_SHOW_CURSOR)
}

hide_cursor :: proc() {
    fmt.print(CSI_HIDE_CURSOR)
}

restore_terminal :: proc "c" () {
    _restore_terminal()
}

get_size :: proc() -> Window_Size {
    return _get_size()
}

clear_screen :: proc(out: ^strings.Builder) {
    strings.write_string(out, CSI_CLEAR_SCREEN)
    strings.write_string(out, CSI_CURSOR_MOVE_HOME)
}

start_sync_update :: proc(out: ^strings.Builder) {
    strings.write_string(out, CSI_SYNC_UPDATE_UP)
}

end_sync_update :: proc(out: ^strings.Builder) {
    strings.write_string(out, CSI_SYNC_UPDATE_DOWN)
}
