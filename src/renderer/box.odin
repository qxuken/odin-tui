package renderer

import "../utils"
import "core:unicode/utf8"

render_box :: proc(renderer: Renderer, bg: Color, start: Coord, bounds: Bounds) {
	for row in 1 ..= bounds.y {
		start_i := utils.tranform_2d_index(start.x + bounds.x, start.x + row, start.y)
		for col in 0 ..< bounds.x {
			i := utils.tranform_2d_index(bounds.x, row, col)
			renderer.state[start_i + i].bg = bg
		}
	}
}
