#+private
package events

import "base:runtime"
import "core:sys/windows"
import "core:time"
import "tui:term_sys"

@(private = "file")
in_handle: windows.HANDLE
@(private = "file")
records: [128]windows.INPUT_RECORD
@(private = "file")
held_buttons: windows.DWORD
@(private = "file")
high_surrogate: rune

@(private = "file")
MOUSE_MOVED: windows.DWORD : 0x0001
@(private = "file")
DOUBLE_CLICK: windows.DWORD : 0x0002
@(private = "file")
MOUSE_WHEELED: windows.DWORD : 0x0004
@(private = "file")
MOUSE_HWHEELED: windows.DWORD : 0x0008

@(private = "file")
RIGHT_ALT_PRESSED: windows.DWORD : 0x0001
@(private = "file")
LEFT_ALT_PRESSED: windows.DWORD : 0x0002
@(private = "file")
RIGHT_CTRL_PRESSED: windows.DWORD : 0x0004
@(private = "file")
LEFT_CTRL_PRESSED: windows.DWORD : 0x0008
@(private = "file")
SHIFT_PRESSED: windows.DWORD : 0x0010

_init :: proc() -> bool {
    in_handle = windows.GetStdHandle(windows.STD_INPUT_HANDLE)
    return in_handle != windows.INVALID_HANDLE_VALUE
}

_destroy :: proc() {}

_poll :: proc(timeout: time.Duration, allocator: runtime.Allocator) -> []Event {
    out := make([dynamic]Event, allocator)
    start := time.tick_now()
    for {
        ms := windows.INFINITE
        if timeout >= 0 {
            remaining := max(timeout - time.tick_since(start), 0)
            whole := (remaining + time.Millisecond - 1) / time.Millisecond
            ms = windows.DWORD(min(whole, time.Duration(max(i32))))
        }
        if windows.WaitForSingleObject(in_handle, ms) != windows.WAIT_OBJECT_0 {
            return out[:]
        }

        n: windows.DWORD
        if !windows.ReadConsoleInputW(in_handle, &records[0], len(records), &n) {
            return out[:]
        }
        for rec in records[:n] {
            translate(rec, &out)
        }
        if len(out) > 0 {
            return out[:]
        }
        if timeout >= 0 && time.tick_since(start) >= timeout {
            return out[:]
        }
    }
}

@(private = "file")
translate :: proc(rec: windows.INPUT_RECORD, out: ^[dynamic]Event) {
    #partial switch rec.EventType {
    case .KEY_EVENT:
        translate_key(rec.Event.KeyEvent, out)
    case .MOUSE_EVENT:
        translate_mouse(rec.Event.MouseEvent, out)
    case .WINDOW_BUFFER_SIZE_EVENT:
        size, _ := term_sys.get_size()
        append(out, Resize{cols = size.cols, rows = size.rows})
    case .FOCUS_EVENT:
        append(out, Focus{gained = bool(rec.Event.FocusEvent.bSetFocus)})
    }
}

@(private = "file")
modifiers :: proc(state: windows.DWORD) -> (mods: Modifiers) {
    if state & SHIFT_PRESSED != 0 {
        mods += {.Shift}
    }
    if state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED) != 0 {
        mods += {.Ctrl}
    }
    if state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED) != 0 {
        mods += {.Alt}
    }
    return
}

@(private = "file")
translate_key :: proc(k: windows.KEY_EVENT_RECORD, out: ^[dynamic]Event) {
    if !k.bKeyDown {
        return
    }
    key := Key{mods = modifiers(transmute(windows.DWORD)k.dwControlKeyState)}

    switch k.wVirtualKeyCode {
    case windows.VK_RETURN:
        key.code = .Enter
    case windows.VK_TAB:
        key.code = .Tab
    case windows.VK_BACK:
        key.code = .Backspace
    case windows.VK_ESCAPE:
        key.code = .Escape
    case windows.VK_UP:
        key.code = .Up
    case windows.VK_DOWN:
        key.code = .Down
    case windows.VK_LEFT:
        key.code = .Left
    case windows.VK_RIGHT:
        key.code = .Right
    case windows.VK_HOME:
        key.code = .Home
    case windows.VK_END:
        key.code = .End
    case windows.VK_PRIOR:
        key.code = .Page_Up
    case windows.VK_NEXT:
        key.code = .Page_Down
    case windows.VK_INSERT:
        key.code = .Insert
    case windows.VK_DELETE:
        key.code = .Delete
    case windows.VK_F1 ..= windows.VK_F12:
        key.code = Key_Code(int(Key_Code.F1) + int(k.wVirtualKeyCode - windows.VK_F1))
    case:
        ch := rune(k.uChar.UnicodeChar)
        if ch == 0 {
            return // modifier key on its own
        }
        if ch >= 0xD800 && ch < 0xDC00 {
            high_surrogate = ch
            return
        }
        if ch >= 0xDC00 && ch < 0xE000 && high_surrogate != 0 {
            ch = 0x10000 + ((high_surrogate - 0xD800) << 10) + (ch - 0xDC00)
            high_surrogate = 0
        }
        if .Ctrl in key.mods && ch < 0x20 {
            // Ctrl+A arrives as 0x01; report the letter like the VT parser does.
            ch = rune('a' + ch - 1)
        }
        key.code = .Char
        key.char = ch
    }

    for _ in 0 ..< max(int(k.wRepeatCount), 1) {
        append(out, key)
    }
}

@(private = "file")
translate_mouse :: proc(m: windows.MOUSE_EVENT_RECORD, out: ^[dynamic]Event) {
    evt := Mouse {
        col  = int(m.dwMousePosition.X),
        row  = int(m.dwMousePosition.Y),
        mods = modifiers(m.dwControlKeyState),
    }
    buttons := m.dwButtonState & 0xFFFF

    switch {
    case m.dwEventFlags & MOUSE_WHEELED != 0:
        evt.action = .Scroll
        evt.button = .Wheel_Up if i16(m.dwButtonState >> 16) > 0 else .Wheel_Down
    case m.dwEventFlags & MOUSE_HWHEELED != 0:
        evt.action = .Scroll
        evt.button = .Wheel_Right if i16(m.dwButtonState >> 16) > 0 else .Wheel_Left
    case m.dwEventFlags & MOUSE_MOVED != 0:
        evt.action = .Move if buttons == 0 else .Drag
        evt.button = button_of(buttons)
    case:
        // Press or release: compare with the previously held buttons.
        pressed := buttons & ~held_buttons
        released := held_buttons & ~buttons
        held_buttons = buttons
        switch {
        case pressed != 0:
            evt.action = .Press
            evt.button = button_of(pressed)
        case released != 0:
            evt.action = .Release
            evt.button = button_of(released)
        case:
            return
        }
    }
    append(out, evt)
}

@(private = "file")
button_of :: proc(buttons: windows.DWORD) -> Mouse_Button {
    switch {
    case buttons & 0x1 != 0:
        return .Left
    case buttons & 0x2 != 0:
        return .Right
    case buttons & 0x4 != 0:
        return .Middle
    }
    return .None
}
