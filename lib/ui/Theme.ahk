#Requires AutoHotkey v2.0

global UiTheme := Map(
    "FontName", "Segoe UI",
    "KeyFace", "Segoe UI",
    "FontSize", "s9",
    "TextColor", "c202124",
    "MutedColor", "c64748B",
    "SectionColor", "c374151",
    "PrimaryColor", "c2563EB",
    "DangerColor", "cB42318",
    "KeyOff", "334155",
    "KeyOn", "355FA3",
    "KeyOv", "355FA3",
    "KeyOffColor", "c334155",
    "KeyOnColor", "c355FA3",
    "KeyDisabledColor", "c94A3B8",
    "KeyCellBg", "E2E8F0",
    "KeyCapOffBg", "F8FAFC",
    "KeyCapOffBorder", "CBD5E1",
    "KeyCapOnBg", "EAF2FF",
    "KeyCapOnBorder", "B7CCEE",
    "KeyCapOvBg", "EAF2FF",
    "KeyCapOvBorder", "B7CCEE",
    "KeyCapLockedBg", "E5E7EB",
    "KeyCapLockedBorder", "CBD5E1",
    "KeyCapLockedText", "94A3B8",
    "KeyCapHintOn", "355FA3",
    "KeyCapHintOv", "355FA3",
    "KeyCapHintLocked", "94A3B8",
    "SwitchTrackOn", "93C5FD",
    "MutedLinkHover", "c5B84D9",
    "WindowBg", "F8FAFC"
)

global UiTheme__HandCursorHwnds := Map()
global UiTheme__HandCursorHandle := 0

UiApplyWindow(gui) {
    global UiTheme
    gui.BackColor := UiTheme["WindowBg"]
    gui.SetFont(UiTheme["FontSize"] " c" UiTheme["KeyOff"], UiTheme["FontName"])
    static cursorHooked := false
    if !cursorHooked {
        cursorHooked := true
        OnMessage(0x0020, UiTheme__OnSetCursor)
    }
}

UiSetDefaultFont(gui, options := "") {
    global UiTheme
    fontOptions := options = "" ? UiTheme["FontSize"] " " UiTheme["TextColor"] : options
    gui.SetFont(fontOptions, UiTheme["FontName"])
}

UiSetKeyFont(gui, size, enabled := false) {
    global UiTheme
    color := enabled ? UiTheme["KeyOnColor"] : UiTheme["KeyOffColor"]
    weight := enabled ? "Bold" : "Norm"
    gui.SetFont(size " " color " " weight, UiTheme["FontName"])
}

UiSetButtonFont(gui, kind := "secondary") {
    global UiTheme
    if (kind = "primary") {
        gui.SetFont("s10 Bold " UiTheme["PrimaryColor"], UiTheme["FontName"])
    } else if (kind = "danger") {
        gui.SetFont("s9 " UiTheme["DangerColor"], UiTheme["FontName"])
    } else {
        gui.SetFont("s9 " UiTheme["TextColor"], UiTheme["FontName"])
    }
}

; 主界面键帽字号（与参考项目 DNFAutoFire 一致）
UiMainKeyLabelFontSize(keyName) {
    switch keyName {
        case "Backspace", "Backslash", "Enter", "LShift", "RShift", "LCtrl", "RCtrl", "LAlt", "RAlt", "Space", "NumLk", "NumEnter":
            return "s10"
        case "Caps", "Tab":
            return "s10"
        case "Up", "Down", "Left", "Right":
            return "s14"
        default:
            return "s12"
    }
}

UiRegisterHandCursor(ctrl) {
    global UiTheme__HandCursorHwnds
    if !IsObject(ctrl) {
        return
    }
    try hw := ctrl.Hwnd
    catch {
        return
    }
    if !hw {
        return
    }
    rootHwnd := DllCall("user32\GetAncestor", "ptr", hw, "uint", 2, "ptr")
    UiTheme__HandCursorHwnds[hw] := rootHwnd ? rootHwnd : hw
}

UiTheme__OnSetCursor(wParam, lParam, msg, hwnd) {
    global UiTheme__HandCursorHwnds, UiTheme__HandCursorHandle
    currentRoot := DllCall("user32\GetAncestor", "ptr", hwnd, "uint", 2, "ptr")
    if !currentRoot {
        currentRoot := hwnd
    }
    pt := Buffer(8, 0)
    if !DllCall("user32\GetCursorPos", "ptr", pt) {
        return
    }
    px := NumGet(pt, 0, "int")
    py := NumGet(pt, 4, "int")
    rc := Buffer(16, 0)
    for handHwnd, rootHwnd in UiTheme__HandCursorHwnds {
        if (rootHwnd != currentRoot) {
            continue
        }
        if !DllCall("user32\GetWindowRect", "ptr", handHwnd, "ptr", rc) {
            continue
        }
        left := NumGet(rc, 0, "int")
        top := NumGet(rc, 4, "int")
        right := NumGet(rc, 8, "int")
        bottom := NumGet(rc, 12, "int")
        if (px >= left && px < right && py >= top && py < bottom) {
            if !UiTheme__HandCursorHandle {
                UiTheme__HandCursorHandle := DllCall("user32\LoadCursor", "ptr", 0, "ptr", 32649, "ptr")
            }
            if UiTheme__HandCursorHandle {
                DllCall("user32\SetCursor", "ptr", UiTheme__HandCursorHandle)
                return true
            }
        }
    }
}
