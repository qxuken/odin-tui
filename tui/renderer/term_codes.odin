package renderer
import "core:fmt"
import "core:terminal/ansi"

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
    return ansi.CSI + ansi.RESET + ansi.SGR
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
    return fmt.aprintf(ansi.CSI + ansi.FG_COLOR_24_BIT + ";%v;%v;%v" + ansi.SGR, color.r, color.g, color.b, allocator = allocator)
}

bg_rbg_code :: proc(color: RBG_Color, allocator := context.temp_allocator) -> string {
    return fmt.aprintf(ansi.CSI + ansi.BG_COLOR_24_BIT + ";%v;%v;%v" + ansi.SGR, color.r, color.g, color.b, allocator = allocator)
}

fg_simple_color_code :: proc(color: Simple_Color) -> string {
    switch color {
    case .Default:
        return ansi.CSI + ansi.FG_DEFAULT + ansi.SGR
    case .Black:
        return ansi.CSI + ansi.FG_BLACK + ansi.SGR
    case .Red:
        return ansi.CSI + ansi.FG_RED + ansi.SGR
    case .Green:
        return ansi.CSI + ansi.FG_GREEN + ansi.SGR
    case .Yellow:
        return ansi.CSI + ansi.FG_YELLOW + ansi.SGR
    case .Blue:
        return ansi.CSI + ansi.FG_BLUE + ansi.SGR
    case .Magenta:
        return ansi.CSI + ansi.FG_MAGENTA + ansi.SGR
    case .Cyan:
        return ansi.CSI + ansi.FG_CYAN + ansi.SGR
    case .White:
        return ansi.CSI + ansi.FG_WHITE + ansi.SGR
    case .BrightBlack:
        return ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR
    case .BrightRed:
        return ansi.CSI + ansi.FG_BRIGHT_RED + ansi.SGR
    case .BrightGreen:
        return ansi.CSI + ansi.FG_BRIGHT_GREEN + ansi.SGR
    case .BrightYellow:
        return ansi.CSI + ansi.FG_BRIGHT_YELLOW + ansi.SGR
    case .BrightBlue:
        return ansi.CSI + ansi.FG_BRIGHT_BLUE + ansi.SGR
    case .BrightMagenta:
        return ansi.CSI + ansi.FG_BRIGHT_MAGENTA + ansi.SGR
    case .BrightCyan:
        return ansi.CSI + ansi.FG_BRIGHT_CYAN + ansi.SGR
    case .BrightWhite:
        return ansi.CSI + ansi.FG_BRIGHT_WHITE + ansi.SGR
    }
    unreachable()
}

bg_simple_color_code :: proc(color: Simple_Color, bright := false) -> string {
    switch color {
    case .Default:
        return ansi.CSI + ansi.BG_DEFAULT + ansi.SGR
    case .Black:
        return ansi.CSI + ansi.BG_BLACK + ansi.SGR
    case .Red:
        return ansi.CSI + ansi.BG_RED + ansi.SGR
    case .Green:
        return ansi.CSI + ansi.BG_GREEN + ansi.SGR
    case .Yellow:
        return ansi.CSI + ansi.BG_YELLOW + ansi.SGR
    case .Blue:
        return ansi.CSI + ansi.BG_BLUE + ansi.SGR
    case .Magenta:
        return ansi.CSI + ansi.BG_MAGENTA + ansi.SGR
    case .Cyan:
        return ansi.CSI + ansi.BG_CYAN + ansi.SGR
    case .White:
        return ansi.CSI + ansi.BG_WHITE + ansi.SGR
    case .BrightBlack:
        return ansi.CSI + ansi.BG_BRIGHT_BLACK + ansi.SGR
    case .BrightRed:
        return ansi.CSI + ansi.BG_BRIGHT_RED + ansi.SGR
    case .BrightGreen:
        return ansi.CSI + ansi.BG_BRIGHT_GREEN + ansi.SGR
    case .BrightYellow:
        return ansi.CSI + ansi.BG_BRIGHT_YELLOW + ansi.SGR
    case .BrightBlue:
        return ansi.CSI + ansi.BG_BRIGHT_BLUE + ansi.SGR
    case .BrightMagenta:
        return ansi.CSI + ansi.BG_BRIGHT_MAGENTA + ansi.SGR
    case .BrightCyan:
        return ansi.CSI + ansi.BG_BRIGHT_CYAN + ansi.SGR
    case .BrightWhite:
        return ansi.CSI + ansi.BG_BRIGHT_WHITE + ansi.SGR
    }
    unreachable()
}

start_style_code :: proc(style: Style) -> string {
    switch style {
    case .Bold:
        return ansi.CSI + ansi.BOLD + ansi.SGR
    case .Dim:
        return ansi.CSI + ansi.FAINT + ansi.SGR
    case .Italic:
        return ansi.CSI + ansi.ITALIC + ansi.SGR
    case .Underline:
        return ansi.CSI + ansi.UNDERLINE + ansi.SGR
    case .Blinking:
        return ansi.CSI + ansi.BLINK_SLOW + ansi.SGR
    case .Inverse:
        return ansi.CSI + ansi.INVERT + ansi.SGR
    case .Strikethrough:
        return ansi.CSI + ansi.STRIKE + ansi.SGR
    }
    unreachable()
}

end_style_code :: proc(style: Style) -> string {
    switch style {
    case .Bold:
        return ansi.CSI + ansi.NO_BOLD_FAINT + ansi.SGR
    case .Dim:
        return ansi.CSI + ansi.NO_BOLD_FAINT + ansi.SGR
    case .Italic:
        return ansi.CSI + ansi.NO_ITALIC_BLACKLETTER + ansi.SGR
    case .Underline:
        return ansi.CSI + ansi.NO_UNDERLINE + ansi.SGR
    case .Blinking:
        return ansi.CSI + ansi.NO_BLINK + ansi.SGR
    case .Inverse:
        return ansi.CSI + ansi.NO_REVERSE + ansi.SGR
    case .Strikethrough:
        return ansi.CSI + ansi.NO_STRIKE + ansi.SGR
    }
    unreachable()
}
