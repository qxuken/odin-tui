// Decoder for the byte stream a VT/xterm compatible terminal sends in raw mode.
// Pure: no I/O, so it is shared by every platform backend and unit tested.
package events

import "base:runtime"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

ESC :: 0x1B

@(private)
PASTE_END :: "\x1b[201~"

Parser :: struct {
    buf:      [dynamic]u8, // bytes not yet turned into events
    in_paste: bool, // between `CSI 200 ~` and `CSI 201 ~`
}

@(private)
Parse_Status :: enum {
    Ok,
    Need_More, // the buffer ends in the middle of a sequence
    Paste_Begin, // consumed `CSI 200 ~`; caller switches to paste mode
}

// Converts as many complete events as possible from `p.buf` into `out`.
// With `flush` set, a trailing lone ESC becomes the Escape key and trailing
// bytes that can never complete are reported as `Unknown`.
parser_drain :: proc(p: ^Parser, out: ^[dynamic]Event, flush: bool, allocator: runtime.Allocator) {
    b := p.buf[:]
    for len(b) > 0 {
        if p.in_paste {
            end := strings.index(string(b), PASTE_END)
            if end < 0 {
                break
            }
            append(out, Paste{strings.clone(string(b[:end]), allocator)})
            b = b[end + len(PASTE_END):]
            p.in_paste = false
            continue
        }

        evt, n, status := parse_one(b, flush, allocator)
        switch status {
        case .Need_More:
            consumed := len(p.buf) - len(b)
            remove_range(&p.buf, 0, consumed)
            return
        case .Paste_Begin:
            p.in_paste = true
        case .Ok:
            append(out, evt)
        }
        b = b[n:]
    }
    consumed := len(p.buf) - len(b)
    remove_range(&p.buf, 0, consumed)
}

// True when the parser holds bytes that may still turn into a complete
// sequence if more input arrives (used to arm the escape timeout).
parser_has_partial :: proc(p: ^Parser) -> bool {
    return len(p.buf) > 0 && !p.in_paste
}

@(private)
parse_one :: proc(b: []u8, flush: bool, allocator: runtime.Allocator) -> (evt: Event, n: int, status: Parse_Status) {
    c := b[0]
    switch {
    case c == ESC:
        return parse_escape(b, flush, allocator)
    case c < 0x20 || c == 0x7F:
        return parse_control(c), 1, .Ok
    case:
        if !utf8.full_rune(b) {
            if !flush {
                return {}, 0, .Need_More
            }
            return Unknown{strings.clone(string(b), allocator)}, len(b), .Ok
        }
        r, size := utf8.decode_rune(b)
        return Key{code = .Char, char = r}, size, .Ok
    }
}

@(private)
parse_control :: proc(c: u8) -> Key {
    switch c {
    case 0x0D, 0x0A:
        return Key{code = .Enter}
    case 0x09:
        return Key{code = .Tab}
    case 0x7F, 0x08:
        return Key{code = .Backspace}
    case 0x00:
        return Key{code = .Char, char = ' ', mods = {.Ctrl}}
    case 0x1C:
        return Key{code = .Char, char = '\\', mods = {.Ctrl}}
    case 0x1D:
        return Key{code = .Char, char = ']', mods = {.Ctrl}}
    case 0x1E:
        return Key{code = .Char, char = '^', mods = {.Ctrl}}
    case 0x1F:
        return Key{code = .Char, char = '_', mods = {.Ctrl}}
    case:
        return Key{code = .Char, char = rune('a' + c - 1), mods = {.Ctrl}}
    }
}

@(private)
parse_escape :: proc(b: []u8, flush: bool, allocator: runtime.Allocator) -> (evt: Event, n: int, status: Parse_Status) {
    if len(b) == 1 {
        if flush {
            return Key{code = .Escape}, 1, .Ok
        }
        return {}, 0, .Need_More
    }

    switch b[1] {
    case '[':
        return parse_csi(b, flush, allocator)
    case 'O':
        // SS3 sequences (cursor keys in application mode, F1-F4).
        if len(b) < 3 {
            if flush {
                return Key{code = .Char, char = 'O', mods = {.Alt}}, 2, .Ok
            }
            return {}, 0, .Need_More
        }
        if code, ok := ss3_key(b[2]); ok {
            return Key{code = code}, 3, .Ok
        }
        return Key{code = .Char, char = 'O', mods = {.Alt}}, 2, .Ok
    case:
        // ESC followed by a key is that key with Alt held (also `ESC ESC`).
        evt, n, status = parse_one(b[1:], flush, allocator)
        if status != .Ok {
            return evt, 0, status
        }
        if k, ok := evt.(Key); ok {
            k.mods += {.Alt}
            evt = k
        }
        return evt, n + 1, .Ok
    }
}

@(private)
ss3_key :: proc(c: u8) -> (code: Key_Code, ok: bool) {
    switch c {
    case 'A':
        return .Up, true
    case 'B':
        return .Down, true
    case 'C':
        return .Right, true
    case 'D':
        return .Left, true
    case 'H':
        return .Home, true
    case 'F':
        return .End, true
    case 'P':
        return .F1, true
    case 'Q':
        return .F2, true
    case 'R':
        return .F3, true
    case 'S':
        return .F4, true
    }
    return
}

