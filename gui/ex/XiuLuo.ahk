#Requires AutoHotkey v2.0

global gXiuLuoGui := Gui("-MinimizeBox -MaximizeBox")
global gXiuLuoCtrls := Map()

UiApplyWindow(gXiuLuoGui)
gXiuLuoGui.OnEvent("Escape", XiuLuoGuiEscape)
gXiuLuoGui.OnEvent("Close", XiuLuoGuiClose)

UiExPageTitle(gXiuLuoGui, exText["XiuLuoPageTitle"], 258)
UiLabel(gXiuLuoGui, UiRect(16, 54, 76, 24), exText["XiuLuoTriggerKey"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoTriggerKey", UiRect(98, 54, 140, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiRect(98, 82, 140, 24), exText["SetKey"], XiuLuoSetTriggerKey)

UiLabel(gXiuLuoGui, UiRect(16, 118, 76, 24), exText["XiuLuoXKey"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoXKey", UiRect(98, 118, 140, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiRect(98, 146, 140, 24), exText["SetKey"], XiuLuoSetXKey)

UiLabel(gXiuLuoGui, UiRect(16, 182, 76, 24), exText["XiuLuoWaveKey1"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey1", UiRect(98, 182, 140, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiRect(98, 210, 140, 24), exText["SetKey"], XiuLuoSetWaveKey1)

UiLabel(gXiuLuoGui, UiRect(16, 246, 76, 24), exText["XiuLuoWaveKey2"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey2", UiRect(98, 246, 140, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiRect(98, 274, 140, 24), exText["SetKey"], XiuLuoSetWaveKey2)

UiLabel(gXiuLuoGui, UiRect(16, 310, 76, 24), exText["XiuLuoWaveKey3"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey3", UiRect(98, 310, 140, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiRect(98, 338, 140, 24), exText["SetKey"], XiuLuoSetWaveKey3)

UiPlainButton(gXiuLuoGui, UiRect(16, 382, 222, 30), exText["CommonSave"], XiuLuoSave, "primary")
UiHelpButton(gXiuLuoGui, UiRect(236, 16, 22, 22), XiuLuoHelp)

XiuLuoGetCtrl(name) {
    global gXiuLuoCtrls
    return gXiuLuoCtrls.Has(name) ? gXiuLuoCtrls[name] : ""
}

ShowGuiXiuLuo(*) {
    global gMainGui, gXiuLuoGui
    if IsObject(gMainGui) {
        gXiuLuoGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gXiuLuoGui.Title := exText["XiuLuoTitle"]
    gXiuLuoGui.Show("w270 h430")
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

XiuLuoSetTriggerKey(*) {
    XiuLuoGetCtrl("XiuLuoTriggerKey").Text := GetPressKey()
}

XiuLuoSetXKey(*) {
    XiuLuoGetCtrl("XiuLuoXKey").Text := GetPressKey()
}

XiuLuoSetWaveKey1(*) {
    XiuLuoGetCtrl("XiuLuoWaveKey1").Text := GetPressKey()
}

XiuLuoSetWaveKey2(*) {
    XiuLuoGetCtrl("XiuLuoWaveKey2").Text := GetPressKey()
}

XiuLuoSetWaveKey3(*) {
    XiuLuoGetCtrl("XiuLuoWaveKey3").Text := GetPressKey()
}

XiuLuoSaveConfig() {
    SavePreset(GetNowSelectPreset(), "XiuLuoTriggerKey", XiuLuoGetCtrl("XiuLuoTriggerKey").Text)
    SavePreset(GetNowSelectPreset(), "XiuLuoXKey", XiuLuoGetCtrl("XiuLuoXKey").Text)
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey1", XiuLuoGetCtrl("XiuLuoWaveKey1").Text)
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey2", XiuLuoGetCtrl("XiuLuoWaveKey2").Text)
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey3", XiuLuoGetCtrl("XiuLuoWaveKey3").Text)
}

XiuLuoLoadConfig() {
    XiuLuoGetCtrl("XiuLuoTriggerKey").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoTriggerKey", "")
    XiuLuoGetCtrl("XiuLuoXKey").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoXKey", "X")
    XiuLuoGetCtrl("XiuLuoWaveKey1").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey1", "1")
    XiuLuoGetCtrl("XiuLuoWaveKey2").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey2", "2")
    XiuLuoGetCtrl("XiuLuoWaveKey3").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey3", "3")
}
