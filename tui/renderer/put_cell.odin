package renderer

import "tui:utils"

@(private)
cell_at :: #force_inline proc(r: ^Renderer, row, col: int) -> ^Cell {
    if row < 0 || col < 0 || row >= r.bounds.y || col >= r.bounds.x {
        return nil
    }
    return &r.state[utils.tranform_2d_index(r.bounds.x, row, col)]
}

put_cell :: proc(r: ^Renderer, row, col: int, cell: Cell) -> bool {
    target := cell_at(r, row, col)
    if target == nil {
        return false
    }
    target^ = cell
    return true
}

put_text_cell :: proc(r: ^Renderer, row, col: int, data: Text_Data_Value, fg: Maybe(Color) = nil, bg: Maybe(Color) = nil, style: Maybe(Style) = nil) -> bool {
    cell := cell_at(r, row, col)
    if cell == nil {
        return false
    }
    if v, ok := fg.?; ok {
        cell.fg = v
    }
    if v, ok := bg.?; ok {
        cell.bg = v
    }
    if v, ok := style.?; ok {
        cell.style = v
    }
    switch v in data {
    case rune:
        if v != 0 {
            cell.data = Text_Data{data}
        }
    case Grapheme_Value, Wide_Continuation:
        cell.data = Text_Data{data}
    }
    return true
}
