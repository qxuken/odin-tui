package renderer

import "base:runtime"
import "core:mem/virtual"
import "tui:utils"

Coord :: [2]int
Bounds :: [2]int
Insert_At :: struct {
    x, y:          int,
    width, height: int,
}

Ascii_Border_Data :: struct {
    rounded: bool,
}

Grapheme_Value :: []u8
Text_Data_Value :: union #no_nil {
    rune,
    Grapheme_Value,
}
Text_Data :: struct {
    value: Text_Data_Value,
}
Cell_Data :: union {
    Ascii_Border_Data,
    Text_Data,
}
Cell :: struct {
    fg:    Color,
    bg:    Color,
    style: Maybe(Style),
    data:  Cell_Data,
}

Renderer :: struct {
    state:    [dynamic]Cell,
    bounds:   Bounds,
    arena:    virtual.Arena,
    scissors: Maybe(Insert_At),
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
