package term

import "core:fmt"
import "core:io"

Window_Size :: struct {
	width:  u16,
	height: u16,
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

clear_screen :: proc(s: io.Stream) {
	io.write_string(s, csi + "H") // move to home (row=1, col=1)
	io.write_string(s, csi + "2J") // clear screen
}