// b starts with `ESC [`.
@(private)
parse_csi :: proc(b: []u8, flush: bool, allocator: runtime.Allocator) -> (evt: Event, n: int, status: Parse_Status) {
    i := 2
    for i < len(b) && b[i] >= 0x30 && b[i] <= 0x3F { // parameter bytes
        i += 1
    }
    for i < len(b) && b[i] >= 0x20 && b[i] <= 0x2F { // intermediate bytes
        i += 1
    }
    if i >= len(b) {
        if flush {
            return Unknown{strings.clone(string(b), allocator)}, len(b), .Ok
        }
        return {}, 0, .Need_More
    }

    final := b[i]
    n = i + 1
    if final < 0x40 || final > 0x7E {
        return Unknown{strings.clone(string(b[:n]), allocator)}, n, .Ok
    }

    params := string(b[2:i])
    evt, status = decode_csi(params, final)
    if status == .Need_More { // decode_csi uses Need_More to say "unrecognised"
        return Unknown{strings.clone(string(b[:n]), allocator)}, n, .Ok
    }
    return evt, n, status
}

@(private)
decode_csi :: proc(params: string, final: u8) -> (evt: Event, status: Parse_Status) {
    if len(params) > 0 && params[0] == '<' && (final == 'M' || final == 'm') {
        if m, ok := decode_sgr_mouse(params[1:], final == 'm'); ok {
            return m, .Ok
        }
        return {}, .Need_More
    }

    a, mods, count := split_params(params)
    switch final {
    case 'A':
        return Key{code = .Up, mods = mods}, .Ok
    case 'B':
        return Key{code = .Down, mods = mods}, .Ok
    case 'C':
        return Key{code = .Right, mods = mods}, .Ok
    case 'D':
        return Key{code = .Left, mods = mods}, .Ok
    case 'H':
        return Key{code = .Home, mods = mods}, .Ok
    case 'F':
        return Key{code = .End, mods = mods}, .Ok
    case 'P':
        return Key{code = .F1, mods = mods}, .Ok
    case 'Q':
        return Key{code = .F2, mods = mods}, .Ok
    case 'R':
        return Key{code = .F3, mods = mods}, .Ok
    case 'S':
        return Key{code = .F4, mods = mods}, .Ok
    case 'Z':
        return Key{code = .Tab, mods = {.Shift}}, .Ok
    case 'I':
        return Focus{gained = true}, .Ok
    case 'O':
        return Focus{gained = false}, .Ok
    case '~':
        if count == 0 {
            return {}, .Need_More
        }
        code: Key_Code
        switch a {
        case 200:
            return {}, .Paste_Begin
        case 201:
            // Stray paste end; nothing to report.
            return {}, .Need_More
        case 1, 7:
            code = .Home
        case 2:
            code = .Insert
        case 3:
            code = .Delete
        case 4, 8:
            code = .End
        case 5:
            code = .Page_Up
        case 6:
            code = .Page_Down
        case 11:
            code = .F1
        case 12:
            code = .F2
        case 13:
            code = .F3
        case 14:
            code = .F4
        case 15:
            code = .F5
        case 17:
            code = .F6
        case 18:
            code = .F7
        case 19:
            code = .F8
        case 20:
            code = .F9
        case 21:
            code = .F10
        case 23:
            code = .F11
        case 24:
            code = .F12
        case:
            return {}, .Need_More
        }
        return Key{code = code, mods = mods}, .Ok
    }
    return {}, .Need_More
}

// Splits `a` or `a;m` where `m` is the xterm modifier parameter.
@(private)
split_params :: proc(params: string) -> (a: int, mods: Modifiers, count: int) {
    if len(params) == 0 {
        return
    }
    first, rest := params, ""
    if semi := strings.index_byte(params, ';'); semi >= 0 {
        first, rest = params[:semi], params[semi + 1:]
    }
    a = strconv.parse_int(first) or_else 0
    count = 1
    if len(rest) > 0 {
        m := strconv.parse_int(rest) or_else 1
        mods = xterm_modifiers(m)
        count = 2
    }
    return
}

@(private)
xterm_modifiers :: proc(m: int) -> (mods: Modifiers) {
    bits := m - 1
    if bits & 1 != 0 {
        mods += {.Shift}
    }
    if bits & 2 != 0 {
        mods += {.Alt}
    }
    if bits & 4 != 0 {
        mods += {.Ctrl}
    }
    return
}

// `Cb;Cx;Cy` from `CSI < Cb ; Cx ; Cy M|m`.
@(private)
decode_sgr_mouse :: proc(params: string, release: bool) -> (m: Mouse, ok: bool) {
    rest := params
    cb := strconv.parse_int(strings.split_iterator(&rest, ";") or_return) or_return
    cx := strconv.parse_int(strings.split_iterator(&rest, ";") or_return) or_return
    cy := strconv.parse_int(strings.split_iterator(&rest, ";") or_return) or_return

    if cb & 4 != 0 {
        m.mods += {.Shift}
    }
    if cb & 8 != 0 {
        m.mods += {.Alt}
    }
    if cb & 16 != 0 {
        m.mods += {.Ctrl}
    }
    m.col = cx - 1
    m.row = cy - 1

    low := cb & 3
    switch {
    case cb & 64 != 0:
        m.action = .Scroll
        switch low {
        case 0:
            m.button = .Wheel_Up
        case 1:
            m.button = .Wheel_Down
        case 2:
            m.button = .Wheel_Left
        case 3:
            m.button = .Wheel_Right
        }
    case:
        switch low {
        case 0:
            m.button = .Left
        case 1:
            m.button = .Middle
        case 2:
            m.button = .Right
        case 3:
            m.button = .None
        }
        switch {
        case release:
            m.action = .Release
        case cb & 32 != 0:
            m.action = .Move if m.button == .None else .Drag
        case:
            m.action = .Press
        }
    }
    return m, true
}
