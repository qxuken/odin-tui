#+build darwin, linux, freebsd, openbsd, netbsd
package main

import psx "core:sys/posix"

@(private = "file")
orig_mode: psx.termios

@(private = "file")
TIOCSWINSZ :: 21524

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
	// TODO: implement for posix
	// https://rosettacode.org/wiki/Terminal_control/Dimensions#Library:_BSD_libc

	// https://github.com/crossterm-rs/crossterm/blob/e104a7cb400910609cdde36f322e3905c4baa805/src/terminal/sys/unix.rs#L85
	// https://github.com/bytecodealliance/rustix/blob/472196d897b463ea40a5245b3920ca4e7c361d1b/src/backend/linux_raw/termios/syscalls.rs#L24

	// TIOCSWINSZ
	unimplemented()
}
