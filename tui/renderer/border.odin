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
    left_col := insert.x
    right_col := insert.x + insert.width
    top_row := insert.y
    bottom_row := insert.y + insert.height
    if insert.width == 1 {
        for row in top_row ..= bottom_row {
            modify_cell(renderer, row, left_col, bg = bg, style = style)
        }
    } else if insert.height == 1 {
        for col in left_col - width.left ..= left_col {
            modify_cell(renderer, top_row, col, bg = bg, style = style)
        }
        return
    } else {
        for row in top_row ..= bottom_row {
            for col in left_col ..< left_col + width.left {
                modify_cell(renderer, row, col, bg = bg, style = style)
            }
            for col in right_col - width.right + 1 ..= right_col {
                modify_cell(renderer, row, col, bg = bg, style = style)
            }
        }
        for col in left_col ..= right_col {
            for row in top_row ..< top_row + width.top {
                modify_cell(renderer, row, col, bg = bg, style = style)
            }
            for row in bottom_row - width.bottom + 1 ..= bottom_row {
                modify_cell(renderer, row, col, bg = bg, style = style)
            }
        }
    }
}
