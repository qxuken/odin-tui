package utils

tranform_2d_index :: proc(columns, r, c: int) -> int {
	return r * columns + c
}
