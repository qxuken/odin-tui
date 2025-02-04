package renderer

import "base:runtime"
import "core:fmt"
import "core:mem/virtual"
import "core:unicode/utf8"
import "tui:utils"

DEBUG_TEXT_RENDERING :: #config(DEBUG_TEXT_RENDERING, false)
TAB_SIZE :: 4
when DEBUG_TEXT_RENDERING {
    TAB_CHAR :: '»'
    NEW_LINE_CHAR :: ''
} else {
    TAB_CHAR :: ' '
    NEW_LINE_CHAR :: ' '
}

Wrap_Mode :: enum {
    Word,
    Line,
    None,
}

wrap_text :: proc(text: string, bounds: Bounds, mode := Wrap_Mode.Word, allocator: runtime.Allocator) -> []Text_Data_Value {
    cells_count := bounds.x * bounds.y
    res := make([dynamic]Text_Data_Value, cells_count, allocator = allocator)

    graphemes, graphemes_count, rune_count, width := utf8.decode_grapheme_clusters(text, allocator = allocator)
    switch mode {
    case .None:
        i := 0
        for grapheme in graphemes {
            if i >= min(bounds.x, cells_count) {
                break
            }
            switch grapheme.width {
            case 2 ..< max(int):
                res[i] = transmute([]u8)text[grapheme.byte_index:][:grapheme.width]
                i += 1
            case 0:
            case 1:
                r := cast(rune)text[grapheme.byte_index]
                switch r {
                case '\n':
                    res[i] = NEW_LINE_CHAR
                    i += 1
                case '\t':
                    for ti in i ..< min(i + TAB_SIZE, cells_count) {
                        res[ti] = TAB_CHAR
                    }
                    i += TAB_SIZE
                case:
                    res[i] = r
                    i += 1
                }
            case min(int) ..< 0:
                fmt.panicf("Grapheme error(#%v):%v", i, grapheme)
            }
        }

    case .Line:
        row := 0
        col := 0
        line_loop: for r, i in text {
            if r == '\n' {
                if col < bounds.x {
                    ti := utils.tranform_2d_index(bounds.x, row, col)
                    if ti >= cells_count {
                        break line_loop
                    }
                    res[ti] = NEW_LINE_CHAR
                }
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
                    if ti >= cells_count {
                        break line_loop
                    }
                    res[ti] = TAB_CHAR
                }
                col += TAB_SIZE
            case:
                ri := utils.tranform_2d_index(bounds.x, row, col)
                if ri >= cells_count {
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
                    if ti >= cells_count {
                        break word_loop
                    }
                    res[ti] = utf8.rune_at(text, li)
                    if li + 1 != i && col + 1 >= bounds.x {
                        if bounds.x > 1 {
                            ti := utils.tranform_2d_index(bounds.x, row, col)
                            if ti >= cells_count {
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
                    if col < bounds.x {
                        ti := utils.tranform_2d_index(bounds.x, row, col)
                        if ti >= cells_count {
                            break word_loop
                        }
                        res[ti] = NEW_LINE_CHAR
                    }
                    row += 1
                    col = 0
                case '\t':
                    for _ in 0 ..< TAB_SIZE {
                        if col >= bounds.x {
                            break
                        }
                        ti := utils.tranform_2d_index(bounds.x, row, col)
                        if ti >= cells_count {
                            break word_loop
                        }
                        res[ti] = TAB_CHAR
                        col += 1
                    }
                case ' ':
                    if col >= bounds.x {
                        row += 1
                        col = 0
                    }
                    ti := utils.tranform_2d_index(bounds.x, row, col)
                    if ti >= cells_count {
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
                if ti >= cells_count {
                    break
                }
                res[ti] = utf8.rune_at(text, li)
                if li + 1 != len(text) && col + 1 >= bounds.x {
                    if bounds.x > 1 {
                        ti := utils.tranform_2d_index(bounds.x, row, col)
                        if ti >= cells_count {
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
