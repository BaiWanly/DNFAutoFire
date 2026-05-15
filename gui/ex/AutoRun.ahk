#Requires AutoHotkey v2.0

global gAutoRunGui := Gui("+ToolWindow")
global gAutoRunCtrls := Map()

UiApplyWindow(gAutoRunGui)
gAutoRunGui.OnEvent("Escape", AutoRunGuiEscape)
gAutoRunGui.OnEvent("Close", AutoRunGuiClose)

xLeft := UiColumnX(1)
xRight := UiColumnX(2)
UiLabel(gAutoRunGui, UiRect(xLeft, UiRowY(1), 80, 20), "左方向键")
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunLeftKey", UiRect(xLeft, UiRowY(2), 80, 20, "+ReadOnly -WantCtrlA"))
UiPlainButton(gAutoRunGui, UiRect(xLeft, UiRowY(3), 80, 22), "设置按键", AutoRunSetLeftKey)

UiLabel(gAutoRunGui, UiRect(xRight, UiRowY(1), 80, 20), "右方向键")
UiEdit(gAutoRunCtrls, gAutoRunGui, "AutoRunRightKey", UiRect(xRight, UiRowY(2), 80, 20, "+ReadOnly -WantCtrlA"))
UiPlainButton(gAutoRunGui, UiRect(xRight, UiRowY(3), 80, 22), "设置按键", AutoRunSetRightKey)

UiPlainButton(gAutoRunGui, UiRect(xRight, 86, 80, 28), "保存", AutoRunSave)
UiHelpButton(gAutoRunGui, UiRect(158, UiRowY(1), 18, 18), AutoRunHelp)

AutoRunGetCtrl(name) {
    global gAutoRunCtrls
    return gAutoRunCtrls.Has(name) ? gAutoRunCtrls[name] : ""
}

ShowGuiAutoRun(*) {
    global gMainGui, gAutoRunGui
    if IsObject(gMainGui) {
        gAutoRunGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gAutoRunGui.Title := "自动奔跑设置"
    gAutoRunGui.Show("w184 h122")
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
    MsgBox("设置自动奔跑要监听的左右键。`n如果游戏里方向键不是 Left/Right，请改成你的实际按键后保存。", "自动奔跑说明", "Iconi")
}

AutoRunSetLeftKey(*) {
    AutoRunGetCtrl("AutoRunLeftKey").Text := GetPressKey()
}

AutoRunSetRightKey(*) {
    AutoRunGetCtrl("AutoRunRightKey").Text := GetPressKey()
}

AutoRunSave(*) {
    SavePreset(GetNowSelectPreset(), "AutoRunLeftKey", AutoRunGetCtrl("AutoRunLeftKey").Text)
    SavePreset(GetNowSelectPreset(), "AutoRunRightKey", AutoRunGetCtrl("AutoRunRightKey").Text)
    HideGuiAutoRun()
}

AutoRunLoadConfig() {
    AutoRunGetCtrl("AutoRunLeftKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunLeftKey", "Left")
    AutoRunGetCtrl("AutoRunRightKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunRightKey", "Right")
}
