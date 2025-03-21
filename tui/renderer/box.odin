package renderer

import "core:unicode/utf8"
import "tui:utils"

render_box :: proc(renderer: ^Renderer, insert: Insert_At, bg: Color = Simple_Color.Default, style: Maybe(Style) = nil) {
    row_start, row_end, col_start, col_end := scissor_bound_indicies(renderer, insert)
    cell := Cell{Simple_Color.Default, bg, style, nil}
    for row in row_start ..< row_end {
        for col in col_start ..< col_end {
            put_cell(renderer, row, col, cell)
        }
    }
}
