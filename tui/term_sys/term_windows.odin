package term_sys

import "core:c/libc"
import "core:fmt"
import "core:sys/windows"

@(private = "file")
orig_mode := max(u32)

@(private = "file")
ENABLE_EXTENDED_FLAGS: windows.DWORD : 0x0080

_set_utf8_terminal :: proc() {
    windows.SetConsoleOutputCP(.UTF8)
    windows.SetConsoleCP(.UTF8)
}

_enable_raw_mode :: proc() {
    if orig_mode == max(u32) {
        return
    }

    // Get a handle to the standard input.
    stdin := windows.GetStdHandle(windows.STD_INPUT_HANDLE)
    ensure(stdin != windows.INVALID_HANDLE_VALUE)

    // Get the original terminal mode.
    ok := windows.GetConsoleMode(stdin, &orig_mode)
    ensure(ok == true)

    raw := orig_mode
    raw &= ~windows.ENABLE_ECHO_INPUT
    raw &= ~windows.ENABLE_LINE_INPUT
    ok = windows.SetConsoleMode(stdin, raw)
    ensure(ok == true)

}

_enable_mouse_capture :: proc() {
    // Get a handle to the standard input.
    stdin := windows.GetStdHandle(windows.STD_INPUT_HANDLE)
    ensure(stdin != windows.INVALID_HANDLE_VALUE)

    if orig_mode != max(u32) {
        ok := windows.GetConsoleMode(stdin, &orig_mode)
        ensure(ok == true)
    }

    mode := windows.ENABLE_MOUSE_INPUT
    mode |= windows.ENABLE_WINDOW_INPUT
    mode |= ENABLE_EXTENDED_FLAGS
    ok := windows.SetConsoleMode(stdin, mode)
    ensure(ok == true)
}

_hook_restore_terminal :: proc "c" () {
    // Reset to the original attributes at the end of the program.
    libc.atexit(restore_terminal)
}

_restore_terminal :: proc "c" () {
    if orig_mode == max(u32) {
        return
    }

    stdin := windows.GetStdHandle(windows.STD_INPUT_HANDLE)
    assert_contextless(stdin != windows.INVALID_HANDLE_VALUE)

    windows.SetConsoleMode(stdin, orig_mode)
}

_get_size :: proc() -> Window_Size {
    // Get a handle to the standard output.
    stdout := windows.GetStdHandle(windows.STD_OUTPUT_HANDLE)
    ensure(stdout != windows.INVALID_HANDLE_VALUE)

    ci: windows.CONSOLE_SCREEN_BUFFER_INFO
    ok := windows.GetConsoleScreenBufferInfo(stdout, &ci)
    ensure(ok == true, "GetConsoleScreenBufferInfo != ok")

    return {cast(int)(ci.dwSize.X), cast(int)(ci.dwSize.Y)}
}
