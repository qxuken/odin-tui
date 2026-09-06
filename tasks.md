ToDo:
- [ ] Kitty keyboard protocol (CSI u) for Shift/Ctrl on plain letters
- [ ] Frame diffing in the renderer (only send changed cells)
- [ ] Cursor position / show cursor API for text inputs
- [ ] Over SSH example?
- [ ] Verify Windows backend on a real console (only cross-checked with `odin check -target:windows_amd64`)

Done:
- [x] Basic renderer
- [x] App initializer with guaranteed restore (exit, panic, signals, Ctrl-Z)
- [x] Blocking event loop with timeout instead of a fixed frame rate
- [x] Cross platform terminal events (keys with modifiers, SGR mouse, resize, paste, focus)
- [x] Word wrapping with graphemes and wide characters
- [x] Box drawing frames
- [x] Rendering example, events example, minimal example
- [x] Rendering performance on macOS/Linux (erase-to-eol instead of full clears, direct writes)
- [x] Alternate mode enter/exit leaves the shell untouched
