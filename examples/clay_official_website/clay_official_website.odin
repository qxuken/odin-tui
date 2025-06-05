package main

import "clay"
import "core:c"
import "core:encoding/json"
import "core:fmt"
import "core:io"
import "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:time"
import "core:unicode"
import "tui:events"
import "tui:renderer"
import "tui:term_sys"

TARGET_FPS :: 60
SAVE_RENDER_LOGS :: #config(SAVE_RENDER_LOGS, false)

window_height: int
window_width: int
target_delta :: time.Second / 120

FONT_ID_TITLE_56 :: 9
FONT_ID_TITLE_52 :: 1
FONT_ID_TITLE_48 :: 2
FONT_ID_TITLE_36 :: 3
FONT_ID_TITLE_32 :: 4
FONT_ID_BODY_16 :: 10
FONT_ID_BODY_36 :: 5
FONT_ID_BODY_30 :: 6
FONT_ID_BODY_28 :: 7
FONT_ID_BODY_24 :: 8

COLOR_LIGHT :: clay.Color{244, 235, 230, 255}
COLOR_LIGHT_HOVER :: clay.Color{224, 215, 210, 255}
COLOR_BUTTON_HOVER :: clay.Color{238, 227, 225, 255}
COLOR_BROWN :: clay.Color{61, 26, 5, 255}
//COLOR_RED :: clay.Color {252, 67, 27, 255}
COLOR_RED :: clay.Color{168, 66, 28, 255}
COLOR_RED_HOVER :: clay.Color{148, 46, 8, 255}
COLOR_ORANGE :: clay.Color{225, 138, 50, 255}
COLOR_BLUE :: clay.Color{111, 173, 162, 255}
COLOR_TEAL :: clay.Color{111, 173, 162, 255}
COLOR_BLUE_DARK :: clay.Color{2, 32, 82, 255}

// Colors for top stripe
COLOR_TOP_BORDER_1 :: clay.Color{168, 66, 28, 255}
COLOR_TOP_BORDER_2 :: clay.Color{223, 110, 44, 255}
COLOR_TOP_BORDER_3 :: clay.Color{225, 138, 50, 255}
COLOR_TOP_BORDER_4 :: clay.Color{236, 189, 80, 255}
COLOR_TOP_BORDER_5 :: clay.Color{240, 213, 137, 255}

COLOR_BLOB_BORDER_1 :: clay.Color{168, 66, 28, 255}
COLOR_BLOB_BORDER_2 :: clay.Color{203, 100, 44, 255}
COLOR_BLOB_BORDER_3 :: clay.Color{225, 138, 50, 255}
COLOR_BLOB_BORDER_4 :: clay.Color{236, 159, 70, 255}
COLOR_BLOB_BORDER_5 :: clay.Color{240, 189, 100, 255}

headerTextConfig := clay.TextElementConfig {
    fontId    = FONT_ID_BODY_24,
    fontSize  = 24,
    textColor = {61, 26, 5, 255},
}

LandingPageDesktop :: proc() {
    if clay.UI(
        clay.ID("LandingPage1Desktop"),
        clay.Layout(
            {
                sizing = {width = clay.SizingGrow({}), height = clay.SizingFit({min = cast(f32)window_height - 70})},
                childAlignment = {y = .CENTER},
                padding = {left = 5, right = 5},
            },
        ),
    ) {
        if clay.UI(
            clay.ID("LandingPage1"),
            clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingGrow({})}, childAlignment = {y = .CENTER}, padding = clay.PaddingAll(3), childGap = 3}),
            clay.Border({left = {2, COLOR_RED}, right = {2, COLOR_RED}}),
        ) {
            if clay.UI(clay.ID("LeftText"), clay.Layout({sizing = {width = clay.SizingPercent(0.55)}, layoutDirection = .TOP_TO_BOTTOM, childGap = 8})) {
                clay.Text(
                    "Clay is a flex-box style UI auto layout library in C, with declarative syntax and microsecond performance.",
                    clay.TextConfig({fontSize = 56, fontId = FONT_ID_TITLE_56, textColor = COLOR_RED}),
                )
                //                if clay.UI(clay.Layout({sizing = {width = clay.SizingGrow({}), height = clay.SizingFixed(32)}})) {}
                clay.Text("Clay is laying out this webpage right now!", clay.TextConfig({fontSize = 36, fontId = FONT_ID_TITLE_36, textColor = COLOR_ORANGE}))
            }
        }
    }
}

