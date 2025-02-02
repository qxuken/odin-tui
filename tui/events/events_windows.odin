package events

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sys/windows"
import "core:time"
import "core:unicode/utf8"

in_handle: windows.HANDLE
in_buf: []windows.INPUT_RECORD

_init_event_poller :: proc() {
    in_handle = windows.GetStdHandle(windows.STD_INPUT_HANDLE)
    in_buf = new([128]windows.INPUT_RECORD)[:]
}

_destroy_event_poller :: proc() {
    delete(in_buf)
}

_poll_event :: proc(allocator := context.temp_allocator) -> ([]Event, bool) {
    n: windows.DWORD
    if windows.GetNumberOfConsoleInputEvents(in_handle, &n) && n == 0 {
        return nil, false
    }
    if ok := windows.ReadConsoleInputW(in_handle, &in_buf[0], 128, &n); !ok {
        return nil, false
    }
    evts := process_input(in_buf[:n], allocator)
    return evts, true
}

process_input :: proc(buf: []windows.INPUT_RECORD, allocator := context.temp_allocator) -> []Event {
    res := make([dynamic]Event, allocator = allocator)

    when DEBUG_EVENTS {
        builder := strings.builder_make(context.allocator)
        for evt in buf {
            switch evt.EventType {
            case .KEY_EVENT:
                strings.write_string(&builder, fmt.tprint(evt.Event.KeyEvent))
            case .MOUSE_EVENT:
                strings.write_string(&builder, fmt.tprint(evt.Event.MouseEvent))
            case .WINDOW_BUFFER_SIZE_EVENT:
                strings.write_string(&builder, fmt.tprint(evt.Event.WindowBufferSizeEvent))
            case .MENU_EVENT:
                strings.write_string(&builder, fmt.tprint(evt.Event.MenuEvent))
            case .FOCUS_EVENT:
                strings.write_string(&builder, fmt.tprint(evt.Event.FocusEvent))
            }
        }
        original_data := strings.to_string(builder)
    }

    for evt in buf {
        event: Event = Unknown{""}
        #partial switch evt.EventType {
        case .KEY_EVENT:
            evt := evt.Event.KeyEvent
            event = Key{rune(evt.wVirtualKeyCode), ""}
        case .MOUSE_EVENT:
            evt := evt.Event.MouseEvent
            coord := evt.dwMousePosition
            state: Mouse_Event_Type
            switch evt.dwButtonState {
            case 0:
                state = .Move
            case 1:
                state = .LeftClick
            case 2:
                state = .RightClick
            case 4:
                state = .MiddleClick
            case 8388608:
                state = .ScrollUp
            case 4286578688:
                state = .ScrollDown
            }
            event = Mouse_Event{state, cast(int)coord.X, cast(int)coord.Y, ""}
        }
        when DEBUG_EVENTS {
            switch &e in event {
            case Unknown:
                e.raw = original_data
            case Mouse_Event:
                e.raw = original_data
            case Key:
                e.raw = original_data
            }
        }
        append(&res, event)
    }

    return res[:]
}
