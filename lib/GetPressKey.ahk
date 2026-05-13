GetPressKey() {
    return GetUserInputKey()
}

GetUserInputKey() {
    ToolTip("请按下一个按键，Esc清空")
    try {
        return GetUserInputKeyCore()
    } finally {
        ToolTip()
    }
}

GetUserInputKeyCore() {
    ih := InputHook("L0")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LWin}{RWin}{AppsKey}", "-E")
    ih.Start()
    ih.Wait()
    key := ih.EndKey
    k := StrLower(key)
    if (ih.EndReason = "Escape" || k = "esc" || k = "escape") {
        return ""
    }
    if (StrLen(key) == 1) {
        key := Format("{:U}", key)
    }
    return key
}

global __PressKeyEditHwndMap := Map()
global __PressKeyEditAfterMap := Map()
global __PressKeyEditClickMap := Map()

; Edit 控件不支持 OnEvent("Click")，改为监听 WM_LBUTTONDOWN（仅限脚本 GUI），延迟执行以免挡住默认焦点处理
; afterCapture：捕获结束後调用，参数为键名字符串（含 Esc 清空时的 ""）
RegisterEditPressKeyCapture(edit, afterCapture := unset) {
    global __PressKeyEditHwndMap, __PressKeyEditAfterMap
    if !IsObject(edit) {
        return
    }
    try GuiTheme_RegisterHandCursor(edit)
    __PressKeyEditHwndMap[edit.Hwnd] := edit
    if IsSet(afterCapture) {
        __PressKeyEditAfterMap[edit.Hwnd] := afterCapture
    } else if __PressKeyEditAfterMap.Has(edit.Hwnd) {
        ; v2 Map.Delete 在键不存在时会抛错
        __PressKeyEditAfterMap.Delete(edit.Hwnd)
    }
    RegisterEditClickHandler(edit, __PressKeyEdit_DefaultClick.Bind(edit.Hwnd))
}

RegisterEditClickHandler(edit, clickHandler) {
    global __PressKeyEditHwndMap, __PressKeyEditClickMap
    static installed := false
    if !IsObject(edit) {
        return
    }
    try GuiTheme_RegisterHandCursor(edit)
    __PressKeyEditHwndMap[edit.Hwnd] := edit
    __PressKeyEditClickMap[edit.Hwnd] := clickHandler
    if !installed {
        installed := true
        OnMessage(0x0201, __PressKeyEdit_OnLButtonDown)
    }
}

__PressKeyEdit_DefaultClick(hwnd) {
    global __PressKeyEditHwndMap, __PressKeyEditAfterMap
    if !__PressKeyEditHwndMap.Has(hwnd) {
        return
    }
    edit := __PressKeyEditHwndMap[hwnd]
    if __PressKeyEditAfterMap.Has(hwnd) {
        GetPressKeyIntoEdit(edit, __PressKeyEditAfterMap[hwnd])
    } else {
        GetPressKeyIntoEdit(edit)
    }
}

__PressKeyEdit_OnLButtonDown(wParam, lParam, msg, hwnd) {
    global __PressKeyEditClickMap
    if !__PressKeyEditClickMap.Has(hwnd) {
        return
    }
    clickHandler := __PressKeyEditClickMap[hwnd]
    SetTimer(() => clickHandler.Call(), -1)
}

; 只读键位框：框内提示并用 InputHook 捕获下一键（无 ToolTip）
GetPressKeyIntoEdit(edit, afterCapture := unset) {
    static capturing := false
    if capturing || !IsObject(edit) {
        return
    }
    capturing := true
    prev := edit.Text
    if (prev = "请按键...") {
        prev := ""
    }
    edit.Text := "请按键..."
    key := ""
    try {
        key := GetUserInputKeyCore()
        edit.Text := key
    } finally {
        capturing := false
    }
    if IsSet(afterCapture) {
        needsEditArg := false
        try {
            if InStr(Type(afterCapture), "BoundFunc") {
                needsEditArg := true
            } else {
                needsEditArg := afterCapture.MinParams >= 2
            }
        }
        if needsEditArg {
            afterCapture.Call(edit, key)
        } else {
            afterCapture.Call(key)
        }
    }
}
