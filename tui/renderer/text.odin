package renderer

import "base:runtime"
import "core:mem/virtual"
import "core:unicode/utf8"
import "tui:utils"

// TODO: Propper word splits
wrap_text :: proc(text: string, bounds: Bounds, allocator: runtime.Allocator) -> []rune {
    res := make([dynamic]rune, bounds.x * bounds.y, allocator = allocator)
    runes := utf8.string_to_runes(text, allocator)
    row := 0
    col := 0
    for r, i in text {
        if (i > 0 && i % bounds.x == 0) || r == '\n' {
            row += 1
            col = 0
        }
        ri := utils.tranform_2d_index(bounds.x, row, col)
        res[ri] = r == '\n' ? ' ' : r
        col += 1
    }
    return res[:]
}

render_text :: proc(renderer: ^Renderer, insert: InsertAt, text: string, fg: Color = .DoNotChange, bg: Color = .DoNotChange, style: Style = .DoNotChange) {
    arena_allocator := virtual.arena_allocator(&renderer.arena)
    wrapped := wrap_text(text, {insert.width, insert.height}, arena_allocator)
    for row in insert.y ..< insert.y + insert.height {
        for col in insert.x ..< insert.x + insert.width {
            i := utils.tranform_2d_index(renderer.bounds.x, row, col)
            if i >= len(renderer.state) {
                continue
            }
            wi := utils.tranform_2d_index(insert.width, row - insert.y, col - insert.x)
            cell := &renderer.state[i]
            if fg != .DoNotChange {
                cell.fg = fg
            }
            if bg != .DoNotChange {
                cell.bg = bg
            }
            if style != .DoNotChange {
                cell.style = style
            }
            cell.value = wrapped[wi]
        }
    }
}
