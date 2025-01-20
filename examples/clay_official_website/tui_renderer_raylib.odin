package main

import "clay"
import "core:math"
import "core:strings"
import "tui:renderer"

clayColorToTuiColor :: proc(color: clay.Color) -> renderer.RBGColor {
    return renderer.RBGColor{color.r, color.g, color.b}
}

measureText :: proc "c" (text: clay.StringSlice, config: ^clay.TextElementConfig, userData: uintptr) -> clay.Dimensions {
    // Measure string size for Font
    textSize: clay.Dimensions = {0, 1}

    maxTextWidth: f32 = 0
    lineTextWidth: f32 = 0

    col := 0
    for i in 0 ..< text.length {
        if text.chars[i] == '\n' {
            textSize.height += 1
            textSize.width = max(textSize.width, cast(f32)col)
            col = 0
        }
        col += 1
    }
    textSize.width = max(textSize.width, cast(f32)col)

    return textSize
}

clayTuiRender :: proc(r: ^renderer.Renderer, renderCommands: ^clay.ClayArray(clay.RenderCommand)) {
    for i in 0 ..< int(renderCommands.length) {
        renderCommand := clay.RenderCommandArray_Get(renderCommands, cast(i32)i)
        boundingBox := renderCommand.boundingBox
        switch (renderCommand.commandType) {
        case clay.RenderCommandType.Text:
            text := string(renderCommand.text.chars[:renderCommand.text.length])
            renderer.render_text(
                r,
                {cast(int)boundingBox.x, cast(int)boundingBox.y, cast(int)boundingBox.width, cast(int)boundingBox.height},
                text,
                fg = clayColorToTuiColor(renderCommand.config.textElementConfig.textColor),
            )
        case clay.RenderCommandType.Rectangle:
            config: ^clay.RectangleElementConfig = renderCommand.config.rectangleElementConfig
            renderer.render_box(
                r,
                {cast(int)boundingBox.x, cast(int)boundingBox.y, cast(int)boundingBox.width, cast(int)boundingBox.height},
                bg = clayColorToTuiColor(config.color),
            )
        case clay.RenderCommandType.Border:
        case clay.RenderCommandType.ScissorStart:
        case clay.RenderCommandType.ScissorEnd:
        case clay.RenderCommandType.Image:
        case clay.RenderCommandType.None:
        case clay.RenderCommandType.Custom:
            {}
        }
    }
}
