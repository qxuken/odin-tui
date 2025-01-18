package renderer

import "base:runtime"
import "core:mem/virtual"

Coord :: [2]int
Bounds :: [2]int

Cell :: struct {
	fg:    Color,
	bg:    Color,
	style: Style,
	// NOTE: Add graphemes
	value: rune,
}

Renderer :: struct {
	state:  [dynamic]Cell,
	bounds: Bounds,
	arena:  virtual.Arena,
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
