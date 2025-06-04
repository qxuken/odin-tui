# Odin TUI

> ## Library very much in a WIP state

A terminal user interface (TUI) library written in Odin, designed to provide basic building blocks for creating terminal applications.

## Overview

Odin TUI is a library that provides fundamental components and utilities for building terminal-based applications. It offers a clean and intuitive API for creating interactive terminal interfaces while maintaining the simplicity and performance that Odin is known for.

## Features

- Basic terminal UI building blocks
- Simple and intuitive API
- Written in pure Odin

## Examples

The project includes several examples demonstrating different aspects of the library, look into `examples/`. There is even example with a clay library.

## Requirements

- Odin compiler
- (optional) Nushell

## Building example

```bash
nu build.nu run-example <example_name>
```

## TODO

- [ ] Handling UTF-8 Graphemes
- [ ] Parsing inputs in Windows ConEmu environment, Wezterm and Iterm on Mac and Linux
- [ ] Ensuring compatibility with thread pools
