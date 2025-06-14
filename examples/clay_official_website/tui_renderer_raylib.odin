package main

import "clay"
import "core:fmt"
import "core:math"
import "core:strings"
import "tui:renderer"

clay_color_into_tui_color :: proc(color: clay.Color) -> renderer.RBG_Color {
    return renderer.RBG_Color{cast(int)color.r, cast(int)color.g, cast(int)color.b}
}

measure_text :: proc "c" (text: clay.StringSlice, config: ^clay.TextElementConfig, userData: rawptr) -> clay.Dimensions {
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

clay_tui_render :: proc(r: ^renderer.Renderer, render_commands: ^clay.ClayArray(clay.RenderCommand)) {
    for i in 0 ..< int(render_commands.length) {
        render_command := clay.RenderCommandArray_Get(render_commands, cast(i32)i)
        bounding_box := renderer.Insert_At {
            cast(int)math.round(render_command.boundingBox.x),
            cast(int)math.round(render_command.boundingBox.y),
            cast(int)math.round(render_command.boundingBox.width),
            cast(int)math.round(render_command.boundingBox.height),
        }
        switch render_command.commandType {
        case .Text:
            config := render_command.renderData.text
            text := string(config.stringContents.chars[:config.stringContents.length])
            renderer.render_text(r, bounding_box, text, fg = clay_color_into_tui_color(config.textColor))
        case .Rectangle:
            config := render_command.renderData.rectangle
            renderer.render_box(r, bounding_box, bg = clay_color_into_tui_color(config.backgroundColor))
        case .Border:
            config := render_command.renderData.border
            renderer.render_border(
                r,
                bounding_box,
                {cast(int)config.width.top, cast(int)config.width.right, cast(int)config.width.bottom, cast(int)config.width.left},
                bg = clay_color_into_tui_color(config.color),
            )
        case .ScissorStart:
            renderer.start_scissors(r, bounding_box)
        case .ScissorEnd:
            renderer.end_scissors(r)
        case .Image:
        case .None:
        case .Custom:
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
        case .Text:
            config := command.renderData.text
            strings.write_string(&out, fmt.tprintfln("text: %v", config))
            strings.write_string(&out, fmt.tprintfln("text_content: %v", string(config.stringContents.chars[:config.stringContents.length])))
        case .Rectangle:
            config := command.renderData.rectangle
            strings.write_string(&out, fmt.tprintfln("rectangle: %v", config))
        case .Border:
            config := command.renderData.border
            strings.write_string(&out, fmt.tprintfln("text: %v", config))
        case .ScissorStart:
            strings.write_string(&out, fmt.tprintfln("ScissorStart"))
        case .ScissorEnd:
            strings.write_string(&out, fmt.tprintfln("ScissorEnd"))
        case .Image:
            strings.write_string(&out, fmt.tprintfln("Image"))
        case .None:
            strings.write_string(&out, fmt.tprintfln("None"))
        case .Custom:
            strings.write_string(&out, fmt.tprintfln("Custom"))
        }
    }
    return strings.to_string(out)
}
