package renderer

import "base:runtime"
import "core:mem/virtual"
import "tui:utils"

Coord :: [2]int
Bounds :: [2]int
InsertAt :: struct {
    x, y:          int,
    width, height: int,
}

Cell :: struct {
    fg:    Color,
    bg:    Color,
    style: Style,
    // TODO: Add graphemes
    value: rune,
}

// TODO: Check if there more efficient buffer on windows
Renderer :: struct {
    state:  [dynamic]Cell,
    bounds: Bounds,
    arena:  virtual.Arena,
}

modify_cell :: proc(r: ^Renderer, row, col: int, value := ' ', fg: Color = .DoNotChange, bg: Color = .DoNotChange, style: Style = .DoNotChange) -> bool {
    i := utils.tranform_2d_index(r.bounds.x, row, col)
    if 0 > i || i >= len(r.state) {
        return false
    }
    cell := &r.state[i]
    if fg != .DoNotChange {
        cell.fg = fg
    }
    if bg != .DoNotChange {
        cell.bg = bg
    }
    if style != .DoNotChange {
        cell.style = style
    }
    cell.value = value
    return true
}

make_renderer :: proc(bounds: Bounds) -> Renderer {
    arena: virtual.Arena
    err := virtual.arena_init_growing(&arena)
    assert(err == .None)
    arena_allocator := virtual.arena_allocator(&arena)
    state := make([dynamic]Cell, bounds.x * bounds.y, allocator = arena_allocator)
    return {state, bounds, arena}
}

clean_renderer_cycle :: proc(renderer: ^Renderer, bounds: Bounds) {
    virtual.arena_free_all(&renderer.arena)
    arena_allocator := virtual.arena_allocator(&renderer.arena)
    renderer.bounds = bounds
    renderer.state = make([dynamic]Cell, bounds.x * bounds.y, allocator = arena_allocator)
}

destroy_renderer :: proc(renderer: ^Renderer) {
    virtual.arena_destroy(&renderer.arena)
}
