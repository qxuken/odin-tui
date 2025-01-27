package main

import "clay"
import "core:fmt"
import "core:math"
import "core:strings"
import "tui:renderer"

clay_color_into_tui_color :: proc(color: clay.Color) -> renderer.RBG_Color {
    return renderer.RBG_Color{cast(int)color.r, cast(int)color.g, cast(int)color.b}
}

measure_text :: proc "c" (text: clay.StringSlice, config: ^clay.TextElementConfig, userData: uintptr) -> clay.Dimensions {
    wrap_mode := config.wrapMode
    // Measure string size for Font
    text_size: clay.Dimensions = {0, 1}

    max_text_width: f32 = 0
    line_text_width: f32 = 0

    col := 0
    for i in 0 ..< text.length {
        if text.chars[i] == '\n' {
            text_size.height += 1
            text_size.width = max(text_size.width, cast(f32)col)
            col = 0
        }
        col += 1
    }
    text_size.width = max(text_size.width, cast(f32)col)

    return text_size
}

clay_tui_render :: proc(r: ^renderer.Renderer, renderCommands: ^clay.ClayArray(clay.RenderCommand)) {
    for i in 0 ..< int(renderCommands.length) {
        renderCommand := clay.RenderCommandArray_Get(renderCommands, cast(i32)i)
        boundingBox := renderer.Insert_At {
            cast(int)math.round(renderCommand.boundingBox.x),
            cast(int)math.round(renderCommand.boundingBox.y),
            cast(int)math.round(renderCommand.boundingBox.width),
            cast(int)math.round(renderCommand.boundingBox.height),
        }
        switch (renderCommand.commandType) {
        case clay.RenderCommandType.Text:
            text := string(renderCommand.text.chars[:renderCommand.text.length])
            renderer.render_text(r, boundingBox, text, fg = clay_color_into_tui_color(renderCommand.config.textElementConfig.textColor))
        case clay.RenderCommandType.Rectangle:
            config: ^clay.RectangleElementConfig = renderCommand.config.rectangleElementConfig
            renderer.render_box(r, boundingBox, bg = clay_color_into_tui_color(config.color))
        case clay.RenderCommandType.Border:
            config := renderCommand.config.borderElementConfig
            renderer.render_border(
                r,
                boundingBox,
                {cast(int)config.top.width, cast(int)config.right.width, cast(int)config.bottom.width, cast(int)config.left.width},
                bg = clay_color_into_tui_color(config.left.color),
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

clay_command_tprint :: proc(render_commands: ^clay.ClayArray(clay.RenderCommand)) -> string {
    out := strings.builder_make(allocator = context.temp_allocator)
    for i in 0 ..< int(render_commands.length) {
        command := clay.RenderCommandArray_Get(render_commands, cast(i32)i)
        strings.write_string(&out, fmt.tprintfln("%#v", command^))
        switch (command.commandType) {
        case clay.RenderCommandType.Text:
            config: ^clay.TextElementConfig = command.config.textElementConfig
            strings.write_string(&out, fmt.tprintfln("text: %v", config^))
            strings.write_string(&out, fmt.tprintfln("text_content: %v", string(command.text.chars[:command.text.length])))
        case clay.RenderCommandType.Rectangle:
            config: ^clay.RectangleElementConfig = command.config.rectangleElementConfig
            strings.write_string(&out, fmt.tprintfln("rectangle: %v", config^))
        case clay.RenderCommandType.Border:
            config := command.config.borderElementConfig
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
