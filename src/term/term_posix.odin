#+build darwin, linux
package term

import "core:c/libc"
import "core:fmt"
import psx "core:sys/posix"

@(private = "file")
orig_mode: psx.termios

_set_utf8_terminal :: proc() {}

_enable_raw_mode :: proc() {
	// Get the original terminal attributes.
	res := psx.tcgetattr(psx.STDIN_FILENO, &orig_mode)
	assert(res == .OK)

	// Reset to the original attributes at the end of the program.
	psx.atexit(restore_terminal)

	// Copy, and remove the
	// ECHO (so what is typed is not shown) and
	// ICANON (so we get each input instead of an entire line at once) flags.
	raw := orig_mode
	raw.c_iflag -= {.BRKINT, .ICRNL, .INPCK, .ISTRIP, .IXON}
	raw.c_oflag -= {.OPOST}
	raw.c_lflag -= {.ECHO, .ICANON, .ISIG, .IEXTEN}
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

	/* Re-enable normal mouse reporting off (if we want a clean state) */
	libc.printf("\x1B[?1003l") // disable all-motion tracking
	libc.printf("\x1B[?1006l") // disable SGR (extended) mouse mode
	libc.printf("\x1B[?1015l") // disable urxvt mouse mode
	libc.printf("\x1B[?1000l") // disable basic mouse tracking
	libc.fflush(libc.stdout)
}
