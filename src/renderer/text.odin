package renderer

import "../utils"
import "base:runtime"
import "core:mem/virtual"
import "core:unicode/utf8"

// NOTE: Propper word splits
wrap_text :: proc(text: string, bounds: Bounds, allocator: runtime.Allocator) -> []rune {
	res := make([dynamic]rune, bounds.x * bounds.y, allocator = allocator)
	runes := utf8.string_to_runes(text, allocator)
	row := 0
	col := 0
	for r, i in text {
		if i % bounds.x == 0 {
			row += 1
			col = 0
		}
		res[utils.tranform_2d_index(bounds.x, row, col)] = r
		col += 1
	}
	return res[:]
}

render_text :: proc(
	renderer: ^Renderer,
	text: string,
	fg: Color,
	bg: Color,
	style: Style,
	start: Coord,
	bounds: Bounds,
) {
	arena_allocator := virtual.arena_allocator(&renderer.arena)
	wrapped := wrap_text(text, bounds, arena_allocator)
	for row in 1 ..= bounds.y {
		start_i := utils.tranform_2d_index(start.x + bounds.x, start.x + row, start.y)
		for col in 0 ..< bounds.x {
			i := utils.tranform_2d_index(bounds.x, row, col)
			cell := &renderer.state[start_i + i]
			if fg != .None {
				cell.fg = fg
			}
			if bg != .None {
				cell.bg = bg
			}
			if style != .None {
				cell.style = style
			}
			cell.value = wrapped[i]
		}
	}
}
