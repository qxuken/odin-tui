package main

import "clay"
import "core:fmt"
import "core:math"
import "core:strings"
import "tui:renderer"

clayColorToTuiColor :: proc(color: clay.Color) -> renderer.RBGColor {
    return renderer.RBGColor{cast(int)color.r, cast(int)color.g, cast(int)color.b}
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
        boundingBox := renderer.InsertAt {
            cast(int)math.round(renderCommand.boundingBox.x),
            cast(int)math.round(renderCommand.boundingBox.y),
            cast(int)math.round(renderCommand.boundingBox.width),
            cast(int)math.round(renderCommand.boundingBox.height),
        }
        switch (renderCommand.commandType) {
        case clay.RenderCommandType.Text:
            text := string(renderCommand.text.chars[:renderCommand.text.length])
            renderer.render_text(r, boundingBox, text, fg = clayColorToTuiColor(renderCommand.config.textElementConfig.textColor))
        case clay.RenderCommandType.Rectangle:
            config: ^clay.RectangleElementConfig = renderCommand.config.rectangleElementConfig
            renderer.render_box(r, boundingBox, bg = clayColorToTuiColor(config.color))
        case clay.RenderCommandType.Border:
            config := renderCommand.config.borderElementConfig
            renderer.render_border(
                r,
                boundingBox,
                {cast(int)config.top.width, cast(int)config.right.width, cast(int)config.bottom.width, cast(int)config.left.width},
                bg = clayColorToTuiColor(config.left.color),
            )
        case clay.RenderCommandType.ScissorStart:
            renderer.start_scissors(r, boundingBox)
        case clay.RenderCommandType.ScissorEnd:
            renderer.end_scissors(r)
        case clay.RenderCommandType.Image:
        case clay.RenderCommandType.None:
        case clay.RenderCommandType.Custom:
            {}
        }
    }
}

clayCommandTPrint :: proc(renderCommands: ^clay.ClayArray(clay.RenderCommand)) -> string {
    out := strings.builder_make(allocator = context.temp_allocator)
    for i in 0 ..< int(renderCommands.length) {
        renderCommand := clay.RenderCommandArray_Get(renderCommands, cast(i32)i)
        strings.write_string(&out, fmt.tprintfln("%#v", renderCommand^))
        switch (renderCommand.commandType) {
        case clay.RenderCommandType.Text:
            config: ^clay.TextElementConfig = renderCommand.config.textElementConfig
            strings.write_string(&out, fmt.tprintfln("text: %v", config^))
            strings.write_string(&out, fmt.tprintfln("text_content: %v", string(renderCommand.text.chars[:renderCommand.text.length])))
        case clay.RenderCommandType.Rectangle:
            config: ^clay.RectangleElementConfig = renderCommand.config.rectangleElementConfig
            strings.write_string(&out, fmt.tprintfln("rectangle: %v", config^))
        case clay.RenderCommandType.Border:
            config := renderCommand.config.borderElementConfig
            strings.write_string(&out, fmt.tprintfln("text: %v", config^))
        case clay.RenderCommandType.ScissorStart:
            strings.write_string(&out, fmt.tprintfln("ScissorStart"))
        case clay.RenderCommandType.ScissorEnd:
            strings.write_string(&out, fmt.tprintfln("ScissorEnd"))
        case clay.RenderCommandType.Image:
            strings.write_string(&out, fmt.tprintfln("Image"))
        case clay.RenderCommandType.None:
            strings.write_string(&out, fmt.tprintfln("None"))
        case clay.RenderCommandType.Custom:
            strings.write_string(&out, fmt.tprintfln("Custom"))
        }
    }
    return strings.to_string(out)
}
