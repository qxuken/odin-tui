package renderer

import "core:unicode/utf8"
import "tui:utils"

render_box :: proc(renderer: ^Renderer, insert: InsertAt, bg: Color = .DoNotChange, style: Style = .DoNotChange) {
    for row in insert.y ..< insert.y + insert.height {
        for col in insert.x ..< insert.x + insert.width {
            modify_cell(renderer, row, col, bg = bg, style = style)
        }
    }
}
