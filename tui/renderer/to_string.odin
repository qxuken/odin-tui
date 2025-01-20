package renderer

import "tui:utils"
import "core:mem/virtual"
import "core:strings"

to_string :: proc(renderer: ^Renderer) -> string {
	arena_allocator := virtual.arena_allocator(&renderer.arena)
	out := strings.builder_make(allocator = arena_allocator)
	for row in 0 ..< renderer.bounds.y {
		for col in 0 ..< renderer.bounds.x {
			i := utils.tranform_2d_index(renderer.bounds.x, row, col)
			cell := &renderer.state[i]
			strings.write_string(&out, bg_color_code(cell.bg, arena_allocator))
			strings.write_string(&out, fg_color_code(cell.fg, arena_allocator))
			strings.write_string(&out, start_style_code(cell.style))
			if cell.value == 0 {
				strings.write_rune(&out, ' ')
			} else {
				strings.write_rune(&out, cell.value)
			}
			strings.write_string(&out, end_style_code(cell.style))
			strings.write_string(&out, reset_code())
		}
	}
	return strings.to_string(out)
}
