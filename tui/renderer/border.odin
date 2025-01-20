package renderer

import "tui:utils"
import "core:unicode/utf8"

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

render_border :: proc(
	renderer: ^Renderer,
	insert: InsertAt,
	width: BordersWidth,
	bg: Color = .DoNotChange,
	fg: Color = .DoNotChange,
	style: Style = .DoNotChange,
) {
	if insert.width <= 0 || insert.height <= 0 {
		return
	}
	if insert.width == 1 {
		col := insert.x
		for row in insert.y ..< insert.y + insert.height {
			i := utils.tranform_2d_index(renderer.bounds.x, row, col)
			cell := &renderer.state[i]
			cell.value = VERTICAL_BORDER
		}
	} else if insert.height == 1 {
		row := insert.y
		for col in insert.x ..< insert.x + insert.width {
			i := utils.tranform_2d_index(renderer.bounds.x, row, col)
			cell := &renderer.state[i]
			cell.value = HORIZONTAL_BORDER
		}
		return
	} else {
		left_col := insert.x
		right_col := insert.x + insert.width
		top_row := insert.y
		bottom_row := insert.y + insert.height
		for row in insert.y ..< insert.y + insert.height {
			for col in insert.x ..< insert.x + insert.width {
				i := utils.tranform_2d_index(renderer.bounds.x, row, col)
				cell := &renderer.state[i]
				if cell.value == 0 {
					cell.value = ' '
				}
			}
		}
	}
}
