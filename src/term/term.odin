package term

import "core:fmt"

Window_Size :: struct {
	width:  u16,
	height: u16,
}

set_utf8_terminal :: proc() {
	_set_utf8_terminal()
}

enable_raw_mode :: proc() {
	// enter alternate mode
	// fmt.print("\033[?1049h")
	_enable_raw_mode()
}

enable_mouse_capture :: proc() {
	_enable_mouse_capture()
}

show_cursor :: proc() {
	fmt.print("\033[?25h")
}

hide_cursor :: proc() {
	fmt.print("\033[?25l")
}

restore_terminal :: proc "c" () {
	// exit alternate mode
	// fmt.print("\033[?1049l")
	_restore_terminal()
}

get_size :: proc() -> Window_Size {
	return _get_size()
}

clear_screen :: proc() {
	fmt.print("\033[H", flush = false) // move to home (row=1, col=1)
	fmt.print("\033[2J") // clear screen
}
