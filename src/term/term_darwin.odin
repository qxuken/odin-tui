package term

import "base:intrinsics"
import "core:c"
import "core:fmt"
import "core:sys/darwin"

@(private = "file")
winsize :: struct {
	ws_row:    u16,
	ws_col:    u16,
	ws_xpixel: u16,
	ws_ypixel: u16,
}

@(private = "file")
TIOCGWINSZ :: 0x40087468

@(private = "file")
syscall_ioctl :: #force_inline proc "contextless" (
	fd: c.int,
	request: u32,
	arg: uintptr,
) -> c.int {
	return(
		cast(c.int)intrinsics.syscall(
			darwin.unix_offset_syscall(.ioctl),
			uintptr(fd),
			uintptr(request),
			arg,
		) \
	)
}

_get_size :: proc() -> Window_Size {
	// https://rosettacode.org/wiki/Terminal_control/Dimensions#Library:_BSD_libc
	fd, ok := darwin.sys_open("/dev/tty", {.RDWR}, {})
	assert(ok == true)
	defer darwin.syscall_close(fd)

	ws := new(winsize)
	defer free(ws)

	ret := syscall_ioctl(fd, TIOCGWINSZ, uintptr(ws))
	assert(ret == 0, "syscall_ioctl return code non zero")

	return {ws.ws_col, ws.ws_row}
}
