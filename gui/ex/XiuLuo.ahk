#Requires AutoHotkey v2.0

global gXiuLuoGui := Gui("-MinimizeBox -MaximizeBox")
global gXiuLuoCtrls := Map()
global gXiuLuoLayout := ExLayout.Window()

UiApplyWindow(gXiuLuoGui)
gXiuLuoGui.OnEvent("Escape", XiuLuoGuiEscape)
gXiuLuoGui.OnEvent("Close", XiuLuoGuiClose)

labelW := 60
fieldW := 120
fieldX := ExLayout.MarginLeft() + labelW + 8
contentRight := fieldX + fieldW

UiExPageTitle(gXiuLuoGui, exText["XiuLuoPageTitle"], contentRight, gXiuLuoLayout, XiuLuoHelp)
UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 54, labelW, 24), exText["XiuLuoTriggerKey"])
UiPressKeyEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoTriggerKey", UiLayoutRect(gXiuLuoLayout, fieldX, 54, fieldW, ExLayout.ControlHeight()))

UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 86, labelW, 24), exText["XiuLuoXKey"])
UiPressKeyEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoXKey", UiLayoutRect(gXiuLuoLayout, fieldX, 86, fieldW, ExLayout.ControlHeight()))

UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 118, labelW, 24), exText["XiuLuoWaveKey1"])
UiPressKeyEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey1", UiLayoutRect(gXiuLuoLayout, fieldX, 118, fieldW, ExLayout.ControlHeight()))

UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 150, labelW, 24), exText["XiuLuoWaveKey2"])
UiPressKeyEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey2", UiLayoutRect(gXiuLuoLayout, fieldX, 150, fieldW, ExLayout.ControlHeight()))

UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 182, labelW, 24), exText["XiuLuoWaveKey3"])
UiPressKeyEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey3", UiLayoutRect(gXiuLuoLayout, fieldX, 182, fieldW, ExLayout.ControlHeight()))

UiPlainButton(gXiuLuoGui, UiExSaveButtonRect(gXiuLuoLayout, 222, contentRight), exText["CommonSave"], XiuLuoSave, "primary")

XiuLuoGetCtrl(name) {
    global gXiuLuoCtrls
    return gXiuLuoCtrls.Has(name) ? gXiuLuoCtrls[name] : ""
}

ShowGuiXiuLuo(*) {
    global gMainGui, gXiuLuoGui, gXiuLuoLayout
    if IsObject(gMainGui) {
        gXiuLuoGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gXiuLuoGui.Title := exText["XiuLuoTitle"]
    gXiuLuoGui.Show("w" gXiuLuoLayout.Width() " h" gXiuLuoLayout.Height())
    XiuLuoLoadConfig()
    DisableGuiMain()
}

HideGuiXiuLuo() {
    gXiuLuoGui.Hide()
    EnableGuiMain()
}

XiuLuoGuiEscape(*) {
    XiuLuoSave()
}

XiuLuoGuiClose(*) {
    XiuLuoSave()
}

XiuLuoHelp(*) {
    UiHelpMsgBox(exText["XiuLuoHelp"], exText["XiuLuoHelpTitle"])
}

XiuLuoSave(*) {
    XiuLuoSaveConfig()
    HideGuiXiuLuo()
}

XiuLuoSaveConfig() {
    SavePreset(GetNowSelectPreset(), "XiuLuoTriggerKey", UiPressKeyEdit_Value(XiuLuoGetCtrl("XiuLuoTriggerKey")))
    SavePreset(GetNowSelectPreset(), "XiuLuoXKey", UiPressKeyEdit_Value(XiuLuoGetCtrl("XiuLuoXKey")))
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey1", UiPressKeyEdit_Value(XiuLuoGetCtrl("XiuLuoWaveKey1")))
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey2", UiPressKeyEdit_Value(XiuLuoGetCtrl("XiuLuoWaveKey2")))
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey3", UiPressKeyEdit_Value(XiuLuoGetCtrl("XiuLuoWaveKey3")))
}

XiuLuoLoadConfig() {
    XiuLuoGetCtrl("XiuLuoTriggerKey").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoTriggerKey", "A")
    XiuLuoGetCtrl("XiuLuoXKey").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoXKey", "X")
    XiuLuoGetCtrl("XiuLuoWaveKey1").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey1", "S")
    XiuLuoGetCtrl("XiuLuoWaveKey2").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey2", "D")
    XiuLuoGetCtrl("XiuLuoWaveKey3").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey3", "F")
}
