package renderer

start_scissors :: proc(renderer: ^Renderer, bounds: InsertAt) {
    renderer.scissors = bounds
}

end_scissors :: proc(renderer: ^Renderer) {
    renderer.scissors = nil
}

scissor_bound_indicies :: proc(renderer: ^Renderer, insert: InsertAt) -> (row_start, row_end, col_start, col_end: int) {
    row_start = insert.y
    row_end   = insert.y + insert.height
    col_start = insert.x
    col_end   = insert.x + insert.width

    if scissors, ok := renderer.scissors.?; ok {
        row_start = max(row_start, scissors.y)
        row_end   = min(row_end, scissors.y + scissors.height)
        col_start = max(col_start, scissors.x)
        col_end   = min(col_end, scissors.x + scissors.width)
    }
    return
}
