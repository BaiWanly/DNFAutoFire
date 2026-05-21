#Requires AutoHotkey v2.0

global gUiListBoxWheel := Map()
global gUiListBoxWheel_Subclassed := Map()
global gUiListBoxWheel_SubclassFn := 0

UiListBoxWheel_Attach(ctrl) {
    global gUiListBoxWheel
    if !IsObject(ctrl) || !ctrl.Hwnd {
        return
    }
    gUiListBoxWheel[ctrl.Hwnd] := true
    UiListBoxWheel_SubclassHwnd(ctrl.Hwnd)
    parent := DllCall("GetParent", "ptr", ctrl.Hwnd, "ptr")
    if !parent {
        return
    }
    UiListBoxWheel_SubclassHwnd(parent)
    try {
        for hwnd in WinGetControlsHwnd("ahk_id " parent) {
            UiListBoxWheel_SubclassHwnd(hwnd)
        }
    }
}

UiListBoxWheel_SubclassHwnd(hwnd) {
    global gUiListBoxWheel_Subclassed, gUiListBoxWheel_SubclassFn
    if !hwnd || gUiListBoxWheel_Subclassed.Has(hwnd) {
        return
    }
    if !gUiListBoxWheel_SubclassFn {
        gUiListBoxWheel_SubclassFn := CallbackCreate(UiListBoxWheel_SubclassProc, "F", 6)
    }
    if DllCall("comctl32\SetWindowSubclass", "ptr", hwnd, "ptr", gUiListBoxWheel_SubclassFn, "uptr", 0, "uptr", 0) {
        gUiListBoxWheel_Subclassed[hwnd] := true
    }
}

