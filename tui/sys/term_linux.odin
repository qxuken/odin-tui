package term

import "core:sys/linux"

@(private = "file")
winsize :: struct {
	ws_row:    u16,
	ws_col:    u16,
	ws_xpixel: u16,
	ws_ypixel: u16,
}

@(private = "file")
TIOCGWINSZ :: 0x5413

_get_size :: proc() -> Window_Size {
	// https://rosettacode.org/wiki/Terminal_control/Dimensions#Library:_BSD_libc
	ws := new(winsize)
	defer free(ws)

	ret := linux.ioctl(linux.STDIN_FILENO, TIOCGWINSZ, uintptr(ws))
	assert(ret == 0, "ioctl return code non zero")

	return {cast(int)ws.ws_col, cast(int)ws.ws_row}
}
