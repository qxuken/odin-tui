package renderer

import "core:unicode/utf8"
import "tui:utils"

render_box :: proc(renderer: ^Renderer, insert: InsertAt, bg: Color = .DoNotChange, fg: Color = .DoNotChange, style: Style = .DoNotChange) {
    for row in insert.y ..< insert.y + insert.height {
        for col in insert.x ..< insert.x + insert.width {
            i := utils.tranform_2d_index(renderer.bounds.x, row, col)
            if i >= len(renderer.state) {
                continue
            }
            cell := &renderer.state[i]
            if fg != .DoNotChange {
                cell.fg = fg
            }
            if bg != .DoNotChange {
                cell.bg = bg
            }
            if style != .DoNotChange {
                cell.style = style
            }
            if cell.value == 0 {
                cell.value = ' '
            }
        }
    }
}
