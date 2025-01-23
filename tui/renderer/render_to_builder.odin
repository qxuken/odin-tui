package renderer

import "core:mem/virtual"
import "core:strings"
import "tui:utils"

render_to_builder :: proc(renderer: ^Renderer, out: ^strings.Builder) {
    arena_allocator := virtual.arena_allocator(&renderer.arena)
    c_bg: Color = SimpleColor.None
    c_fg: Color = SimpleColor.None
    c_style := Style.None
    contigues_empty := 0
    for cell, i in renderer.state {
        if contigues_empty > 0 && i % renderer.bounds[0] == 0 {
            strings.write_string(out, "\r\n")
            contigues_empty = 0
        }
        if cell.bg == .None && cell.fg == .None && cell.style == .None && (cell.value == 0 || cell.value == ' ') {
            contigues_empty += 1
        } else if contigues_empty > 0 {
            gap := strings.repeat(" ", contigues_empty, arena_allocator)
            strings.write_string(out, gap)
            contigues_empty = 0
        }
        if (cell.bg == .None && c_bg != .None) || (cell.fg == .None && c_fg != .None) {
            strings.write_string(out, reset_code())
            if cell.fg != .None {
                strings.write_string(out, fg_color_code(cell.fg, arena_allocator))
            }
            if cell.bg != .None {
                strings.write_string(out, bg_color_code(cell.bg, arena_allocator))
            }
        } else {
            if cell.bg != .None && cell.bg != c_bg {
                strings.write_string(out, bg_color_code(cell.bg, arena_allocator))
            }
            if cell.fg != .None && cell.fg != c_fg {
                strings.write_string(out, fg_color_code(cell.fg, arena_allocator))
            }
        }
        if cell.bg != c_bg {
            c_bg = cell.bg
        }
        if cell.fg != c_fg {
            c_fg = cell.fg
        }
        if cell.style != c_style {
            strings.write_string(out, end_style_code(c_style))
            if cell.style != .None {
                start_style_code(cell.style)
            }
            c_style = cell.style
        }

        if (cell.bg != .None || cell.fg != .None || cell.style != .None) && (cell.value == 0 || cell.value == ' ') {
            strings.write_rune(out, ' ')
        } else {
            strings.write_rune(out, cell.value)
        }
    }
    strings.write_string(out, reset_code())
}
