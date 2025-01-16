#+build darwin, linux, freebsd, openbsd, netbsd
package main

import "core:sys/linux"
import psx "core:sys/posix"

@(private = "file")
orig_mode: psx.termios

@(private = "file")
winsize :: struct {
	ws_row:    u16,
	ws_col:    u16,
	ws_xpixel: u16,
	ws_ypixel: u16,
}

@(private = "file")
TIOCGWINSZ :: 0x5413

_enable_raw_mode :: proc() {
	// Get the original terminal attributes.
	res := psx.tcgetattr(psx.STDIN_FILENO, &orig_mode)
	assert(res == .OK)

	// Reset to the original attributes at the end of the program.
	psx.atexit(disable_raw_mode)

	// Copy, and remove the
	// ECHO (so what is typed is not shown) and
	// ICANON (so we get each input instead of an entire line at once) flags.
	raw := orig_mode
	raw.c_lflag -= {.ECHO, .ICANON}
	res = psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &raw)
	assert(res == .OK)
}

_disable_raw_mode :: proc "c" () {
	psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &orig_mode)
}

_set_utf8_terminal :: proc() {}

_get_size :: proc() -> Window_Size {
	// https://rosettacode.org/wiki/Terminal_control/Dimensions#Library:_BSD_libc
	// fd, err := linux.open("/dev/tty", {.RDWR})
	// assert(err == nil)
	// defer linux.close(fd)

	ws := new(winsize)
	defer free(ws)

	ret := linux.ioctl(linux.STDIN_FILENO, TIOCGWINSZ, uintptr(ws))

	return {ws.ws_col, ws.ws_row}
}