FeatureBlocks :: proc(widthSizing: clay.SizingAxis, outerPadding: u16) {
    textConfig := clay.TextConfig({fontSize = 24, fontId = FONT_ID_BODY_24, textColor = COLOR_RED})
    if clay.UI(
        clay.ID("HFileBoxOuter"),
        clay.Layout(
            {layoutDirection = .TOP_TO_BOTTOM, sizing = {width = widthSizing}, childAlignment = {y = .CENTER}, padding = {outerPadding, outerPadding, 3, 3}, childGap = 8},
        ),
    ) {
        if clay.UI(clay.ID("HFileIncludeOuter"), clay.Layout({padding = {8, 8, 4, 4}}), clay.Rectangle({color = COLOR_RED, cornerRadius = clay.CornerRadiusAll(8)})) {
            clay.Text("#include clay.h", clay.TextConfig({fontSize = 24, fontId = FONT_ID_BODY_24, textColor = COLOR_LIGHT}))
        }
        clay.Text("~2000 lines of C99.", textConfig)
        clay.Text("Zero dependencies, including no C standard library.", textConfig)
    }
    if clay.UI(
        clay.ID("BringYourOwnRendererOuter"),
        clay.Layout(
            {layoutDirection = .TOP_TO_BOTTOM, sizing = {width = widthSizing}, childAlignment = {y = .CENTER}, padding = {outerPadding, outerPadding, 3, 3}, childGap = 2},
        ),
    ) {
        clay.Text("Renderer agnostic.", clay.TextConfig({fontId = FONT_ID_BODY_24, fontSize = 24, textColor = COLOR_ORANGE}))
        clay.Text("Layout with clay, then render with Raylib, WebGL Canvas or even as HTML.", textConfig)
        clay.Text("Flexible output for easy compositing in your custom engine or environment.", textConfig)
    }
}

FeatureBlocksDesktop :: proc() {
    if clay.UI(clay.ID("FeatureBlocksOuter"), clay.Layout({sizing = {width = clay.SizingGrow({})}})) {
        if clay.UI(
            clay.ID("FeatureBlocksInner"),
            clay.Layout({sizing = {width = clay.SizingGrow({})}, childAlignment = {y = .CENTER}}),
            clay.Border({betweenChildren = {width = 1, color = COLOR_RED}}),
        ) {
            FeatureBlocks(clay.SizingPercent(0.5), 5)
        }
    }
}

DeclarativeSyntaxPage :: proc(titleTextConfig: clay.TextElementConfig, widthSizing: clay.SizingAxis) {
    if clay.UI(clay.ID("SyntaxPageLeftText"), clay.Layout({sizing = {width = widthSizing}, layoutDirection = .TOP_TO_BOTTOM, childGap = 8})) {
        clay.Text("Declarative Syntax", clay.TextConfig(titleTextConfig))
        if clay.UI(clay.ID("SyntaxSpacer"), clay.Layout({sizing = {width = clay.SizingGrow({max = 2})}})) {}
        clay.Text(
            "Flexible and readable declarative syntax with nested UI element hierarchies.",
            clay.TextConfig({fontSize = 28, fontId = FONT_ID_BODY_28, textColor = COLOR_RED}),
        )
        clay.Text("Mix elements with standard C code like loops, conditionals and functions.", clay.TextConfig({fontSize = 28, fontId = FONT_ID_BODY_28, textColor = COLOR_RED}))
        clay.Text(
            "Create your own library of re-usable components from UI primitives like text, images and rectangles.",
            clay.TextConfig({fontSize = 28, fontId = FONT_ID_BODY_28, textColor = COLOR_RED}),
        )
    }
}

