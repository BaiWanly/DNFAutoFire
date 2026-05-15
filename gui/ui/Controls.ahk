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

UiSection(gui, options, title) {
    UiSetDefaultFont(gui, "s9 c333333")
    return gui.Add("GroupBox", options, title)
}

UiLabel(gui, options, text) {
    UiSetDefaultFont(gui, "s9 c333333")
    return gui.Add("Text", options " +0x200", text)
}

UiMutedLabel(gui, options, text) {
    UiSetDefaultFont(gui, "s9 c666666")
    return gui.Add("Text", options " +0x200", text)
}

UiButton(ctrls, gui, name, options, text, onClick := "") {
    ctrl := UiAdd(ctrls, gui, "Button", "v" name " " options, text)
    if (onClick != "") {
        ctrl.OnEvent("Click", onClick)
    }
    return ctrl
}

UiPlainButton(gui, options, text, onClick := "") {
    UiSetDefaultFont(gui, "s9 c222222")
    ctrl := gui.Add("Button", options, text)
    if (onClick != "") {
        ctrl.OnEvent("Click", onClick)
    }
    return ctrl
}

UiHelpButton(gui, options, onClick) {
    ctrl := UiPlainButton(gui, options, "?", onClick)
    return ctrl
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

UiKeycap(ctrls, gui, name, pos, label, fontSize, onClick) {
    UiSetKeyFont(gui, fontSize, false)
    ctrl := UiAdd(ctrls, gui, "Text", "v" name " " pos " +0x200 +0x400000 +Center", label)
    ctrl.OnEvent("Click", onClick)
    return ctrl
}

UiSkillKeyEditor(gui, ctrls, prefix, listTitle, shotTitle, addText, deleteText, setText, addFn, deleteFn, setFn, saveFn, helpFn, delayTitle := "") {
    listX := UiColumnX(1)
    formX := UiColumnX(2)
    listW := 80
    fieldW := 80

    UiLabel(gui, UiRect(listX, UiRowY(1), listW, 20), listTitle)
    UiListBox(ctrls, gui, prefix "KeysListBox", UiRect(listX, UiRowY(2), listW, 172))

    UiPlainButton(gui, UiRect(formX, 40, fieldW, 22), addText, addFn)
    UiPlainButton(gui, UiRect(formX, 70, fieldW, 22), deleteText, deleteFn)
    UiLabel(gui, UiRect(formX, 100, fieldW, 20), shotTitle)
    UiEdit(ctrls, gui, prefix "ShotKey", UiRect(formX, 120, fieldW, 20, "+ReadOnly -WantCtrlA"))
    UiPlainButton(gui, UiRect(formX, 148, fieldW, 22), setText, setFn)

    saveY := 178
    if (delayTitle != "") {
        UiLabel(gui, UiRect(formX, 180, fieldW, 20), delayTitle)
        UiEdit(ctrls, gui, prefix "Delay", UiRect(formX, 200, fieldW, 20, "+Number"))
        saveY := 232
    }
    UiPlainButton(gui, UiRect(formX, saveY, fieldW, 27), "保存", saveFn)
    UiHelpButton(gui, UiRect(158, 8, 18, 18), helpFn)
}
