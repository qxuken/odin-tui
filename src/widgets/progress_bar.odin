package widgets

import "core:fmt"

draw_progress_bar :: proc(title: string, percent: u16, width: u16 = 25) {
	fmt.printf("%v %d%%\r\n", title, percent, flush = false)

	if percent == 0 {
		fmt.print(rune(0xEE00), flush = false)
	} else {
		fmt.print(rune(0xEE03), flush = false)
	}

	dynamic_width := width - 2
	done := cast(u16)percent * dynamic_width / 100
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
