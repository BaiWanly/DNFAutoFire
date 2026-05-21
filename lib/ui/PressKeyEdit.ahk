#Requires AutoHotkey v2.0

global UiPressKeyEdit__Fields := Map()
global UiPressKeyEdit__Session := ""
global UiPressKeyEdit__OnMessageInstalled := false
global UiPressKeyEdit__EscHookReady := false

UiPressKeyEdit_Prompt() {
    global exText
    if IsSet(exText) && IsObject(exText) && exText.Has("PressKeyPrompt") {
        return exText["PressKeyPrompt"]
    }
    return "输入按键.."
}

UiPressKeyEdit(ctrls, gui, name, options, onCaptured := "") {
    base := "+ReadOnly -WantCtrlA -E0x200 Border"
    if !InStr(options, "ReadOnly") {
        options .= " " base
    }
    ctrl := UiEdit(ctrls, gui, name, options)
    UiPressKeyEdit_Attach(ctrl, onCaptured)
    return ctrl
}

UiPressKeyEdit_Attach(ctrl, onCaptured := "") {
    if !IsObject(ctrl) {
        return
    }
    try hwnd := ctrl.Hwnd
    catch {
        return
    }
    if !hwnd {
        return
    }
    UiPressKeyEdit__Fields[hwnd] := Map("ctrl", ctrl, "hwnd", hwnd, "onCaptured", onCaptured)
    ctrl.OnEvent("LoseFocus", UiPressKeyEdit_OnLoseFocus)
    UiPressKeyEdit_EnsureClickHook()
    UiPressKeyEdit_EnsureEscHotkey()
}

UiPressKeyEdit_EnsureClickHook() {
    global UiPressKeyEdit__OnMessageInstalled
    if UiPressKeyEdit__OnMessageInstalled {
        return
    }
    OnMessage(0x0201, UiPressKeyEdit_OnLButtonDown)
    UiPressKeyEdit__OnMessageInstalled := true
}

UiPressKeyEdit_OnLButtonDown(wParam, lParam, msg, hwnd) {
    global UiPressKeyEdit__Fields
    if !hwnd || !UiPressKeyEdit__Fields.Has(hwnd) {
        return
    }
    entry := UiPressKeyEdit__Fields[hwnd]
    ctrl := entry["ctrl"]
    if !IsObject(ctrl) || UiPressKeyEdit_IsCapturing(ctrl) {
        return
    }
    UiPressKeyEdit_Begin(ctrl)
}

UiPressKeyEdit_IsPrompt(text) {
    return text = UiPressKeyEdit_Prompt()
}

UiPressKeyEdit_Value(ctrl) {
    if !IsObject(ctrl) {
        return ""
    }
    try text := ctrl.Text
    catch {
        return ""
    }
    return UiPressKeyEdit_IsPrompt(text) ? "" : text
}

UiPressKeyEdit_IsCapturing(ctrl) {
    global UiPressKeyEdit__Session
    if !IsObject(ctrl) || !IsObject(UiPressKeyEdit__Session) {
        return false
    }
    try {
        return UiPressKeyEdit__Session["ctrl"].Hwnd = ctrl.Hwnd
    } catch {
        return false
    }
}

UiPressKeyEdit_IsSessionActive() {
    global UiPressKeyEdit__Session
    return IsObject(UiPressKeyEdit__Session)
}

UiPressKeyEdit_OnLoseFocus(ctrl, *) {
    if !UiPressKeyEdit_IsCapturing(ctrl) {
        return
    }
    ; 延后处理，避免 Esc 先触发失焦把值恢复回去
    SetTimer(UiPressKeyEdit_DeferredLoseFocus.Bind(ctrl), -1)
}

UiPressKeyEdit_DeferredLoseFocus(ctrl, *) {
    if !UiPressKeyEdit_IsCapturing(ctrl) {
        return
    }
    global UiPressKeyEdit__Session
    saved := IsObject(UiPressKeyEdit__Session) ? UiPressKeyEdit__Session["savedText"] : ""
    UiPressKeyEdit_Finish(ctrl, saved)
}

UiPressKeyEdit_Begin(ctrl) {
    global UiPressKeyEdit__Session
    if IsObject(UiPressKeyEdit__Session) {
        try prev := UiPressKeyEdit__Session["ctrl"]
        catch {
            prev := ""
        }
        if IsObject(prev) && prev.Hwnd != ctrl.Hwnd {
            UiPressKeyEdit_Finish(prev, UiPressKeyEdit__Session["savedText"])
        }
    }
    saved := ""
    try saved := ctrl.Text
    catch {
    }
    if UiPressKeyEdit_IsPrompt(saved) {
        saved := ""
    }
    ctrl.Text := UiPressKeyEdit_Prompt()
    try ctrl.Focus()
    catch {
    }
    ih := InputHook("L0")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{Escape}", "E")
    ih.KeyOpt("{LWin}{RWin}{AppsKey}", "-E")
    ih.OnEnd := UiPressKeyEdit_OnInputEnd.Bind(ctrl)
    ih.Start()
    UiPressKeyEdit__Session := Map("ctrl", ctrl, "savedText", saved, "hook", ih)
}

UiPressKeyEdit_OnInputEnd(ctrl, ih, *) {
    if !UiPressKeyEdit_IsCapturing(ctrl) {
        try ih.Stop()
        catch {
        }
        return
    }
    if (ih.EndKey = "Escape") {
        UiPressKeyEdit_Finish(ctrl, "")
        return
    }
    key := ih.EndKey
    if (StrLen(key) = 1) {
        key := Format("{:U}", key)
    }
    UiPressKeyEdit_Commit(ctrl, key)
}

UiPressKeyEdit_OnEscape(*) {
    global UiPressKeyEdit__Session
    if !IsObject(UiPressKeyEdit__Session) {
        return
    }
    try ctrl := UiPressKeyEdit__Session["ctrl"]
    catch {
        return
    }
    UiPressKeyEdit_Finish(ctrl, "")
}

UiPressKeyEdit_Commit(ctrl, key) {
    entry := UiPressKeyEdit__Lookup(ctrl)
    onCaptured := IsObject(entry) ? entry["onCaptured"] : ""
    value := key
    if (onCaptured != "") {
        try value := onCaptured.Call(key)
        catch {
            value := key
        }
    }
    UiPressKeyEdit_Finish(ctrl, value)
}

UiPressKeyEdit_Finish(ctrl, value) {
    global UiPressKeyEdit__Session
    session := UiPressKeyEdit__Session
    if IsObject(session) {
        try ih := session["hook"]
        catch {
            ih := ""
        }
        if IsObject(ih) {
            try ih.Stop()
            catch {
            }
        }
    }
    UiPressKeyEdit__Session := ""
    try ctrl.Text := value
    catch {
    }
}

UiPressKeyEdit__Lookup(ctrl) {
    global UiPressKeyEdit__Fields
    try hwnd := ctrl.Hwnd
    catch {
        return ""
    }
    return UiPressKeyEdit__Fields.Has(hwnd) ? UiPressKeyEdit__Fields[hwnd] : ""
}

UiPressKeyEdit_EnsureEscHotkey() {
    global UiPressKeyEdit__EscHookReady
    if UiPressKeyEdit__EscHookReady {
        return
    }
    try {
        HotIf(UiPressKeyEdit_IsSessionActive)
        Hotkey("Escape", UiPressKeyEdit_OnEscape, "On")
        HotIf()
        UiPressKeyEdit__EscHookReady := true
    } catch {
    }
}