DeclarativeSyntaxPageDesktop :: proc() {
    if clay.UI(
        clay.ID("SyntaxPageDesktop"),
        clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFit({min = cast(f32)window_height - 50})}, childAlignment = {y = .CENTER}, padding = {left = 5, right = 5}}),
    ) {
        if clay.UI(
            clay.ID("SyntaxPage"),
            clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingGrow({})}, childAlignment = {y = .CENTER}, padding = clay.PaddingAll(3), childGap = 3}),
            clay.Border({left = {2, COLOR_RED}, right = {2, COLOR_RED}}),
        ) {
            DeclarativeSyntaxPage({fontSize = 52, fontId = FONT_ID_TITLE_52, textColor = COLOR_RED}, clay.SizingPercent(0.5))
        }
    }
}

RendererButtonActive :: proc(index: i32, text: string) {
    if clay.UI(
        clay.Layout({sizing = {width = clay.SizingFixed(30)}, padding = clay.PaddingAll(6)}),
        clay.Rectangle({color = COLOR_RED, cornerRadius = clay.CornerRadiusAll(10)}),
    ) {
        clay.Text(text, clay.TextConfig({fontSize = 28, fontId = FONT_ID_BODY_28, textColor = COLOR_LIGHT}))
    }
}

RendererButtonInactive :: proc(index: u32, text: string) {
    if clay.UI(clay.Layout({}), clay.BorderOutsideRadius({2, COLOR_RED}, 10)) {
        if clay.UI(
            clay.ID("RendererButtonInactiveInner", index),
            clay.Layout({sizing = {width = clay.SizingFixed(30)}, padding = clay.PaddingAll(6)}),
            clay.Rectangle({color = COLOR_LIGHT, cornerRadius = clay.CornerRadiusAll(1)}),
        ) {
            clay.Text(text, clay.TextConfig({fontSize = 28, fontId = FONT_ID_BODY_28, textColor = COLOR_RED}))
        }
    }
}

RendererPage :: proc(titleTextConfig: clay.TextElementConfig, widthSizing: clay.SizingAxis) {
    if clay.UI(clay.ID("RendererLeftText"), clay.Layout({sizing = {width = widthSizing}, layoutDirection = .TOP_TO_BOTTOM, childGap = 8})) {
        clay.Text("Renderer & Platform Agnostic", clay.TextConfig(titleTextConfig))
        if clay.UI(clay.Layout({sizing = {width = clay.SizingGrow({max = 6})}})) {}
        clay.Text(
            "Clay outputs a sorted array of primitive render commands, such as RECTANGLE, TEXT or IMAGE.",
            clay.TextConfig({fontSize = 28, fontId = FONT_ID_BODY_36, textColor = COLOR_RED}),
        )
        clay.Text(
            "Write your own renderer in a few hundred lines of code, or use the provided examples for Raylib, WebGL canvas and more.",
            clay.TextConfig({fontSize = 28, fontId = FONT_ID_BODY_36, textColor = COLOR_RED}),
        )
        clay.Text("There's even an HTML renderer - you're looking at it right now!", clay.TextConfig({fontSize = 28, fontId = FONT_ID_BODY_36, textColor = COLOR_RED}))
    }
    if clay.UI(clay.ID("RendererRightText"), clay.Layout({sizing = {width = widthSizing}, childAlignment = {x = .CENTER}, layoutDirection = .TOP_TO_BOTTOM, childGap = 16})) {
        clay.Text("Try changing renderer!", clay.TextConfig({fontSize = 36, fontId = FONT_ID_BODY_36, textColor = COLOR_ORANGE}))
        if clay.UI(clay.Layout({sizing = {width = clay.SizingGrow({max = 16})}})) {}
        RendererButtonActive(0, "Raylib Renderer")
    }
}

