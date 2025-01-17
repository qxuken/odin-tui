package term

import "core:fmt"

Window_Size :: struct {
	width:  u16,
	height: u16,
}

enable_raw_mode :: proc() {
	_enable_raw_mode()

	// enter alternate mode
	// fmt.print("\033[?1049h")
}

disable_raw_mode :: proc "c" () {
	_disable_raw_mode()

	// exit alternate mode
	// fmt.print("\033[?1049l")
}

set_utf8_terminal :: proc() {
	_set_utf8_terminal()
}

get_size :: proc() -> Window_Size {
	return _get_size()
}

clear_screen :: proc() {
	fmt.print("\033[H", flush = false) // move to home (row=1, col=1)
	fmt.print("\033[2J") // clear screen
}

hide_cursor :: proc() {
	fmt.print("\033[?25l")
}

show_cursor :: proc() {
	fmt.print("\033[?25h")
}
