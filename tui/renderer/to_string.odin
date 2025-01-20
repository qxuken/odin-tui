package renderer

import "core:mem/virtual"
import "core:strings"
import "tui:utils"

to_string :: proc(renderer: ^Renderer) -> string {
    arena_allocator := virtual.arena_allocator(&renderer.arena)
    out := strings.builder_make(allocator = arena_allocator)
    for row in 0 ..< renderer.bounds.y {
        for col in 0 ..< renderer.bounds.x {
            i := utils.tranform_2d_index(renderer.bounds.x, row, col)
            cell := &renderer.state[i]
            if i > 0 {
                prevCell := &renderer.state[i - 1]
                // Some -> None : need reset
                if (cell.bg == .None && prevCell.bg != .None) || (cell.fg == .None && prevCell.fg != .None) {
                    strings.write_string(&out, reset_code())
                    if cell.fg != .None {
                        strings.write_string(&out, fg_color_code(cell.fg, arena_allocator))
                    }
                    if cell.bg != .None {
                        strings.write_string(&out, bg_color_code(cell.bg, arena_allocator))
                    }
                } else {
                    if cell.bg != .None && cell.bg != prevCell.bg {
                        strings.write_string(&out, bg_color_code(cell.bg, arena_allocator))
                    }
                    if cell.fg != .None && cell.fg != prevCell.fg {
                        strings.write_string(&out, fg_color_code(cell.fg, arena_allocator))
                    }
                    if cell.style != prevCell.style {
                        strings.write_string(&out, cell.style == .None ? end_style_code(prevCell.style) : start_style_code(cell.style))
                    }
                }
            } else {
                strings.write_string(&out, bg_color_code(cell.bg, arena_allocator))
                strings.write_string(&out, fg_color_code(cell.fg, arena_allocator))
                strings.write_string(&out, start_style_code(cell.style))
            }
            if cell.value == 0 {
                strings.write_rune(&out, ' ')
            } else {
                strings.write_rune(&out, cell.value)
            }
        }
    }
    strings.write_string(&out, reset_code())
    return strings.to_string(out)
}
