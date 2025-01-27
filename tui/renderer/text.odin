package renderer

import "base:runtime"
import "core:mem/virtual"
import "core:unicode/utf8"
import "tui:utils"

Wrap_Mode :: enum {
    Word,
    Line,
    None,
}

// TODO: Propper word splits
wrap_text :: proc(text: string, bounds: Bounds, mode := Wrap_Mode.Word, allocator: runtime.Allocator) -> []rune {
    runes_count := bounds.x * bounds.y
    res := make([dynamic]rune, runes_count, allocator = allocator)
    switch mode {
    case .None:
        for r, i in text {
            if i >= bounds.x || i >= runes_count {
                break
            }
            res[i] = r
        }
    case .Line:
        row := 0
        col := 0

        for r, i in text {
            if r == '\n' {
                row += 1
                col = 0
                continue
            }
            if col >= bounds.x {
                continue
            }
            ri := utils.tranform_2d_index(bounds.x, row, col)
            if ri >= runes_count {
                break
            }
            res[ri] = r
            col += 1
        }
    case .Word:
        row := 0
        col := 0
        word_start := -1
        word_loop: for r, i in text {
            if (r == ' ' || r == '\n' || r == '\t') {
                if word_start > 0 {
                    word_len := i - word_start
                    remaining_len := bounds.x - col
                    if word_len > remaining_len && word_len <= bounds.x {
                        row += 1
                        col = 0
                    }
                    for wi in word_start ..< i {
                        if wi > 0 && wi % bounds.x == 0 {
                            row += 1
                            col = 0
                        }
                        ri := utils.tranform_2d_index(bounds.x, row, col)
                        if ri >= runes_count {
                            break word_loop
                        }
                        res[ri] = r
                        col += 1
                    }
                    word_start = -1
                } else {
                    if i > 0 && i % bounds.x == 0 {
                        row += 1
                        col = 0
                    }
                    ri := utils.tranform_2d_index(bounds.x, row, col)
                    if ri >= runes_count {
                        break word_loop
                    }
                    res[ri] = r
                    col += 1
                }
            } else if word_start == -1 {
                word_start = i
            }
        }
        for r, i in text[word_start:] {
            if i > 0 && i % bounds.x == 0 {
                row += 1
                col = 0
            }
            ri := utils.tranform_2d_index(bounds.x, row, col)
            if ri >= runes_count {
                break
            }
            res[ri] = r
            col += 1
        }
    }
    return res[:]
}

render_text :: proc(renderer: ^Renderer, insert: Insert_At, text: string, mode := Wrap_Mode.Word, fg: Maybe(Color) = nil, bg: Maybe(Color) = nil, style: Maybe(Style) = nil) {
    arena_allocator := virtual.arena_allocator(&renderer.arena)
    wrapped := wrap_text(text, {insert.width, insert.height}, mode, allocator = arena_allocator)

    row_start, row_end, col_start, col_end := scissor_bound_indicies(renderer, insert)

    for row in row_start ..< row_end {
        for col in col_start ..< col_end {
            wi := utils.tranform_2d_index(insert.width, row - insert.y, col - insert.x)
            put_text_cell(renderer, row, col, wrapped[wi], fg, bg, style)
        }
    }
}
