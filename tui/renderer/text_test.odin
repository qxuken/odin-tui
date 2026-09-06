package renderer

import "core:testing"

@(private = "file")
lines :: proc(cells: []Text_Data_Value, width: int) -> [dynamic]string {
    res := make([dynamic]string, context.temp_allocator)
    for row := 0; row * width < len(cells); row += 1 {
        buf := make([dynamic]u8, context.temp_allocator)
        for cell in cells[row * width:][:width] {
            switch v in cell {
            case rune:
                if v == 0 {
                    append(&buf, '.')
                } else {
                    append(&buf, ..transmute([]u8)string(rune_to_string(v)))
                }
            case Grapheme_Value:
                append(&buf, ..v)
            case Wide_Continuation:
                append(&buf, '_')
            }
        }
        append(&res, string(buf[:]))
    }
    return res
}

@(private = "file")
rune_to_string :: proc(r: rune) -> string {
    buf := make([]u8, 4, context.temp_allocator)
    n := 0
    switch {
    case r < 0x80:
        buf[0] = u8(r)
        n = 1
    case r < 0x800:
        buf[0] = u8(0xC0 | r >> 6)
        buf[1] = u8(0x80 | r & 0x3F)
        n = 2
    case r < 0x10000:
        buf[0] = u8(0xE0 | r >> 12)
        buf[1] = u8(0x80 | (r >> 6) & 0x3F)
        buf[2] = u8(0x80 | r & 0x3F)
        n = 3
    case:
        buf[0] = u8(0xF0 | r >> 18)
        buf[1] = u8(0x80 | (r >> 12) & 0x3F)
        buf[2] = u8(0x80 | (r >> 6) & 0x3F)
        buf[3] = u8(0x80 | r & 0x3F)
        n = 4
    }
    return string(buf[:n])
}

@(test)
word_wrap_basic :: proc(t: ^testing.T) {
    out := lines(wrap_text("Wrap words here.\nnext", {10, 4}, .Word, context.temp_allocator), 10)
    testing.expect_value(t, out[0], "Wrap words")
    testing.expect_value(t, out[1], "here. ....")
    testing.expect_value(t, out[2], "next......")
    testing.expect_value(t, out[3], "..........")
}

@(test)
word_wrap_hyphenates_long_words :: proc(t: ^testing.T) {
    out := lines(wrap_text("abcdefghij", {5, 3}, .Word, context.temp_allocator), 5)
    testing.expect_value(t, out[0], "abcd-")
    testing.expect_value(t, out[1], "efgh-")
    testing.expect_value(t, out[2], "ij...")
}

@(test)
word_wrap_unicode :: proc(t: ^testing.T) {
    out := lines(wrap_text("héllo wörld 👪x", {6, 3}, .Word, context.temp_allocator), 6)
    testing.expect_value(t, out[0], "héllo ")
    testing.expect_value(t, out[1], "wörld ")
    testing.expect_value(t, out[2], "👪_x...")
}

@(test)
line_and_none_modes :: proc(t: ^testing.T) {
    line := lines(wrap_text("ab\tc\nlonger than", {6, 2}, .Line, context.temp_allocator), 6)
    testing.expect_value(t, line[0], "ab    ")
    testing.expect_value(t, line[1], "longer")

    none := lines(wrap_text("a\nb", {6, 1}, .None, context.temp_allocator), 6)
    testing.expect_value(t, none[0], "a b...")
}

@(test)
wide_glyph_wraps_when_it_does_not_fit :: proc(t: ^testing.T) {
    out := lines(wrap_text("a👪", {2, 2}, .Word, context.temp_allocator), 2)
    testing.expect_value(t, out[0], "a.")
    testing.expect_value(t, out[1], "👪_")
}
