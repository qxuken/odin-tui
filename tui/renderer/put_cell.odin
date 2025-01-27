package renderer

import "tui:utils"

put_cell :: proc(r: ^Renderer, row, col: int, cell: Cell) -> bool {
    i := utils.tranform_2d_index(r.bounds.x, row, col)
    if 0 > i || i >= len(r.state) {
        return false
    }
    r.state[i] = cell
    return true
}

put_text_cell :: proc(r: ^Renderer, row, col: int, data: rune, fg: Maybe(Color) = nil, bg: Maybe(Color) = nil, style: Maybe(Style) = nil) -> bool {
    i := utils.tranform_2d_index(r.bounds.x, row, col)
    if 0 > i || i >= len(r.state) {
        return false
    }
    cell := &r.state[i]
    if v, ok := fg.?; ok {
        cell.fg = v
    }
    if v, ok := bg.?; ok {
        cell.bg = v
    }
    if v, ok := style.?; ok {
        cell.style = v
    }
    if data != 0 {
        cell.data = TextData{data}
    }
    return true
}
