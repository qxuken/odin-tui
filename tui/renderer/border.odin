package renderer

import "core:unicode/utf8"
import "tui:utils"

TOP_LEFT_BORDER :: '┌'
TOP_LEFT_BORDER_ROUNDED :: '╭'

TOP_RIGHT_BORDER :: '┐'
TOP_RIGHT_BORDER_ROUNDED :: '╮'

BOTTOM_LEFT_BORDER :: '└'
BOTTOM_LEFT_BORDER_ROUNDED :: '╰'

BOTTOM_RIGHT_BORDER :: '┘'
BOTTOM_RIGHT_BORDER_ROUNDED :: '╯'

HORIZONTAL_BORDER :: '─'
VERTICAL_BORDER :: '│'

BordersWidth :: struct {
    top:    int,
    right:  int,
    bottom: int,
    left:   int,
}

render_border :: proc(renderer: ^Renderer, insert: InsertAt, width: BordersWidth, bg: Color = .DoNotChange, style: Style = .DoNotChange) {
    if insert.width <= 0 || insert.height <= 0 {
        return
    }
    row_start, row_end, col_start, col_end := scissor_bound_indicies(renderer, insert)

    if insert.width == 1 {
        for row in row_start ..= row_end {
            modify_cell(renderer, row, col_start, bg = bg, style = style)
        }
    } else if insert.height == 1 {
        for col in col_start - width.left ..= col_start {
            modify_cell(renderer, row_start, col, bg = bg, style = style)
        }
        return
    } else {
        for row in row_start ..= row_end {
            for col in col_start ..< col_start + width.left {
                modify_cell(renderer, row, col, bg = bg, style = style)
            }
            for col in col_end - width.right + 1 ..= col_end {
                modify_cell(renderer, row, col, bg = bg, style = style)
            }
        }
        for col in col_start ..= col_end {
            for row in row_start ..< row_start + width.top {
                modify_cell(renderer, row, col, bg = bg, style = style)
            }
            for row in row_end - width.bottom + 1 ..= row_end {
                modify_cell(renderer, row, col, bg = bg, style = style)
            }
        }
    }
}
