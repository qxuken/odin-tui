#+build darwin, linux
package term

import "core:c/libc"
import "core:fmt"
import psx "core:sys/posix"

@(private = "file")
orig_mode: psx.termios

_set_utf8_terminal :: proc() {}

_enable_raw_mode :: proc() {
	res := psx.tcgetattr(psx.STDIN_FILENO, &orig_mode)
	assert(res == .OK)

	psx.atexit(restore_terminal)
	psx.signal(.SIGINT, proc "c" (_: psx.Signal) {_restore_terminal()})

	raw := orig_mode
	raw.c_iflag -= {.IGNBRK, .BRKINT, .PARMRK, .ISTRIP, .INLCR, .IGNCR, .ICRNL, .IXON}
	raw.c_oflag += {.OPOST, .ONLCR}
	raw.c_lflag -= {.ECHO, .ECHONL, .ICANON, .ISIG, .IEXTEN}
	raw.c_cflag -= {.PARENB}
	raw.c_cflag += {.CS8}
	raw.c_cc[.VMIN] = 0
	raw.c_cc[.VTIME] = 1
	res = psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &raw)
	assert(res == .OK)
}

_enable_mouse_capture :: proc() {
	// Also enable basic mouse tracking if needed
	fmt.print("\x1B[?1000h", flush = false)
	// Enable draging event
	fmt.print("\x1B[?1002h", flush = false)
	// Enable all-motion tracking
	fmt.print("\x1B[?1003h", flush = false)
	// Enable SGR extended mouse mode (for better coordinates, etc.)
	fmt.print("\x1B[?1006h", flush = false)
	// Enable URxvt extended mouse mode >223
	fmt.print("\x1B[?1015h", flush = false)
	fmt.print()
}

_restore_terminal :: proc "c" () {
	psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &orig_mode)
}
