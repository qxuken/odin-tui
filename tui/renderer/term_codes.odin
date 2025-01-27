package renderer
import "core:fmt"
import "tui:sys"

// https://en.wikipedia.org/wiki/ANSI_escape_code

Simple_Color :: enum {
    Default,
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
    BrightBlack,
    BrightRed,
    BrightGreen,
    BrightYellow,
    BrightBlue,
    BrightMagenta,
    BrightCyan,
    BrightWhite,
}

RBG_Color :: [3]int

Color :: union #no_nil {
    Simple_Color,
    RBG_Color,
}

Style :: enum {
    Bold,
    Dim,
    Italic,
    Underline,
    Blinking,
    Inverse,
    Strikethrough,
}

reset_code :: proc() -> string {
    return sys.csi + "0m"
}

fg_color_code :: proc(color: Color, allocator := context.temp_allocator) -> string {
    switch c in color {
    case Simple_Color:
        return fg_simple_color_code(c)
    case RBG_Color:
        return fg_rbg_code(c, allocator)
    }
    unreachable()
}

bg_color_code :: proc(color: Color, allocator := context.temp_allocator) -> string {
    switch c in color {
    case Simple_Color:
        return bg_simple_color_code(c)
    case RBG_Color:
        return bg_rbg_code(c, allocator)
    }
    unreachable()
}

fg_rbg_code :: proc(color: RBG_Color, allocator := context.temp_allocator) -> string {
    return fmt.aprintf(sys.csi + "38;2;%v;%v;%vm", color.r, color.g, color.b, allocator = allocator)
}

bg_rbg_code :: proc(color: RBG_Color, allocator := context.temp_allocator) -> string {
    return fmt.aprintf(sys.csi + "48;2;%v;%v;%vm", color.r, color.g, color.b, allocator = allocator)
}

fg_simple_color_code :: proc(color: Simple_Color) -> string {
    switch color {
    case .Default:
        return sys.csi + "39m"
    case .Black:
        return sys.csi + "30m"
    case .Red:
        return sys.csi + "31m"
    case .Green:
        return sys.csi + "32m"
    case .Yellow:
        return sys.csi + "33m"
    case .Blue:
        return sys.csi + "34m"
    case .Magenta:
        return sys.csi + "35m"
    case .Cyan:
        return sys.csi + "36m"
    case .White:
        return sys.csi + "37m"
    case .BrightBlack:
        return sys.csi + "90m"
    case .BrightRed:
        return sys.csi + "91m"
    case .BrightGreen:
        return sys.csi + "92m"
    case .BrightYellow:
        return sys.csi + "93m"
    case .BrightBlue:
        return sys.csi + "94m"
    case .BrightMagenta:
        return sys.csi + "95m"
    case .BrightCyan:
        return sys.csi + "96m"
    case .BrightWhite:
        return sys.csi + "97m"
    }
    unreachable()
}

bg_simple_color_code :: proc(color: Simple_Color, bright := false) -> string {
    switch color {
    case .Default:
        return sys.csi + "49m"
    case .Black:
        return sys.csi + "40m"
    case .Red:
        return sys.csi + "41m"
    case .Green:
        return sys.csi + "42m"
    case .Yellow:
        return sys.csi + "43m"
    case .Blue:
        return sys.csi + "44m"
    case .Magenta:
        return sys.csi + "45m"
    case .Cyan:
        return sys.csi + "46m"
    case .White:
        return sys.csi + "47m"
    case .BrightBlack:
        return sys.csi + "100m"
    case .BrightRed:
        return sys.csi + "101m"
    case .BrightGreen:
        return sys.csi + "102m"
    case .BrightYellow:
        return sys.csi + "103m"
    case .BrightBlue:
        return sys.csi + "104m"
    case .BrightMagenta:
        return sys.csi + "105m"
    case .BrightCyan:
        return sys.csi + "106m"
    case .BrightWhite:
        return sys.csi + "107m"
    }
    unreachable()
}

start_style_code :: proc(style: Style) -> string {
    switch style {
    case .Bold:
        return sys.csi + "1m"
    case .Dim:
        return sys.csi + "2m"
    case .Italic:
        return sys.csi + "3m"
    case .Underline:
        return sys.csi + "4m"
    case .Blinking:
        return sys.csi + "5m"
    case .Inverse:
        return sys.csi + "7m"
    case .Strikethrough:
        return sys.csi + "9m"
    }
    unreachable()
}

end_style_code :: proc(style: Style) -> string {
    switch style {
    case .Bold:
        return sys.csi + "22m"
    case .Dim:
        return sys.csi + "22m"
    case .Italic:
        return sys.csi + "23m"
    case .Underline:
        return sys.csi + "24m"
    case .Blinking:
        return sys.csi + "25m"
    case .Inverse:
        return sys.csi + "27m"
    case .Strikethrough:
        return sys.csi + "200m"
    }
    unreachable()
}
