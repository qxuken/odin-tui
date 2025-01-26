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

render_text :: proc(renderer: ^Renderer, insert: InsertAt, text: string, fg: Maybe(Color) = nil, bg: Maybe(Color) = nil, style: Maybe(Style) = nil) {
    arena_allocator := virtual.arena_allocator(&renderer.arena)
    wrapped := wrap_text(text, {insert.width, insert.height}, arena_allocator)

    row_start, row_end, col_start, col_end := scissor_bound_indicies(renderer, insert)

    for row in row_start ..< row_end {
        for col in col_start ..< col_end {
            wi := utils.tranform_2d_index(insert.width, row - insert.y, col - insert.x)
            put_text_cell(renderer, row, col, wrapped[wi], fg, bg, style)
        }
    }
}
