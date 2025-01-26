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

AsciiBorderData :: struct {
    rounded: bool,
}
TextData :: struct {
    // TODO: add []u8 variant for graphemes
    value: rune,
}
CellData :: union {
    AsciiBorderData,
    TextData,
}
Cell :: struct {
    fg:    Color,
    bg:    Color,
    style: Maybe(Style),
    data:  CellData,
}

Renderer :: struct {
    state:    [dynamic]Cell,
    bounds:   Bounds,
    arena:    virtual.Arena,
    scissors: Maybe(InsertAt),
}

make_renderer :: proc(bounds: Bounds) -> Renderer {
    arena: virtual.Arena
    err := virtual.arena_init_growing(&arena)
    ensure(err == .None)
    arena_allocator := virtual.arena_allocator(&arena)
    state := make([dynamic]Cell, bounds.x * bounds.y, allocator = arena_allocator)
    return {state, bounds, arena, nil}
}

clean_renderer_cycle :: proc(renderer: ^Renderer, bounds: Bounds) {
    virtual.arena_free_all(&renderer.arena)
    arena_allocator := virtual.arena_allocator(&renderer.arena)
    renderer.bounds = bounds
    renderer.scissors = nil
    renderer.state = make([dynamic]Cell, bounds.x * bounds.y, allocator = arena_allocator)
}

destroy_renderer :: proc(renderer: ^Renderer) {
    virtual.arena_destroy(&renderer.arena)
}
