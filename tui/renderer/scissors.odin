package renderer

start_scissors :: proc(renderer: ^Renderer, bounds: InsertAt) {
    renderer.scissors = bounds
}

end_scissors :: proc(renderer: ^Renderer) {
    renderer.scissors = nil
}

scissor_bound_indicies :: #force_inline proc(renderer: ^Renderer, insert: InsertAt) -> (row_start, row_end, col_start, col_end: int) {
    row_start = insert.y
    col_start = insert.x
    row_end = insert.y + insert.height
    col_end = insert.x + insert.width

    if scissors, ok := renderer.scissors.?; ok {
        row_start = max(row_start, scissors.y)
        col_start = max(col_start, scissors.x)
        row_end = min(row_end, scissors.y + scissors.height)
        col_end = min(col_end, scissors.x + scissors.width)
    }
    return
}
