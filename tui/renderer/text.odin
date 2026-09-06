package renderer

import "base:runtime"
import "core:mem/virtual"
import "core:unicode/utf8"
import "tui:utils"

DEBUG_TEXT_RENDERING :: #config(DEBUG_TEXT_RENDERING, false)
TAB_SIZE :: 4
when DEBUG_TEXT_RENDERING {
    TAB_CHAR :: '»'
    NEW_LINE_CHAR :: '¶'
} else {
    TAB_CHAR :: ' '
    NEW_LINE_CHAR :: ' '
}

Wrap_Mode :: enum {
    Word, // break lines between words, hyphenate words wider than a line
    Line, // break lines only at "\n", clip the rest
    None, // single line, "\n" is rendered as a space
}

@(private = "file")
Token_Kind :: enum {
    Glyph,
    Space,
    Tab,
    Newline,
}

@(private = "file")
Token :: struct {
    kind:  Token_Kind,
    value: Text_Data_Value,
    width: int, // cells taken on screen: 1 or 2
}

@(private = "file")
Layout :: struct {
    cells:  []Text_Data_Value,
    bounds: Bounds,
    row:    int,
    col:    int,
}

@(private = "file")
tokenize :: proc(text: string, allocator: runtime.Allocator) -> []Token {
    tokens := make([dynamic]Token, 0, len(text), allocator)
    it := utf8.decode_grapheme_iterator_make(text)
    for cluster, grapheme in utf8.decode_grapheme_iterate(&it) {
        switch cluster {
        case "\n", "\r\n":
            append(&tokens, Token{kind = .Newline, width = 1})
        case "\r":
        case "\t":
            append(&tokens, Token{kind = .Tab, width = 1})
        case " ":
            append(&tokens, Token{kind = .Space, value = ' ', width = 1})
        case:
            if grapheme.width <= 0 {
                continue // zero width: control characters, lone combining marks
            }
            tok := Token{kind = .Glyph, width = min(grapheme.width, 2)}
            r, size := utf8.decode_rune_in_string(cluster)
            if size == len(cluster) {
                tok.value = r
            } else {
                tok.value = transmute(Grapheme_Value)cluster
            }
            append(&tokens, tok)
        }
    }
    return tokens[:]
}

@(private = "file")
layout_put :: proc(l: ^Layout, tok: Token) -> bool {
    if l.row >= l.bounds.y || l.col + tok.width > l.bounds.x {
        return false
    }
    i := utils.tranform_2d_index(l.bounds.x, l.row, l.col)
    l.cells[i] = tok.value
    if tok.width == 2 {
        l.cells[i + 1] = Wide_Continuation{}
    }
    l.col += tok.width
    return true
}

@(private = "file")
layout_newline :: proc(l: ^Layout) {
    l.row += 1
    l.col = 0
}

@(private = "file")
layout_tab :: proc(l: ^Layout) {
    for _ in 0 ..< TAB_SIZE {
        if !layout_put(l, Token{value = TAB_CHAR, width = 1}) {
            break
        }
    }
}

// Lays `text` out into a `bounds.x * bounds.y` grid of cells. Cells that
// receive no text hold the zero rune.
wrap_text :: proc(text: string, bounds: Bounds, mode := Wrap_Mode.Word, allocator: runtime.Allocator) -> []Text_Data_Value {
    l := Layout {
        cells  = make([]Text_Data_Value, bounds.x * bounds.y, allocator),
        bounds = bounds,
    }
    if bounds.x <= 0 || bounds.y <= 0 {
        return l.cells
    }
    tokens := tokenize(text, allocator)

    switch mode {
    case .None:
        for tok in tokens {
            switch tok.kind {
            case .Glyph, .Space:
                layout_put(&l, tok)
            case .Newline:
                layout_put(&l, Token{value = NEW_LINE_CHAR, width = 1})
            case .Tab:
                layout_tab(&l)
            }
            if l.col >= bounds.x {
                break
            }
        }

    case .Line:
        for tok in tokens {
            if l.row >= bounds.y {
                break
            }
            switch tok.kind {
            case .Glyph, .Space:
                layout_put(&l, tok)
            case .Newline:
                layout_put(&l, Token{value = NEW_LINE_CHAR, width = 1})
                layout_newline(&l)
            case .Tab:
                layout_tab(&l)
            }
        }

    case .Word:
        i := 0
        for i < len(tokens) && l.row < bounds.y {
            tok := tokens[i]
            switch tok.kind {
            case .Newline:
                layout_put(&l, Token{value = NEW_LINE_CHAR, width = 1})
                layout_newline(&l)
                i += 1
            case .Tab:
                layout_tab(&l)
                i += 1
            case .Space:
                // Spaces that do not fit are swallowed by the line break.
                layout_put(&l, tok)
                i += 1
            case .Glyph:
                // Measure the word.
                end := i
                word_width := 0
                for end < len(tokens) && tokens[end].kind == .Glyph {
                    word_width += tokens[end].width
                    end += 1
                }
                if l.col + word_width > bounds.x && word_width <= bounds.x && l.col > 0 {
                    layout_newline(&l)
                }
                for j in i ..< end {
                    if l.row >= bounds.y {
                        break
                    }
                    g := tokens[j]
                    if l.col + g.width > bounds.x {
                        // Word wider than a line: replace the last glyph with a
                        // hyphen and carry that glyph over to the next line.
                        prev := tokens[max(j - 1, 0)]
                        if j > i && l.col > 0 && prev.width == 1 && prev.width + g.width < bounds.x {
                            l.col -= 1
                            layout_put(&l, Token{value = '-', width = 1})
                            layout_newline(&l)
                            layout_put(&l, prev)
                        } else {
                            layout_newline(&l)
                        }
                    }
                    layout_put(&l, g)
                }
                i = end
            }
        }
    }

    return l.cells
}

render_text :: proc(renderer: ^Renderer, insert: Insert_At, text: string, mode := Wrap_Mode.Word, fg: Maybe(Color) = nil, bg: Maybe(Color) = nil, style: Maybe(Style) = nil) {
    if insert.width <= 0 || insert.height <= 0 {
        return
    }
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
