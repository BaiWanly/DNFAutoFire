#Requires AutoHotkey v2.0

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
    return gui.Add("Text", UiRect(x, y, w, 20, "+0x200"), title)
}

UiLabel(gui, options, text) {
    global UiTheme
    UiSetDefaultFont(gui, "s9 " UiTheme["TextColor"])
    return gui.Add("Text", options " +0x200", text)
}

; EX 设置窗口内页标题（与窗口标题栏区分，显示在内容区顶部）
UiExPageTitle(gui, title, contentWidth) {
    return UiLabel(gui, UiRect(16, 16, contentWidth - 46, 22, "+0x200"), title)
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

UiEdit(ctrls, gui, name, options) {
    return UiAdd(ctrls, gui, "Edit", "v" name " " options)
}

UiListBox(ctrls, gui, name, options, onChange := "") {
    ctrl := UiAdd(ctrls, gui, "ListBox", "v" name " " options)
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

UiSkillKeyEditor(gui, ctrls, prefix, listTitle, shotTitle, addText, deleteText, setText, addFn, deleteFn, setFn, saveFn, helpFn, saveText, pageTitle := "", delayTitle := "", shotTitle2 := "", setFn2 := 0) {
    skColX := 16
    skColW := 136
    skGap := 16
    skRightX := skColX + skColW + skGap
    skBtnGap := 8
    skBtnW := (skColW - skBtnGap) // 2
    skTriggerLW := 60
    skTriggerEX := skRightX + skTriggerLW + 6
    skTriggerEW := skColW - skTriggerLW - 6
    skListY := 74
    hasSecondShot := (shotTitle2 != "" && IsObject(setFn2))
    extraRows := 0
    if hasSecondShot {
        extraRows += 1
    }
    if (delayTitle != "") {
        extraRows += 1
    }
    skListH := 176 - extraRows * 28
    skBtnY := skListY + skListH + 6
    nextRowY := 136
    skSaveY := 286 + extraRows * 28
    skWinW := skTriggerEX + skTriggerEW + 16
    setBtnW := skTriggerEX - skRightX + skTriggerEW

    if (pageTitle != "") {
        UiExPageTitle(gui, pageTitle, skWinW)
    }
    UiHelpButton(gui, UiRect(skWinW - 30, 12, 22, 22), helpFn)
    UiLabel(gui, UiRect(skColX, 52, skColW, 20), listTitle)
    UiListBox(ctrls, gui, prefix "KeysListBox", UiRect(skColX, skListY, skColW, skListH))

    UiPlainButton(gui, UiRect(skColX, skBtnY, skBtnW, 24), addText, addFn)
    UiPlainButton(gui, UiRect(skColX + skBtnW + skBtnGap, skBtnY, skBtnW, 24), deleteText, deleteFn)

    UiLabel(gui, UiRect(skRightX, 78, skTriggerLW, 24), shotTitle)
    UiEdit(ctrls, gui, prefix "ShotKey", UiRect(skTriggerEX, 78, skTriggerEW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
    UiPlainButton(gui, UiRect(skRightX, 106, setBtnW, 24), setText, setFn)

    if hasSecondShot {
        UiLabel(gui, UiRect(skRightX, nextRowY, skTriggerLW, 24), shotTitle2)
        UiEdit(ctrls, gui, prefix "ShotKey2", UiRect(skTriggerEX, nextRowY, skTriggerEW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
        UiPlainButton(gui, UiRect(skRightX, nextRowY + 28, setBtnW, 24), setText, setFn2)
        nextRowY += 58
    }

    if (delayTitle != "") {
        delayLW := 78
        delayEX := skRightX + delayLW + 6
        delayEW := skColW - delayLW - 6
        UiLabel(gui, UiRect(skRightX, nextRowY, delayLW, 24), delayTitle)
        UiEdit(ctrls, gui, prefix "Delay", UiRect(delayEX, nextRowY, delayEW, 24, "+Number -E0x200 Border"))
    }
    UiPlainButton(gui, UiRect(16, skSaveY, skWinW - 32, 28), saveText, saveFn, "primary")
}
