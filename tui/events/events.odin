// Package events turns terminal input into a stream of typed events.
//
// The only entry point an application needs is `poll`, which blocks until at
// least one event is available or the timeout expires:
//
//     for running {
//         for evt in events.poll(events.FOREVER) {
//             switch e in evt { ... }
//         }
//         redraw()
//     }
//
// Blocking with `FOREVER` means the process sleeps until the user does
// something or the window is resized; pass a timeout when the UI also needs
// periodic updates (a clock, an animation, a progress bar).
package events

import "core:time"

FOREVER :: time.Duration(-1)

Key_Code :: enum {
    Char, // `Key.char` holds the character
    Enter,
    Tab,
    Backspace,
    Escape,
    Up,
    Down,
    Left,
    Right,
    Home,
    End,
    Page_Up,
    Page_Down,
    Insert,
    Delete,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
}

Modifier :: enum {
    Shift,
    Ctrl,
    Alt,
}
Modifiers :: bit_set[Modifier]

Key :: struct {
    code: Key_Code,
    char: rune, // only meaningful for `.Char`
    mods: Modifiers,
}

Mouse_Button :: enum {
    None,
    Left,
    Middle,
    Right,
    Wheel_Up,
    Wheel_Down,
    Wheel_Left,
    Wheel_Right,
}

Mouse_Action :: enum {
    Press,
    Release,
    Drag, // motion with a button held
    Move, // motion with no button held
    Scroll, // `button` is one of the `Wheel_*` values
}

Mouse :: struct {
    action: Mouse_Action,
    button: Mouse_Button,
    col:    int, // zero based
    row:    int, // zero based
    mods:   Modifiers,
}

Resize :: struct {
    cols: int,
    rows: int,
}

// Text inserted with bracketed paste. `text` is allocated with the allocator
// passed to `poll`.
Paste :: struct {
    text: string,
}

Focus :: struct {
    gained: bool,
}

// Input that could not be decoded. `raw` is allocated with the allocator
// passed to `poll`.
Unknown :: struct {
    raw: string,
}

Event :: union #no_nil {
    Unknown,
    Key,
    Mouse,
    Resize,
    Paste,
    Focus,
}

// Prepares the input source. Call after `term_sys.init`.
init :: proc() -> bool {
    return _init()
}

destroy :: proc() {
    _destroy()
}

// Waits up to `timeout` for input and returns every event that is available.
// A negative timeout (`FOREVER`) blocks until something happens, zero returns
// immediately. The returned slice, and any strings inside it, are allocated
// with `allocator`.
poll :: proc(timeout := FOREVER, allocator := context.temp_allocator) -> []Event {
    return _poll(timeout, allocator)
}

// True when `evt` is the given key with exactly the given modifiers.
is_key :: proc(evt: Event, code: Key_Code, mods: Modifiers = {}) -> bool {
    k, ok := evt.(Key)
    return ok && k.code == code && k.mods == mods
}

// True when `evt` is the character `r` with exactly the given modifiers.
is_char :: proc(evt: Event, r: rune, mods: Modifiers = {}) -> bool {
    k, ok := evt.(Key)
    return ok && k.code == .Char && k.char == r && k.mods == mods
}
