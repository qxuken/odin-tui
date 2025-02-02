package renderer

import "base:runtime"
import "core:mem/virtual"
import "core:unicode/utf8"
import "tui:utils"

TAB_SIZE :: #config(TAB_SIZE, 4)

Wrap_Mode :: enum {
    Word,
    Line,
    None,
}

wrap_text :: proc(text: string, bounds: Bounds, mode := Wrap_Mode.Word, allocator: runtime.Allocator) -> []rune {
    runes_count := bounds.x * bounds.y
    res := make([dynamic]rune, runes_count, allocator = allocator)

    switch mode {
    case .None:
        i := 0
        for r in text {
            if i >= min(bounds.x, runes_count) {
                break
            }
            switch r {
            case '\n':
                res[i] = ' '
                i += 1
            case '\t':
                for ti in i ..< min(i + TAB_SIZE, runes_count) {
                    res[ti] = ' '
                }
                i += TAB_SIZE - 1
            case:
                res[i] = r
                i += 1
            }
        }

    case .Line:
        row := 0
        col := 0
        line_loop: for r, i in text {
            if r == '\n' {
                row += 1
                col = 0
                continue
            }
            if col >= bounds.x {
                continue
            }
            switch r {
            case '\t':
                for lcol in col ..< min(col + TAB_SIZE, bounds.x) {
                    ti := utils.tranform_2d_index(bounds.x, row, lcol)
                    if ti >= runes_count {
                        break line_loop
                    }
                    res[ti] = ' '
                }
                col += TAB_SIZE - 1
            case:
                ri := utils.tranform_2d_index(bounds.x, row, col)
                if ri >= runes_count {
                    break
                }
                res[ri] = r
                col += 1
            }
        }

    case .Word:
        row := 0
        col := 0
        word_start := -1
        // graphemes, graphemes_count, rune_count, width := utf8.decode_grapheme_clusters(text, allocator = allocator)
        word_loop: for r, i in text {
            space_symbol := r == ' ' || r == '\n' || r == '\t'
            switch {
            case !space_symbol && word_start == -1:
                word_start = i
            case space_symbol && word_start != -1:
                word_len := i - word_start
                if word_len <= bounds.x && word_len > bounds.x - col {
                    row += 1
                    col = 0
                }
                for li in word_start ..< i {
                    ti := utils.tranform_2d_index(bounds.x, row, col)
                    if ti >= runes_count {
                        break word_loop
                    }
                    res[ti] = utf8.rune_at(text, li)
                    if li + 1 != i && col + 1 >= bounds.x {
                        if bounds.x > 1 {
                            ti := utils.tranform_2d_index(bounds.x, row, col)
                            if ti >= runes_count {
                                break
                            }
                            res[ti] = '-'
                        }
                        row += 1
                        col = 0
                    } else {
                        col += 1
                    }
                }
                word_start = -1
                fallthrough
            case space_symbol && word_start == -1:
                switch r {
                case '\n':
                    row += 1
                    col = 0
                case '\t':
                    for _ in 0 ..< TAB_SIZE {
                        if col >= bounds.x {
                            break
                        }
                        ti := utils.tranform_2d_index(bounds.x, row, col)
                        if ti >= runes_count {
                            break word_loop
                        }
                        res[ti] = ' '
                        col += 1
                    }
                case ' ':
                    if col >= bounds.x {
                        row += 1
                        col = 0
                    }
                    ti := utils.tranform_2d_index(bounds.x, row, col)
                    if ti >= runes_count {
                        break word_loop
                    }
                    res[ti] = ' '
                    col += 1
                }
            }
        }
        if word_start != -1 {
            word_len := len(text) - word_start
            if word_len <= bounds.x && word_len > bounds.x - col {
                row += 1
                col = 0
            }
            for li in word_start ..< len(text) {
                ti := utils.tranform_2d_index(bounds.x, row, col)
                if ti >= runes_count {
                    break
                }
                res[ti] = utf8.rune_at(text, li)
                if li + 1 != len(text) && col + 1 >= bounds.x {
                    if bounds.x > 1 {
                        ti := utils.tranform_2d_index(bounds.x, row, col)
                        if ti >= runes_count {
                            break
                        }
                        res[ti] = '-'
                    }
                    row += 1
                    col = 0
                } else {
                    col += 1
                }
            }
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
