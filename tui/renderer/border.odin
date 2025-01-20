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
    if insert.width == 1 {
        col := insert.x
        for row in insert.y ..= insert.y + insert.height {
            modify_cell(renderer, row, col, bg = bg, style = style)
        }
    } else if insert.height == 1 {
        row := insert.y
        for col in insert.x ..= insert.x + insert.width {
            modify_cell(renderer, row, col, bg = bg, style = style)
        }
        return
    } else {
        left_col := insert.x
        right_col := insert.x + insert.width
        top_row := insert.y
        bottom_row := insert.y + insert.height
        for row in insert.y ..= insert.y + insert.height {
            if width.left > 0 {
                for col in left_col ..= left_col + width.left {
                    modify_cell(renderer, row, col, bg = bg, style = style)
                }
            }
            if width.right > 0 {
                for col in right_col - width.right ..= right_col {
                    modify_cell(renderer, row, col, bg = bg, style = style)
                }
            }
        }
        for col in insert.x ..= insert.x + insert.width {
            if width.top > 0 {
                for row in top_row ..= top_row + width.top {
                    modify_cell(renderer, row, col, bg = bg, style = style)
                }
            }
            if width.bottom > 0 {
                for row in bottom_row - width.bottom ..= bottom_row {
                    modify_cell(renderer, row, col, bg = bg, style = style)
                }
            }
        }
    }
}
