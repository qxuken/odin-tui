package renderer

import "core:mem/virtual"
import "core:strings"
import "tui:utils"

render_to_builder :: proc(renderer: ^Renderer, out: ^strings.Builder) {
    arena_allocator := virtual.arena_allocator(&renderer.arena)

    c_bg: Color
    c_fg: Color
    c_style: Maybe(Style)
    contigues_len := 0

    for cell, i in renderer.state {
        if contigues_len > 0 && i % renderer.bounds.x == 0 {
            if c_bg != Simple_Color.Default || c_fg != Simple_Color.Default || c_style != nil {
                gap := strings.repeat(" ", contigues_len, arena_allocator)
                strings.write_string(out, gap)
            }
            strings.write_string(out, "\r\n")
            contigues_len = 0
        }

        if cell.fg == c_fg && cell.bg == c_bg && cell.style == c_style && cell.data == nil {
            contigues_len += 1
            continue
        } else if contigues_len > 0 {
            gap := strings.repeat(" ", contigues_len, arena_allocator)
            strings.write_string(out, gap)
            contigues_len = 0
        }

        if cell.bg != c_bg {
            strings.write_string(out, bg_color_code(cell.bg, arena_allocator))
            c_bg = cell.bg
        }
        if cell.fg != c_fg {
            strings.write_string(out, fg_color_code(cell.fg, arena_allocator))
            c_fg = cell.fg
        }
        if cell.style != c_style {
            if s, ok := c_style.?; ok {
                strings.write_string(out, end_style_code(s))
            }
            if s, ok := cell.style.?; ok {
                strings.write_string(out, start_style_code(s))
            }
            c_style = cell.style
        }

        if v, ok := cell.data.(Text_Data); ok {
            switch text_value in v.value {
            case rune:
                strings.write_rune(out, text_value)
            case Grapheme_Value:
                strings.write_bytes(out, text_value)
            }
        } else {
            strings.write_rune(out, ' ')
        }
    }

    if contigues_len > 0 && (c_bg != Simple_Color.Default || c_fg != Simple_Color.Default || c_style != nil) {
        gap := strings.repeat(" ", contigues_len, arena_allocator)
        strings.write_string(out, gap)
    }
    strings.write_string(out, reset_code())
}
