#Requires AutoHotkey v2.0

global gAutoRunGui := Gui("-MinimizeBox -MaximizeBox")
global gAutoRunCtrls := Map()

UiApplyWindow(gAutoRunGui)
gAutoRunGui.OnEvent("Escape", AutoRunGuiEscape)
gAutoRunGui.OnEvent("Close", AutoRunGuiClose)

UiExPageTitle(gAutoRunGui, exText["AutoRunPageTitle"], 296)
UiLabel(gAutoRunGui, UiRect(16, 54, 72, 26), exText["AutoRunLeftKey"])
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunLeftKey", UiRect(96, 54, 168, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gAutoRunGui, UiRect(96, 84, 168, 24), exText["SetKey"], AutoRunSetLeftKey)

UiLabel(gAutoRunGui, UiRect(16, 118, 72, 26), exText["AutoRunRightKey"])
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunRightKey", UiRect(96, 118, 168, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gAutoRunGui, UiRect(96, 148, 168, 24), exText["SetKey"], AutoRunSetRightKey)

UiLabel(gAutoRunGui, UiRect(16, 182, 72, 26), exText["AutoRunDelay"])
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunDelay", UiRect(96, 182, 72, 24, "+Number -E0x200 Border"))

UiPlainButton(gAutoRunGui, UiRect(96, 218, 168, 32), exText["CommonSave"], AutoRunSave, "primary")
UiHelpButton(gAutoRunGui, UiRect(262, 16, 22, 22), AutoRunHelp)

AutoRunGetCtrl(name) {
    global gAutoRunCtrls
    return gAutoRunCtrls.Has(name) ? gAutoRunCtrls[name] : ""
}

ShowGuiAutoRun(*) {
    global gMainGui, gAutoRunGui
    if IsObject(gMainGui) {
        gAutoRunGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gAutoRunGui.Title := exText["AutoRunTitle"]
    gAutoRunGui.Show("w296 h270")
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

AutoRunSetLeftKey(*) {
    AutoRunGetCtrl("AutoRunLeftKey").Text := GetPressKey()
}

AutoRunSetRightKey(*) {
    AutoRunGetCtrl("AutoRunRightKey").Text := GetPressKey()
}

AutoRunSave(*) {
    delay := Round((Trim(AutoRunGetCtrl("AutoRunDelay").Text) = "" ? 40 : AutoRunGetCtrl("AutoRunDelay").Text) + 0)
    if (delay < 1) {
        delay := 1
    } else if (delay > 400) {
        delay := 400
    }
    AutoRunGetCtrl("AutoRunDelay").Text := delay
    SavePreset(GetNowSelectPreset(), "AutoRunLeftKey", AutoRunGetCtrl("AutoRunLeftKey").Text)
    SavePreset(GetNowSelectPreset(), "AutoRunRightKey", AutoRunGetCtrl("AutoRunRightKey").Text)
    SavePreset(GetNowSelectPreset(), "AutoRunDelay", delay)
    HideGuiAutoRun()
}

AutoRunLoadConfig() {
    delay := Round(LoadPreset(GetNowSelectPreset(), "AutoRunDelay", 40) + 0)
    if (delay < 1) {
        delay := 1
    } else if (delay > 400) {
        delay := 400
    }
    AutoRunGetCtrl("AutoRunLeftKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunLeftKey", "Left")
    AutoRunGetCtrl("AutoRunRightKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunRightKey", "Right")
    AutoRunGetCtrl("AutoRunDelay").Text := delay
}
