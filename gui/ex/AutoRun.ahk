#Requires AutoHotkey v2.0

global gAutoRunGui := Gui("-MinimizeBox -MaximizeBox")
global gAutoRunCtrls := Map()
global gAutoRunLayout := ExLayout.Window()

UiApplyWindow(gAutoRunGui)
gAutoRunGui.OnEvent("Escape", AutoRunGuiEscape)
gAutoRunGui.OnEvent("Close", AutoRunGuiClose)

labelW := 60
fieldW := 120
fieldX := ExLayout.MarginLeft() + labelW + 8
contentRight := fieldX + fieldW

UiExPageTitle(gAutoRunGui, exText["AutoRunPageTitle"], contentRight, gAutoRunLayout, AutoRunHelp)
UiLabel(gAutoRunGui, UiLayoutRect(gAutoRunLayout, ExLayout.MarginLeft(), 54, labelW, 26), exText["AutoRunLeftKey"])
UiPressKeyEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunLeftKey", UiLayoutRect(gAutoRunLayout, fieldX, 54, fieldW, ExLayout.ControlHeight()))

UiLabel(gAutoRunGui, UiLayoutRect(gAutoRunLayout, ExLayout.MarginLeft(), 86, labelW, 26), exText["AutoRunRightKey"])
UiPressKeyEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunRightKey", UiLayoutRect(gAutoRunLayout, fieldX, 86, fieldW, ExLayout.ControlHeight()))

UiLabel(gAutoRunGui, UiLayoutRect(gAutoRunLayout, ExLayout.MarginLeft(), 118, labelW, 26), exText["AutoRunDelay"])
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunDelay", UiLayoutRect(gAutoRunLayout, fieldX, 118, fieldW, ExLayout.ControlHeight(), "+Number -E0x200 Border"))

autoRunSaveRects := UiExSplitButtonRects(gAutoRunLayout, ExLayout.MarginLeft(), 158, contentRight - ExLayout.MarginLeft(), 8, ExLayout.SaveButtonHeight())
UiPlainButton(gAutoRunGui, autoRunSaveRects[1], exText["CommonSaveToAll"], AutoRunSaveToAll, "secondary")
UiPlainButton(gAutoRunGui, autoRunSaveRects[2], exText["CommonSave"], AutoRunSave, "primary")

AutoRunGetCtrl(name) {
    global gAutoRunCtrls
    return gAutoRunCtrls.Has(name) ? gAutoRunCtrls[name] : ""
}

ShowGuiAutoRun(*) {
    global gMainGui, gAutoRunGui, gAutoRunLayout
    if IsObject(gMainGui) {
        gAutoRunGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gAutoRunGui.Title := exText["AutoRunTitle"]
    gAutoRunGui.Show("w" gAutoRunLayout.Width() " h" gAutoRunLayout.Height())
    AutoRunLoadConfig()
    DisableGuiMain()
}

HideGuiAutoRun() {
    gAutoRunGui.Hide()
    EnableGuiMain()
}

AutoRunGuiEscape(*) {
    AutoRunSave()
}

AutoRunGuiClose(*) {
    AutoRunSave()
}

AutoRunHelp(*) {
    UiHelpMsgBox(exText["AutoRunHelp"], exText["AutoRunHelpTitle"])
}

AutoRunReadFields() {
    delay := Round((Trim(AutoRunGetCtrl("AutoRunDelay").Text) = "" ? 30 : AutoRunGetCtrl("AutoRunDelay").Text) + 0)
    if (delay < 1) {
        delay := 1
    } else if (delay > 400) {
        delay := 400
    }
    AutoRunGetCtrl("AutoRunDelay").Text := delay
    return Map(
        "AutoRunLeftKey", UiPressKeyEdit_Value(AutoRunGetCtrl("AutoRunLeftKey")),
        "AutoRunRightKey", UiPressKeyEdit_Value(AutoRunGetCtrl("AutoRunRightKey")),
        "AutoRunDelay", delay
    )
}

AutoRunWritePreset(presetName, fields) {
    SavePreset(presetName, "AutoRunLeftKey", fields["AutoRunLeftKey"])
    SavePreset(presetName, "AutoRunRightKey", fields["AutoRunRightKey"])
    SavePreset(presetName, "AutoRunDelay", fields["AutoRunDelay"])
}

AutoRunSave(*) {
    AutoRunWritePreset(GetNowSelectPreset(), AutoRunReadFields())
    HideGuiAutoRun()
}

AutoRunSaveToAll(*) {
    fields := AutoRunReadFields()
    for presetName in LoadAllPreset() {
        AutoRunWritePreset(presetName, fields)
    }
    HideGuiAutoRun()
}

AutoRunLoadConfig() {
    delay := Round(LoadPreset(GetNowSelectPreset(), "AutoRunDelay", 30) + 0)
    if (delay < 1) {
        delay := 1
    } else if (delay > 400) {
        delay := 400
    }
    AutoRunGetCtrl("AutoRunLeftKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunLeftKey", "Left")
    AutoRunGetCtrl("AutoRunRightKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunRightKey", "Right")
    AutoRunGetCtrl("AutoRunDelay").Text := delay
}