RendererPageDesktop :: proc() {
    if clay.UI(
        clay.ID("RendererPageDesktop"),
        clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFit({min = cast(f32)window_height - 5})}, childAlignment = {y = .CENTER}, padding = {left = 5, right = 5}}),
    ) {
        if clay.UI(
            clay.ID("RendererPage"),
            clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingGrow({})}, childAlignment = {y = .CENTER}, padding = clay.PaddingAll(32), childGap = 32}),
            clay.Border({left = {2, COLOR_RED}, right = {2, COLOR_RED}}),
        ) {
            RendererPage({fontSize = 52, fontId = FONT_ID_TITLE_52, textColor = COLOR_RED}, clay.SizingPercent(0.5))
        }
    }
}

createLayout :: proc() -> clay.ClayArray(clay.RenderCommand) {
    clay.BeginLayout()
    if clay.UI(
        clay.ID("OuterContainer"),
        clay.Layout({layoutDirection = .TOP_TO_BOTTOM, sizing = {clay.SizingGrow({}), clay.SizingGrow({})}}),
        clay.Rectangle({color = COLOR_LIGHT}),
    ) {
        if clay.UI(
            clay.ID("Header"),
            clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(3)}, childAlignment = {y = .CENTER}, childGap = 2, padding = {left = 4, right = 2}}),
        ) {
            clay.Text("Clay", &headerTextConfig)
            if clay.UI(clay.Layout({sizing = {width = clay.SizingGrow({})}})) {}

            if clay.UI(
                clay.ID("LinkGithubOuter"),
                clay.Layout({padding = {4, 4, 6, 6}}),
                clay.BorderOutsideRadius({1, COLOR_RED}, 1),
                clay.Rectangle(
                    {cornerRadius = clay.CornerRadiusAll(1), color = clay.PointerOver(clay.GetElementId(clay.MakeString("LinkGithubOuter"))) ? COLOR_LIGHT_HOVER : COLOR_LIGHT},
                ),
            ) {
                clay.Text("Github", clay.TextConfig({fontId = FONT_ID_BODY_24, fontSize = 24, textColor = {61, 26, 5, 255}}))
            }
        }
        if clay.UI(clay.ID("TopBorder1"), clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(1)}}), clay.Rectangle({color = COLOR_TOP_BORDER_5})) {}
        if clay.UI(clay.ID("TopBorder2"), clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(1)}}), clay.Rectangle({color = COLOR_TOP_BORDER_4})) {}
        if clay.UI(clay.ID("TopBorder3"), clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(1)}}), clay.Rectangle({color = COLOR_TOP_BORDER_3})) {}
        if clay.UI(clay.ID("TopBorder4"), clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(1)}}), clay.Rectangle({color = COLOR_TOP_BORDER_2})) {}
        if clay.UI(clay.ID("TopBorder5"), clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(1)}}), clay.Rectangle({color = COLOR_TOP_BORDER_1})) {}
        if clay.UI(
            clay.ID("ScrollContainerBackgroundRectangle"),
            clay.Scroll({vertical = true}),
            clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingGrow({})}, layoutDirection = clay.LayoutDirection.TOP_TO_BOTTOM}),
            clay.Rectangle({color = COLOR_LIGHT}),
            clay.Border({betweenChildren = {2, COLOR_RED}}),
        ) {
            LandingPageDesktop()
            FeatureBlocksDesktop()
            DeclarativeSyntaxPageDesktop()
            RendererPageDesktop()
        }
    }
    return clay.EndLayout()
}

errorHandler :: proc "c" (errorData: clay.ErrorData) {
    if (errorData.errorType == clay.ErrorType.DUPLICATE_ID) {

    }
}

