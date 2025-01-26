package renderer

import "core:unicode/utf8"
import "tui:utils"

render_box :: proc(renderer: ^Renderer, insert: InsertAt, bg: Color = .DoNotChange, style: Style = .DoNotChange) {
    row_start, row_end, col_start, col_end := scissor_bound_indicies(renderer, insert)
    for row in row_start ..< row_end {
        for col in col_start ..< col_end {
            modify_cell(renderer, row, col, bg = bg, style = style)
        }
    }
}
