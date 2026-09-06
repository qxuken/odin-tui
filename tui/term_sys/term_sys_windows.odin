#+private
package term_sys

import "core:c/libc"
import "core:sys/windows"

@(private = "file")
ENABLE_EXTENDED_FLAGS: windows.DWORD : 0x0080

@(private = "file")
orig_in_mode: windows.DWORD
@(private = "file")
orig_out_mode: windows.DWORD
@(private = "file")
orig_in_cp: windows.CODEPAGE
@(private = "file")
orig_out_cp: windows.CODEPAGE
@(private = "file")
hooks_installed: bool

@(private = "file")
in_handle :: #force_inline proc "contextless" () -> windows.HANDLE {
    return windows.GetStdHandle(windows.STD_INPUT_HANDLE)
}

@(private = "file")
out_handle :: #force_inline proc "contextless" () -> windows.HANDLE {
    return windows.GetStdHandle(windows.STD_OUTPUT_HANDLE)
}

_init :: proc() -> Error {
    hin, hout := in_handle(), out_handle()
    if hin == windows.INVALID_HANDLE_VALUE || hout == windows.INVALID_HANDLE_VALUE {
        return .Not_A_Terminal
    }
    if !windows.GetConsoleMode(hin, &orig_in_mode) || !windows.GetConsoleMode(hout, &orig_out_mode) {
        return .Not_A_Terminal
    }
    orig_in_cp = windows.GetConsoleCP()
    orig_out_cp = windows.GetConsoleOutputCP()
    windows.SetConsoleCP(.UTF8)
    windows.SetConsoleOutputCP(.UTF8)

    if !apply_modes() {
        return .Set_Mode_Failed
    }
    install_hooks()
    _write(enter_seq())
    return .None
}

_leave_modes :: proc "contextless" () {
    _write(leave_seq())
    windows.SetConsoleMode(in_handle(), orig_in_mode)
    windows.SetConsoleMode(out_handle(), orig_out_mode)
    windows.SetConsoleCP(orig_in_cp)
    windows.SetConsoleOutputCP(orig_out_cp)
}

_suspend :: proc() {}

_write :: proc "contextless" (data: []u8) {
    h := out_handle()
    rest := data
    for len(rest) > 0 {
        written: windows.DWORD
        if !windows.WriteFile(h, raw_data(rest), windows.DWORD(len(rest)), &written, nil) {
            return
        }
        rest = rest[written:]
    }
}

_get_size :: proc() -> (size: Window_Size, ok: bool) {
    ci: windows.CONSOLE_SCREEN_BUFFER_INFO
    if !windows.GetConsoleScreenBufferInfo(out_handle(), &ci) {
        return
    }
    // The visible window, not the (scrollback) buffer.
    return Window_Size{cols = int(ci.srWindow.Right - ci.srWindow.Left) + 1, rows = int(ci.srWindow.Bottom - ci.srWindow.Top) + 1}, true
}

@(private = "file")
apply_modes :: proc "contextless" () -> bool {
    // Raw-ish input: no line buffering, no echo, Ctrl-C delivered as a key.
    // ENABLE_EXTENDED_FLAGS without ENABLE_QUICK_EDIT_MODE turns quick edit
    // off, which otherwise swallows mouse events.
    in_mode := ENABLE_EXTENDED_FLAGS | windows.ENABLE_WINDOW_INPUT
    if options.mouse {
        in_mode |= windows.ENABLE_MOUSE_INPUT
    }
    if !windows.SetConsoleMode(in_handle(), in_mode) {
        return false
    }
    // Let the console interpret the escape sequences we write.
    out_mode := orig_out_mode | windows.ENABLE_VIRTUAL_TERMINAL_PROCESSING
    return bool(windows.SetConsoleMode(out_handle(), out_mode))
}

@(private = "file")
install_hooks :: proc() {
    if hooks_installed {
        return
    }
    hooks_installed = true
    libc.atexit(shutdown)
    windows.SetConsoleCtrlHandler(ctrl_handler, true)
}

@(private = "file")
ctrl_handler :: proc "system" (ctrl_type: windows.DWORD) -> windows.BOOL {
    shutdown()
    return false
}
