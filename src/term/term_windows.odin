package term

import "core:c/libc"
import "core:sys/windows"

@(private = "file")
orig_mode: windows.DWORD

_enable_raw_mode :: proc() {
	// Get a handle to the standard input.
	stdin := windows.GetStdHandle(windows.STD_INPUT_HANDLE)
	assert(stdin != windows.INVALID_HANDLE_VALUE)

	// Get the original terminal mode.
	ok := windows.GetConsoleMode(stdin, &orig_mode)
	assert(ok == true)

	// Reset to the original attributes at the end of the program.
	libc.atexit(disable_raw_mode)

	// Copy, and remove the
	// ENABLE_ECHO_INPUT (so what is typed is not shown) and
	// ENABLE_LINE_INPUT (so we get each input instead of an entire line at once) flags.
	raw := orig_mode
	raw &= ~windows.ENABLE_ECHO_INPUT
	raw &= ~windows.ENABLE_LINE_INPUT
	ok = windows.SetConsoleMode(stdin, raw)
	assert(ok == true)
}

_disable_raw_mode :: proc "c" () {
	stdin := windows.GetStdHandle(windows.STD_INPUT_HANDLE)
	assert_contextless(stdin != windows.INVALID_HANDLE_VALUE)

	windows.SetConsoleMode(stdin, orig_mode)
}

_set_utf8_terminal :: proc() {
	windows.SetConsoleOutputCP(.UTF8)
	windows.SetConsoleCP(.UTF8)
}

_get_size :: proc() -> Window_Size {
	// Get a handle to the standard output.
	stdout := windows.GetStdHandle(windows.STD_OUTPUT_HANDLE)
	assert(stdout != windows.INVALID_HANDLE_VALUE)

	ci: windows.CONSOLE_SCREEN_BUFFER_INFO
	ok := windows.GetConsoleScreenBufferInfo(stdout, &ci)
	assert(ok == true, "GetConsoleScreenBufferInfo != ok")

	return {ci.srWindow.Right - ci.srWindow.Left + 1, ci.srWindow.Top - ci.srWindow.Bottom + 1}
}