UiListBoxWheel_SubclassProc(hWnd, uMsg, wParam, lParam, uIdSubclass, dwRefData) {
    global gUiListBoxWheel
    if (uMsg = 0x020A) {
        target := 0
        if gUiListBoxWheel.Has(hWnd) {
            target := hWnd
        } else {
            target := UiListBoxWheel_HitTestFromScreen(lParam)
        }
        if target {
            UiListBoxWheel_ApplyDelta(target, UiListBoxWheel_Delta(wParam))
            return 0
        }
    }
    return DllCall("DefSubclassProc", "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam, "UPtr")
}

UiListBoxWheel_HitTestFromScreen(lParam) {
    global gUiListBoxWheel
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    if (x > 0x7FFF) {
        x -= 0x10000
    }
    if (y > 0x7FFF) {
        y -= 0x10000
    }
    for hwnd, _ in gUiListBoxWheel {
        rc := Buffer(16, 0)
        if !DllCall("GetWindowRect", "ptr", hwnd, "ptr", rc) {
            continue
        }
        if (x >= NumGet(rc, 0, "Int")
            && x < NumGet(rc, 8, "Int")
            && y >= NumGet(rc, 4, "Int")
            && y < NumGet(rc, 12, "Int")) {
            return hwnd
        }
    }
    return 0
}

UiListBoxWheel_Delta(wParam) {
    delta := (wParam >> 16) & 0xFFFF
    if (delta > 0x7FFF) {
        delta -= 0x10000
    }
    return delta
}

; -VScroll 去掉 WS_VSCROLL 后需手动发 WM_VSCROLL（SB_LINEUP / SB_LINEDOWN）
UiListBoxWheel_ApplyDelta(hwnd, delta) {
    if !delta {
        return
    }
    code := (delta > 0) ? 0 : 1
    Loop Max(1, Abs(Round(delta / 120))) {
        DllCall("SendMessage", "ptr", hwnd, "uint", 0x115, "ptr", code, "ptr", 0, "ptr")
    }
}

UiRegister(ctrls, ctrl) {
    if IsObject(ctrls) && ctrl.Name != "" {
        ctrls[ctrl.Name] := ctrl
    }
    return ctrl
}

UiAdd(ctrls, gui, ctrlType, options, text := "") {
    if (ctrlType = "ListBox" || ctrlType = "DropDownList" || ctrlType = "ComboBox") && (text = "") {
        ctrl := gui.Add(ctrlType, options, [])
    } else if (ctrlType = "Hotkey" && text = "") {
        ctrl := gui.Add(ctrlType, options)
    } else {
        ctrl := gui.Add(ctrlType, options, text)
    }
    return UiRegister(ctrls, ctrl)
}

UiOptionNumber(options, key, defaultValue := 0) {
    if RegExMatch(options, "(^|\s)" key "(-?\d+)", &match) {
        return match[2] + 0
    }
    return defaultValue
}

UiSection(gui, options, title) {
    global UiTheme
    x := UiOptionNumber(options, "x")
    y := UiOptionNumber(options, "y")
    w := UiOptionNumber(options, "w", 120)
    UiSetDefaultFont(gui, "s9 Bold " UiTheme["SectionColor"])
    return gui.Add("Text", UiRect(x, y, w, ExLayout.ControlHeight(), "+0x200 BackgroundTrans"), title)
}

UiLabel(gui, options, text) {
    global UiTheme
    UiSetDefaultFont(gui, "s9 " UiTheme["TextColor"])
    return gui.Add("Text", options " +0x200", text)
}

; EX 设置窗口内页标题（与窗口标题栏区分，显示在内容区顶部）
UiExPageTitle(gui, title, contentRight, layout := "", helpFn := "") {
    titleX := ExLayout.MarginLeft()
    titleY := ExLayout.TitleY()
    titleW := ExLayout.TitleTextWidth(contentRight)
    titleCtrl := UiLabel(gui, UiLayoutRect(layout, titleX, titleY, titleW, ExLayout.TitleHeight(), "+0x200"), title)
    if (helpFn != "") {
        UiHelpButton(gui, UiExHelpButtonRect(layout, contentRight, ExLayout.HelpButtonY()), helpFn)
    }
    return titleCtrl
}

UiSectionWithHelp(gui, layout, x, y, title, helpFn, contentRight := "") {
    UiSection(gui, UiLayoutRect(layout, x, y, 120, 20), title)
    if (contentRight != "" && helpFn != "") {
        UiHelpButton(gui, UiExHelpButtonRect(layout, contentRight, y), helpFn)
    }
}

UiExSaveButtonRect(layout, y, contentRight, h := ExLayout.SaveButtonHeight()) {
    x := ExLayout.MarginLeft()
    return UiLayoutRect(layout, x, y, contentRight - x, h)
}

UiExHelpButtonRect(layout, contentRight, y, sz := 22) {
    return UiLayoutRect(layout, contentRight - sz, y, sz, sz)
}

UiExSplitButtonRects(layout, x, y, totalW, gap := 8, h := ExLayout.ControlHeight()) {
    leftW := Floor((totalW - gap) / 2)
    rightX := x + leftW + gap
    rightW := totalW - leftW - gap
    return [UiLayoutRect(layout, x, y, leftW, h), UiLayoutRect(layout, rightX, y, rightW, h)]
}

UiMutedLabel(gui, options, text) {
    global UiTheme
    UiSetDefaultFont(gui, "s9 " UiTheme["MutedColor"])
    return gui.Add("Text", options " +0x200", text)
}

UiButton(ctrls, gui, name, options, text, onClick := "", kind := "secondary") {
    UiSetButtonFont(gui, kind)
    ctrl := UiAdd(ctrls, gui, "Button", "v" name " " options, text)
    if (onClick != "") {
        ctrl.OnEvent("Click", onClick)
    }
    return ctrl
}

UiPlainButton(gui, options, text, onClick := "", kind := "secondary") {
    UiSetButtonFont(gui, kind)
    ctrl := gui.Add("Button", options, text)
    if (onClick != "") {
        ctrl.OnEvent("Click", onClick)
    }
    return ctrl
}

UiHelpButton(gui, options, onClick) {
    ctrl := UiPlainButton(gui, options, "?", onClick, "secondary")
    return ctrl
}

; 帮助说明弹窗（不用 MsgBox，避免 Windows 信息提示音）
; extraText 非空时，在内容区右上角显示次级「?」帮助按钮
UiHelpMsgBox(text, title := "", extraText := "", extraTitle := "") {
    ownerHwnd := WinExist("A")
    opt := "+AlwaysOnTop -MinimizeBox -MaximizeBox"
    if ownerHwnd {
        opt .= " +Owner" ownerHwnd
    }
    dlg := Gui(opt, title)
    UiApplyWindow(dlg)
    UiSetDefaultFont(dlg)
    pad := 16
    innerW := 368
    textY := pad
    if (extraText != "") {
        UiHelpButton(dlg, UiRect(pad + innerW - 22, pad, 22, 22), (*) => UiHelpMsgBox(extraText, extraTitle))
        textY := pad + 28
    }
    dlg.Add("Text", "x" pad " y" textY " w" innerW, text)
    UiPlainButton(dlg, "x" (pad + innerW - 80) " y+12 w80 h28 Default", "确定", (*) => dlg.Destroy(), "primary")
    dlg.OnEvent("Close", (*) => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())
    dlg.Show("AutoSize")
    WinWaitClose("ahk_id " dlg.Hwnd)
}

UiCheckBox(ctrls, gui, name, options) {
    return UiAdd(ctrls, gui, "CheckBox", "v" name " " options)
}

UiLink(ctrls, gui, name, options, text, onClick := "") {
    ctrl := UiAdd(ctrls, gui, "Link", "v" name " " options, "<a>" text "</a>")
    if (onClick != "") {
        ctrl.OnEvent("Click", onClick)
    }
    return ctrl
}

; 单行 Edit 无原生垂直居中；用 EM_GETRECT / EM_SETRECT（AHK 社区常见做法，见 just me）
UiEdit_ShouldVCenter(options) {
    if RegExMatch(options, "i)\bHidden\b") {
        return false
    }
    if RegExMatch(options, "i)\+Multi\b") {
        return false
    }
    h := UiOptionNumber(options, "h", 0)
    if (h > 0 && h < 16) {
        return false
    }
    return true
}

UiEditVCenter(hwnd) {
    if !hwnd {
        return
    }
    rc := Buffer(16, 0)
    if !DllCall("GetClientRect", "Ptr", hwnd, "Ptr", rc) {
        return
    }
    clHeight := NumGet(rc, 12, "Int")
    SendMessage(0xB2, 0, rc, , hwnd)
    rcHeight := NumGet(rc, 12, "Int") - NumGet(rc, 4, "Int")
    if (rcHeight <= 0) {
        return
    }
    dy := (clHeight - rcHeight) // 2
    if (dy <= 0) {
        return
    }
    NumPut("Int", NumGet(rc, 4, "Int") + dy, rc, 4)
    NumPut("Int", NumGet(rc, 12, "Int") + dy, rc, 12)
    SendMessage(0xB3, 0, rc, , hwnd)
}

UiEdit(ctrls, gui, name, options) {
    ctrl := UiAdd(ctrls, gui, "Edit", "v" name " " options)
    if UiEdit_ShouldVCenter(options) {
        try hwnd := ctrl.Hwnd
        catch {
            hwnd := 0
        }
        if hwnd {
            SetTimer(UiEditVCenter.Bind(hwnd), -1)
        }
    }
    return ctrl
}

UiListBox(ctrls, gui, name, options, onChange := "") {
    ctrl := UiAdd(ctrls, gui, "ListBox", "v" name " -VScroll " options)
    UiListBoxWheel_Attach(ctrl)
    if (onChange != "") {
        ctrl.OnEvent("Change", onChange)
    }
    return ctrl
}

UiHotkey(ctrls, gui, name, options, onChange := "") {
    ctrl := UiAdd(ctrls, gui, "Hotkey", "v" name " " options)
    if (onChange != "") {
        ctrl.OnEvent("Change", onChange)
    }
    return ctrl
}

UiSkillKeyEditor(gui, ctrls, prefix, listTitle, shotTitle, addText, deleteText, addFn, deleteFn, saveFn, helpFn, saveText, pageTitle := "", delayTitle := "", shotTitle2 := "", layout := "", saveAllFn := "", saveAllText := "") {
    skColX := ExLayout.MarginLeft()
    skColW := 120
    skGap := 16
    skRightX := skColX + skColW + skGap
    skRightColW := 120
    skFieldGap := 8
    skTriggerEW := 60
    skTriggerLW := skRightColW - skFieldGap - skTriggerEW
    skTriggerEX := skRightX + skTriggerLW + skFieldGap
    skBtnGap := 8
    skBtnW := (skColW - skBtnGap) // 2
    skListY := 74
    hasSecondShot := (shotTitle2 != "")
    skShotRowY := 78
    skRowStep := 30
    skListH := 180
    skBtnY := skListY + skListH + 6
    nextRowY := skShotRowY + skRowStep
    skSaveY := skBtnY + 30
    skContentRight := skRightX + skRightColW
    if (pageTitle != "") {
        UiExPageTitle(gui, pageTitle, skContentRight, layout, helpFn)
    }
    UiLabel(gui, UiLayoutRect(layout, skColX, 52, skColW, 20), listTitle)
    UiListBox(ctrls, gui, prefix "KeysListBox", UiLayoutRect(layout, skColX, skListY, skColW, skListH))

    ch := ExLayout.ControlHeight()
    UiPlainButton(gui, UiLayoutRect(layout, skColX, skBtnY, skBtnW, ch), addText, addFn)
    UiPlainButton(gui, UiLayoutRect(layout, skColX + skBtnW + skBtnGap, skBtnY, skBtnW, ch), deleteText, deleteFn)

    UiLabel(gui, UiLayoutRect(layout, skRightX, skShotRowY, skTriggerLW, ch), shotTitle)
    UiPressKeyEdit(ctrls, gui, prefix "ShotKey", UiLayoutRect(layout, skTriggerEX, skShotRowY, skTriggerEW, ch))

    if hasSecondShot {
        UiLabel(gui, UiLayoutRect(layout, skRightX, nextRowY, skTriggerLW, ch), shotTitle2)
        UiPressKeyEdit(ctrls, gui, prefix "ShotKey2", UiLayoutRect(layout, skTriggerEX, nextRowY, skTriggerEW, ch))
        nextRowY += skRowStep
    }

    if (delayTitle != "") {
        delayLW := skTriggerLW
        delayEX := skRightX + delayLW + skFieldGap
        delayEW := skTriggerEW
        UiLabel(gui, UiLayoutRect(layout, skRightX, nextRowY, delayLW, ch), delayTitle)
        UiEdit(ctrls, gui, prefix "Delay", UiLayoutRect(layout, delayEX, nextRowY, delayEW, ch, "+Number -E0x200 Border"))
    }
    saveBarW := skContentRight - ExLayout.MarginLeft()
    saveH := ExLayout.SaveButtonHeight()
    if (saveAllFn != "") {
        saveBtnRects := UiExSplitButtonRects(layout, ExLayout.MarginLeft(), skSaveY, saveBarW, 8, saveH)
        UiPlainButton(gui, saveBtnRects[1], saveAllText, saveAllFn, "secondary")
        UiPlainButton(gui, saveBtnRects[2], saveText, saveFn, "primary")
    } else {
        UiPlainButton(gui, UiExSaveButtonRect(layout, skSaveY, skContentRight), saveText, saveFn, "primary")
    }
}
