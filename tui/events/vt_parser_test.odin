package events

import "core:testing"

@(private = "file")
feed :: proc(t: ^testing.T, input: string, flush := false) -> (out: [dynamic]Event, p: Parser) {
    p.buf = make([dynamic]u8, context.temp_allocator)
    append(&p.buf, ..transmute([]u8)input)
    out = make([dynamic]Event, context.temp_allocator)
    parser_drain(&p, &out, flush, context.temp_allocator)
    return
}

@(test)
plain_and_utf8_chars :: proc(t: ^testing.T) {
    out, p := feed(t, "aé👪")
    testing.expect_value(t, len(out), 3)
    testing.expect_value(t, out[0], Event(Key{code = .Char, char = 'a'}))
    testing.expect_value(t, out[1], Event(Key{code = .Char, char = 'é'}))
    testing.expect_value(t, out[2], Event(Key{code = .Char, char = '👪'}))
    testing.expect_value(t, len(p.buf), 0)
}

@(test)
control_keys :: proc(t: ^testing.T) {
    out, _ := feed(t, "\r\n\t\x7f\x08\x03\x00\x1f")
    testing.expect_value(t, len(out), 8)
    testing.expect_value(t, out[0], Event(Key{code = .Enter}))
    testing.expect_value(t, out[1], Event(Key{code = .Enter}))
    testing.expect_value(t, out[2], Event(Key{code = .Tab}))
    testing.expect_value(t, out[3], Event(Key{code = .Backspace}))
    testing.expect_value(t, out[4], Event(Key{code = .Backspace}))
    testing.expect_value(t, out[5], Event(Key{code = .Char, char = 'c', mods = {.Ctrl}}))
    testing.expect_value(t, out[6], Event(Key{code = .Char, char = ' ', mods = {.Ctrl}}))
    testing.expect_value(t, out[7], Event(Key{code = .Char, char = '_', mods = {.Ctrl}}))
}

@(test)
lone_escape_waits_then_flushes :: proc(t: ^testing.T) {
    out, p := feed(t, "\x1b")
    testing.expect_value(t, len(out), 0)
    testing.expect_value(t, len(p.buf), 1)
    testing.expect(t, parser_has_partial(&p))

    out2, p2 := feed(t, "\x1b", flush = true)
    testing.expect_value(t, len(out2), 1)
    testing.expect_value(t, out2[0], Event(Key{code = .Escape}))
    testing.expect_value(t, len(p2.buf), 0)
}

@(test)
alt_prefix :: proc(t: ^testing.T) {
    out, _ := feed(t, "\x1bx\x1b\x1b", flush = true)
    testing.expect_value(t, len(out), 2)
    testing.expect_value(t, out[0], Event(Key{code = .Char, char = 'x', mods = {.Alt}}))
    testing.expect_value(t, out[1], Event(Key{code = .Escape, mods = {.Alt}}))
}

@(test)
csi_keys :: proc(t: ^testing.T) {
    out, _ := feed(t, "\x1b[A\x1b[1;5D\x1b[H\x1b[3~\x1b[5;2~\x1b[15~\x1b[24~\x1b[Z\x1b[1;3P")
    testing.expect_value(t, len(out), 9)
    testing.expect_value(t, out[0], Event(Key{code = .Up}))
    testing.expect_value(t, out[1], Event(Key{code = .Left, mods = {.Ctrl}}))
    testing.expect_value(t, out[2], Event(Key{code = .Home}))
    testing.expect_value(t, out[3], Event(Key{code = .Delete}))
    testing.expect_value(t, out[4], Event(Key{code = .Page_Up, mods = {.Shift}}))
    testing.expect_value(t, out[5], Event(Key{code = .F5}))
    testing.expect_value(t, out[6], Event(Key{code = .F12}))
    testing.expect_value(t, out[7], Event(Key{code = .Tab, mods = {.Shift}}))
    testing.expect_value(t, out[8], Event(Key{code = .F1, mods = {.Alt}}))
}

@(test)
ss3_keys :: proc(t: ^testing.T) {
    out, _ := feed(t, "\x1bOA\x1bOP\x1bOF")
    testing.expect_value(t, len(out), 3)
    testing.expect_value(t, out[0], Event(Key{code = .Up}))
    testing.expect_value(t, out[1], Event(Key{code = .F1}))
    testing.expect_value(t, out[2], Event(Key{code = .End}))
}

@(test)
split_sequence_across_reads :: proc(t: ^testing.T) {
    out, p := feed(t, "\x1b[1;")
    testing.expect_value(t, len(out), 0)
    testing.expect_value(t, len(p.buf), 4)

    append(&p.buf, ..transmute([]u8)string("5Cq"))
    parser_drain(&p, &out, false, context.temp_allocator)
    testing.expect_value(t, len(out), 2)
    testing.expect_value(t, out[0], Event(Key{code = .Right, mods = {.Ctrl}}))
    testing.expect_value(t, out[1], Event(Key{code = .Char, char = 'q'}))
    testing.expect_value(t, len(p.buf), 0)
}

@(test)
sgr_mouse :: proc(t: ^testing.T) {
    out, _ := feed(t, "\x1b[<0;10;5M\x1b[<0;10;5m\x1b[<32;11;5M\x1b[<35;12;6M\x1b[<64;1;1M\x1b[<65;1;1M\x1b[<18;3;4M")
    testing.expect_value(t, len(out), 7)
    testing.expect_value(t, out[0], Event(Mouse{action = .Press, button = .Left, col = 9, row = 4}))
    testing.expect_value(t, out[1], Event(Mouse{action = .Release, button = .Left, col = 9, row = 4}))
    testing.expect_value(t, out[2], Event(Mouse{action = .Drag, button = .Left, col = 10, row = 4}))
    testing.expect_value(t, out[3], Event(Mouse{action = .Move, button = .None, col = 11, row = 5}))
    testing.expect_value(t, out[4], Event(Mouse{action = .Scroll, button = .Wheel_Up, col = 0, row = 0}))
    testing.expect_value(t, out[5], Event(Mouse{action = .Scroll, button = .Wheel_Down, col = 0, row = 0}))
    testing.expect_value(t, out[6], Event(Mouse{action = .Press, button = .Right, col = 2, row = 3, mods = {.Ctrl}}))
}

@(test)
focus_and_paste :: proc(t: ^testing.T) {
    out, p := feed(t, "\x1b[I\x1b[200~hello\x1b[Aworld")
    testing.expect_value(t, len(out), 1)
    testing.expect_value(t, out[0], Event(Focus{gained = true}))
    testing.expect(t, p.in_paste)

    append(&p.buf, ..transmute([]u8)string("!\x1b[201~\x1b[O"))
    parser_drain(&p, &out, false, context.temp_allocator)
    testing.expect_value(t, len(out), 3)
    paste, is_paste := out[1].(Paste)
    testing.expect(t, is_paste)
    testing.expect_value(t, paste.text, "hello\x1b[Aworld!")
    testing.expect_value(t, out[2], Event(Focus{gained = false}))
    testing.expect(t, !p.in_paste)
}

@(test)
unknown_sequences :: proc(t: ^testing.T) {
    out, _ := feed(t, "\x1b[?1;2c")
    testing.expect_value(t, len(out), 1)
    u, is_unknown := out[0].(Unknown)
    testing.expect(t, is_unknown)
    testing.expect_value(t, u.raw, "\x1b[?1;2c")
}
