package utils

tranform_2d_index :: #force_inline proc(columns, r, c: int) -> int {
    return r * columns + c
}
