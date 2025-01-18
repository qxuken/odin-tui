package renderer

import "../term"

Color :: enum {
	None,
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

Style :: enum {
	None,
	Bold,
	Dim,
	Italic,
	Underline,
	Blinking,
	Inverse,
	Hidden,
	Strikethrough,
}

reset_color :: proc() -> string {
	return term.csi + "0m"
}

fg_color_code :: proc(color: Color) -> string {
	switch color {
	case .None:
		return ""
	case .Black:
		return term.csi + "30m"
	case .Red:
		return term.csi + "31m"
	case .Green:
		return term.csi + "32m"
	case .Yellow:
		return term.csi + "33m"
	case .Blue:
		return term.csi + "34m"
	case .Magenta:
		return term.csi + "35m"
	case .Cyan:
		return term.csi + "36m"
	case .White:
		return term.csi + "37m"
	case .BrightBlack:
		return term.csi + "90m"
	case .BrightRed:
		return term.csi + "91m"
	case .BrightGreen:
		return term.csi + "92m"
	case .BrightYellow:
		return term.csi + "93m"
	case .BrightBlue:
		return term.csi + "94m"
	case .BrightMagenta:
		return term.csi + "95m"
	case .BrightCyan:
		return term.csi + "96m"
	case .BrightWhite:
		return term.csi + "97m"
	}
	unreachable()
}

bg_color_code :: proc(color: Color, bright := false) -> string {
	switch color {
	case .None:
		return ""
	case .Black:
		return term.csi + "40m"
	case .Red:
		return term.csi + "41m"
	case .Green:
		return term.csi + "42m"
	case .Yellow:
		return term.csi + "43m"
	case .Blue:
		return term.csi + "44m"
	case .Magenta:
		return term.csi + "45m"
	case .Cyan:
		return term.csi + "46m"
	case .White:
		return term.csi + "47m"
	case .BrightBlack:
		return term.csi + "100m"
	case .BrightRed:
		return term.csi + "101m"
	case .BrightGreen:
		return term.csi + "102m"
	case .BrightYellow:
		return term.csi + "103m"
	case .BrightBlue:
		return term.csi + "104m"
	case .BrightMagenta:
		return term.csi + "105m"
	case .BrightCyan:
		return term.csi + "106m"
	case .BrightWhite:
		return term.csi + "107m"
	}
	unreachable()
}

start_style_code :: proc(style: Style) -> string {
	switch style {
	case .None:
		return ""
	case .Bold:
		return term.csi + "1m"
	case .Dim:
		return term.csi + "2m"
	case .Italic:
		return term.csi + "3m"
	case .Underline:
		return term.csi + "4m"
	case .Blinking:
		return term.csi + "5m"
	case .Inverse:
		return term.csi + "7m"
	case .Hidden:
		return term.csi + "8m"
	case .Strikethrough:
		return term.csi + "9m"
	}
	unreachable()
}

reset_style_code :: proc(style: Style) -> string {
	switch style {
	case .None:
		return ""
	case .Bold:
		return term.csi + "22m"
	case .Dim:
		return term.csi + "22m"
	case .Italic:
		return term.csi + "23m"
	case .Underline:
		return term.csi + "24m"
	case .Blinking:
		return term.csi + "25m"
	case .Inverse:
		return term.csi + "27m"
	case .Hidden:
		return term.csi + "28m"
	case .Strikethrough:
		return term.csi + "200m"
	}
	unreachable()
}
