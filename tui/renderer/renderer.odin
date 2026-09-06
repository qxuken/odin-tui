// Package renderer is a cell grid that is filled by draw calls and then
// serialised to ANSI escape sequences once per frame.
package renderer

import "core:mem/virtual"

Coord :: [2]int
Bounds :: [2]int // x = columns, y = rows
Insert_At :: struct {
    x, y:          int,
    width, height: int,
}

// Bytes of a multi-rune grapheme cluster (an emoji with modifiers, a flag, ...).
Grapheme_Value :: []u8

// Marks the second cell of a two-cell wide character; nothing is emitted for it.
Wide_Continuation :: struct {}

Text_Data_Value :: union #no_nil {
    rune, // 0 means "no text"
    Grapheme_Value,
    Wide_Continuation,
}
Text_Data :: struct {
    value: Text_Data_Value,
}
Cell_Data :: union {
    Text_Data,
}
Cell :: struct {
    fg:    Color,
    bg:    Color,
    style: Maybe(Style),
    data:  Cell_Data,
}

Renderer :: struct {
    state:    []Cell,
    bounds:   Bounds,
    arena:    virtual.Arena, // frame allocator, reset by `clean_renderer_cycle`
    scissors: Maybe(Insert_At),
}

make_renderer :: proc(bounds: Bounds) -> Renderer {
    arena: virtual.Arena
    err := virtual.arena_init_growing(&arena)
    ensure(err == .None)
    arena_allocator := virtual.arena_allocator(&arena)
    state := make([]Cell, bounds.x * bounds.y, allocator = arena_allocator)
    return {state, bounds, arena, nil}
}

// Starts a new frame: drops everything allocated during the previous one and
// resizes the grid to `bounds`.
clean_renderer_cycle :: proc(renderer: ^Renderer, bounds: Bounds) {
    virtual.arena_free_all(&renderer.arena)
    arena_allocator := virtual.arena_allocator(&renderer.arena)
    renderer.bounds = bounds
    renderer.scissors = nil
    renderer.state = make([]Cell, bounds.x * bounds.y, allocator = arena_allocator)
}

destroy_renderer :: proc(renderer: ^Renderer) {
    virtual.arena_destroy(&renderer.arena)
}
