package renderer

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

// Fills a border of the given thickness inside `insert` with `bg`.
render_border :: proc(renderer: ^Renderer, insert: Insert_At, width: BordersWidth, bg: Color = Simple_Color.Default, style: Maybe(Style) = nil) {
    if insert.width <= 0 || insert.height <= 0 {
        return
    }
    cell := Cell{Simple_Color.Default, bg, style, nil}
    in_border :: proc(insert: Insert_At, width: BordersWidth, row, col: int) -> bool {
        return(
            row < insert.y + width.top ||
            row >= insert.y + insert.height - width.bottom ||
            col < insert.x + width.left ||
            col >= insert.x + insert.width - width.right \
        )
    }

    row_start, row_end, col_start, col_end := scissor_bound_indicies(renderer, insert)
    for row in row_start ..< row_end {
        for col in col_start ..< col_end {
            if in_border(insert, width, row, col) {
                put_cell(renderer, row, col, cell)
            }
        }
    }
}

// Draws a one cell frame of box-drawing characters along the edge of `insert`.
render_frame :: proc(renderer: ^Renderer, insert: Insert_At, fg: Maybe(Color) = nil, bg: Maybe(Color) = nil, style: Maybe(Style) = nil, rounded := false) {
    if insert.width <= 0 || insert.height <= 0 {
        return
    }
    left, right := insert.x, insert.x + insert.width - 1
    top, bottom := insert.y, insert.y + insert.height - 1
    row_start, row_end, col_start, col_end := scissor_bound_indicies(renderer, insert)

    for row in row_start ..< row_end {
        for col in col_start ..< col_end {
            glyph: rune
            switch {
            case row == top && col == left:
                glyph = TOP_LEFT_BORDER_ROUNDED if rounded else TOP_LEFT_BORDER
            case row == top && col == right:
                glyph = TOP_RIGHT_BORDER_ROUNDED if rounded else TOP_RIGHT_BORDER
            case row == bottom && col == left:
                glyph = BOTTOM_LEFT_BORDER_ROUNDED if rounded else BOTTOM_LEFT_BORDER
            case row == bottom && col == right:
                glyph = BOTTOM_RIGHT_BORDER_ROUNDED if rounded else BOTTOM_RIGHT_BORDER
            case row == top || row == bottom:
                glyph = HORIZONTAL_BORDER
            case col == left || col == right:
                glyph = VERTICAL_BORDER
            case:
                continue
            }
            if insert.width == 1 {
                glyph = VERTICAL_BORDER
            } else if insert.height == 1 {
                glyph = HORIZONTAL_BORDER
            }
            put_text_cell(renderer, row, col, glyph, fg, bg, style)
        }
    }
}