main :: proc() {
    term_sys.set_utf8_terminal()
    term_sys.enable_raw_mode()
    term_sys.enable_mouse_capture()
    term_sys.enter_alternate_mode()
    term_sys.hide_cursor()
    defer term_sys.show_cursor()
    defer term_sys.exit_alternate_mode()
    defer term_sys.restore_terminal()

    size := term_sys.get_size()

    min_memory_size: u32 = clay.MinMemorySize()
    memory := make([^]u8, min_memory_size)
    arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(min_memory_size, memory)
    clay.Initialize(arena, {cast(f32)size.width, cast(f32)size.width}, {handler = errorHandler})
    clay.SetMeasureTextFunction(measure_text, 0)

    out_stream := os.stream_from_handle(os.stdout)
    defer io.destroy(out_stream)

    events.init_event_poller()
    defer events.destroy_event_poller()

    ren := renderer.make_renderer({})

    frame_time := time.tick_now()
    fps := 0
    frames_counter_value := 0
    frames_counter_delta: time.Duration

    for {
        defer free_all(context.temp_allocator)

        size := term_sys.get_size()
        window_width = size.width
        window_height = size.height

        renderer.clean_renderer_cycle(&ren, {size.width, size.height})
        clay.SetLayoutDimensions({cast(f32)window_width, cast(f32)window_height})

        evts, ok := events.poll_event()
        if ok {
            scroll_amount: f32
            mouse_position := [2]int{max(int), max(int)}
            mouse_pressed := false
            for evt in evts {
                #partial switch e in evt {
                case events.Mouse_Event:
                    if e.m == .ScrollDown {
                        scroll_amount -= 0.1
                    } else if e.m == .ScrollUp {
                        scroll_amount += 0.1
                    } else {
                        mouse_pressed = e.m == .LeftClick || e.m == .LeftDrag
                        mouse_position = {e.x, e.y}
                    }
                case events.Key:
                    if unicode.to_lower(e.val) == 'q' {
                        return
                    }
                }
            }
            if scroll_amount != 0 {
                clay.UpdateScrollContainers(true, {0, scroll_amount}, cast(f32)(target_delta))
            }
            if mouse_position.x != max(int) {
                clay.SetPointerState({cast(f32)mouse_position.x, cast(f32)mouse_position.y}, mouse_pressed)
            }
        }

        render_commands: clay.ClayArray(clay.RenderCommand) = createLayout()
        clay_tui_render(&ren, &render_commands)

        fps_str := fmt.tprint(fps)
        renderer.render_text(&ren, {size.width - len(fps_str), 0, len(fps_str), 1}, fps_str, fg = .Green, bg = .Black, style = .Bold)

        arena_allocator := virtual.arena_allocator(&ren.arena)
        out_builder := strings.builder_make(arena_allocator)
        term_sys.start_sync_update(&out_builder)
        term_sys.clear_screen(&out_builder)
        renderer.render_to_builder(&ren, &out_builder)
        term_sys.end_sync_update(&out_builder)

        io.write_string(out_stream, strings.to_string(out_builder))
        io.flush(out_stream)

        delta_time := time.tick_since(frame_time)
        frames_counter_delta += delta_time
        if frames_counter_delta >= time.Second {
            fps = frames_counter_value
            frames_counter_value = 0
            frames_counter_delta = 0
            when SAVE_RENDER_LOGS {
                log_filename := fmt.tprintf("./logs/%v.json", transmute(i64)time.tick_now())
                w_err := os.write_entire_file_or_err(log_filename, transmute([]u8)clay_command_tprint(&render_commands))
                if w_err != nil {
                    fmt.eprintfln("Unable to write file(%v): %v", log_filename, w_err)
                    os.exit(1)
                }
            }
        } else {
            frames_counter_value += 1
        }

        frame_time = time.tick_now()
        time.sleep(max(time.Nanosecond, time.Second / TARGET_FPS - delta_time))
    }
}
