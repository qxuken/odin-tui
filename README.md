# Odin TUI

> Work in progress, but usable.

A small terminal user interface toolkit written in Odin. It fills the gap
`core` leaves for full-screen terminal programs:

- **`tui:term_sys`** – raw mode, alternate screen, mouse reporting, bracketed
  paste and focus events, with the terminal restored on exit, on panics, on
  fatal signals and around Ctrl-Z / `fg`.
- **`tui:events`** – a blocking `poll(timeout)` that turns terminal input into
  typed events: keys with modifiers, SGR mouse, resize, paste, focus.
- **`tui:renderer`** – a cell grid with text wrapping (grapheme aware, wide
  characters), boxes, borders, frames, scissors, colours and styles, serialised
  to one ANSI string per frame.

Supported: macOS, Linux, the BSDs (via `core:sys/posix`) and Windows 10+
(console API + virtual terminal sequences).

## The loop

There is no frame rate. The process sleeps inside `events.poll` until the user
does something or the window changes, then redraws once:

```odin
term_sys.init()
defer term_sys.shutdown()
context.assertion_failure_proc = term_sys.assertion_failure_proc
events.init()
defer events.destroy()

for running {
    size, _ := term_sys.get_size()
    renderer.clean_renderer_cycle(&ren, {size.cols, size.rows})
    // ... draw calls ...
    term_sys.push_begin_sync_update(&frame)
    term_sys.push_cursor_home(&frame)
    renderer.render_to_builder(&ren, &frame)
    term_sys.push_end_sync_update(&frame)
    term_sys.flush_builder(&frame)

    for evt in events.poll(events.FOREVER) {   // or a timeout for periodic redraws
        if events.is_char(evt, 'q') do running = false
    }
}
```

## Examples

| file                   | shows                                                     |
| ---------------------- | --------------------------------------------------------- |
| `examples/minimal.odin`| the smallest complete program                             |
| `examples/events.odin` | every decoded event, suspend/resume with Ctrl-Z            |
| `examples/full.odin`   | renderer features and a once-a-second clock via a timeout |

```bash
nu build.nu run-example minimal.odin --run
```

or without Nushell:

```bash
odin run examples/minimal.odin -file -collection:tui=./tui
```

## Tests

```bash
nu build.nu test
```

runs the input parser and text wrapping tests (`odin test` on each package).

## Requirements

- A recent Odin nightly (the `core:os` rewrite from 2026 is required)
- (optional) Nushell for `build.nu`

## Not done yet

- Kitty keyboard protocol (disambiguated modifiers for plain letters)
- Diffing frames instead of re-sending the whole grid
- Cursor positioning API for text input widgets
