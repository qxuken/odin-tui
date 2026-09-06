package renderer

import "core:mem/virtual"
import "core:strings"
import "core:terminal/ansi"

@(private = "file")
ERASE_LINE_RIGHT :: ansi.CSI + "0K"

// Serialises the grid into `out`, starting at the current cursor position.
// Rows are terminated with CR LF and trailing empty cells are erased rather
// than overwritten, so the caller only needs to move the cursor home first.
render_to_builder :: proc(renderer: ^Renderer, out: ^strings.Builder) {
    arena_allocator := virtual.arena_allocator(&renderer.arena)

    c_bg: Color = Simple_Color.Default
    c_fg: Color = Simple_Color.Default
    c_style: Maybe(Style)

    write_gap :: proc(out: ^strings.Builder, n: int) {
        for _ in 0 ..< n {
            strings.write_byte(out, ' ')
        }
    }

    for row in 0 ..< renderer.bounds.y {
        if row > 0 {
            strings.write_string(out, "\r\n")
        }
        gap := 0
        for col in 0 ..< renderer.bounds.x {
            cell := renderer.state[row * renderer.bounds.x + col]
            if cell.data == nil && cell.fg == c_fg && cell.bg == c_bg && cell.style == c_style {
                gap += 1
                continue
            }
            if gap > 0 {
                write_gap(out, gap)
                gap = 0
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
                case Wide_Continuation:
                // covered by the preceding wide character
                }
            } else {
                strings.write_byte(out, ' ')
            }
        }

        if gap > 0 {
            if c_bg != Simple_Color.Default || c_fg != Simple_Color.Default || c_style != nil {
                write_gap(out, gap)
            } else {
                strings.write_string(out, ERASE_LINE_RIGHT)
            }
        }
    }
    strings.write_string(out, reset_code())
}
