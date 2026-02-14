package term_sys

import "ansi"

import "core:strings"

Window_Size :: struct {
    row:    int,
    col:    int,
    xpixel: int,
    ypixel: int,
}

set_utf8_terminal :: proc() {
    _set_utf8_terminal()
}

enable_raw_mode :: proc() {
    _enable_raw_mode()
}

hook_restore_terminal :: proc "c" () {
    _hook_restore_terminal()
}

restore_terminal :: proc "c" () {
    _restore_terminal()
}

get_size :: proc() -> Maybe(Window_Size) {
    return _get_size()
}

enable_mouse_capture :: proc(out: ^strings.Builder) {
    _enable_mouse_capture()

    strings.write_string(out, ansi.CSI_MOUSE_TRACKING_UP)
    strings.write_string(out, ansi.CSI_MOUSE_DRAGING_UP)
    strings.write_string(out, ansi.CSI_MOUSE_ALL_MOTION_TRACKING_UP)
    strings.write_string(out, ansi.CSI_MOUSE_EXTENDING_MODE_UP)
    strings.write_string(out, ansi.CSI_MOUSE_EXTENDING_MODE_UP)
}

enter_alternate_mode :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_ALTERNATE_MODE_UP)
}

exit_alternate_mode :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_ALTERNATE_MODE_DOWN)
}

show_cursor :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_SHOW_CURSOR)
}

hide_cursor :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_HIDE_CURSOR)
}

clear_screen :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_CLEAR_SCREEN)
    strings.write_string(out, ansi.CSI_CURSOR_MOVE_HOME)
}

start_sync_update :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_SYNC_UPDATE_UP)
}

end_sync_update :: proc(out: ^strings.Builder) {
    strings.write_string(out, ansi.CSI_SYNC_UPDATE_DOWN)
}
