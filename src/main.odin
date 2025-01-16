package main

import "core:fmt"
import "core:io"
import "core:os"
import "core:sys/windows"
import "core:time"
import "core:unicode/utf8"

main :: proc() {
	set_utf8_terminal()
	enable_raw_mode()
	defer disable_raw_mode()

	size := get_size()

	clear_screen()
	fmt.print("Enter something:")
	input := get_input()
	defer delete(input)

	hide_cursor()
	defer show_cursor()

	clear_screen()
	fmt.print("You typed", input)
	time.sleep(1.667e+7 * 30)

	for percent in 0 ..= 100 {
		clear_screen()
		draw_progress_bar("Uploading result", percent, size.width)
		time.sleep(1.667e+7)
	}

	fmt.print("\nPress ENTER to exit...")
	get_input()
}

get_input :: proc(allocator := context.allocator) -> string {
	buf := make([dynamic]byte, allocator)
	in_stream := os.stream_from_handle(os.stdin)

	for {
		// Read a single character at a time.
		ch, sz, err := io.read_rune(in_stream)
		fmt.eprintln(ch, sz, err)
		switch {
		case err != nil:
			fmt.eprintfln("\nError: %v", err)
			os.exit(1)

		case ch == '\n':
			return string(buf[:])

		case ch == '\u007f':
			// Backspace.
			_, bs_sz := utf8.decode_last_rune(buf[:])
			if bs_sz > 0 {
				resize(&buf, len(buf) - bs_sz)
				// Replace last star with a space.
				fmt.print("\b \b")
			}
		case:
			bytes, _ := utf8.encode_rune(ch)
			append(&buf, ..bytes[:sz])

			fmt.print('*')
		}
	}
}

draw_progress_bar :: proc(title: string, percent: int, width := 25) {
	fmt.printf("%v %d%%\n", title, percent, flush = false) // Put cursor back at the start of the line

	if percent == 0 {
		fmt.print(rune(0xEE00), flush = false)
	} else {
		fmt.print(rune(0xEE03), flush = false)
	}

	dynamic_width := width - 2
	done := percent * dynamic_width / 100
	left := dynamic_width - done
	for _ in 0 ..< done {
		fmt.print(rune(0xEE04), flush = false)
	}
	for _ in 0 ..< left {
		fmt.print(rune(0xEE01), flush = false)
	}
	if percent == 100 {
		fmt.print(rune(0xEE05))
	} else {
		fmt.print(rune(0xEE02))
	}
}
