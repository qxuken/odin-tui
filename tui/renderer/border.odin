package renderer

import "core:unicode/utf8"
import "tui:utils"

// https://gitlab.com/christosangel/c-squares/-/blob/main/c-squares.c?ref_type=heads
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

render_border :: proc(renderer: ^Renderer, insert: InsertAt, width: BordersWidth, bg: Color = SimpleColor.Default, style: Maybe(Style) = nil) {
    if insert.width <= 0 || insert.height <= 0 {
        return
    }
    row_start, row_end, col_start, col_end := scissor_bound_indicies(renderer, insert)
    cell := Cell{SimpleColor.Default, bg, style, nil}

    if insert.width == 1 {
        for row in row_start ..= row_end {
            put_cell(renderer, row, col_start, cell)
        }
    } else if insert.height == 1 {
        for col in col_start - width.left ..= col_start {
            put_cell(renderer, row_start, col, cell)
        }
        return
    } else {
        for row in row_start ..= row_end {
            for col in col_start ..< col_start + width.left {
                put_cell(renderer, row, col, cell)
            }
            for col in col_end - width.right + 1 ..= col_end {
                put_cell(renderer, row, col, cell)
            }
        }
        for col in col_start ..= col_end {
            for row in row_start ..< row_start + width.top {
                put_cell(renderer, row, col, cell)
            }
            for row in row_end - width.bottom + 1 ..= row_end {
                put_cell(renderer, row, col, cell)
            }
        }
    }
}
