#Requires AutoHotkey v2.0

global gJianZongGui := Gui("-MinimizeBox -MaximizeBox")
global gJianZongCtrls := Map()

UiApplyWindow(gJianZongGui)
gJianZongGui.OnEvent("Escape", JianZongGuiEscape)
gJianZongGui.OnEvent("Close", JianZongGuiClose)

UiExPageTitle(gJianZongGui, exText["JianZongPageTitle"], 220)
UiLabel(gJianZongGui, UiRect(16, 54, 110, 24), exText["JianZongDelay"])
UiEdit(gJianZongCtrls, gJianZongGui, "JianZongDelay", UiRect(128, 54, 72, 24, "+Number -E0x200 Border"))
UiLabel(gJianZongGui, UiRect(16, 86, 110, 24), exText["JianZongSkillKey"])
UiEdit(gJianZongCtrls, gJianZongGui, "JianZongSkillKey", UiRect(128, 86, 72, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gJianZongGui, UiRect(16, 118, 184, 26), exText["SetKey"], JianZongSetSkillKey)
UiPlainButton(gJianZongGui, UiRect(16, 152, 184, 32), exText["CommonSave"], JianZongSave, "primary")
UiHelpButton(gJianZongGui, UiRect(188, 16, 22, 22), JianZongHelp)

JianZongGetCtrl(name) {
    global gJianZongCtrls
    return gJianZongCtrls.Has(name) ? gJianZongCtrls[name] : ""
}

ShowGuiJianZong(*) {
    global gMainGui, gJianZongGui
    if IsObject(gMainGui) {
        gJianZongGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gJianZongGui.Title := exText["JianZongTitle"]
    gJianZongGui.Show("w220 h200")
    JianZongLoadConfig()
    DisableGuiMain()
}

HideGuiJianZong() {
    gJianZongGui.Hide()
    EnableGuiMain()
}

JianZongGuiEscape(*) {
    JianZongSave()
}

JianZongGuiClose(*) {
    JianZongSave()
}

JianZongHelp(*) {
    UiHelpMsgBox(exText["JianZongHelp"], exText["JianZongHelpTitle"])
}

JianZongSave(*) {
    JianZongSaveConfig()
    HideGuiJianZong()
}

JianZongSetSkillKey(*) {
    JianZongGetCtrl("JianZongSkillKey").Text := GetPressKey()
}

JianZongSaveConfig() {
    SavePreset(GetNowSelectPreset(), "JianZongSkillKey", JianZongGetCtrl("JianZongSkillKey").Text)
    SavePreset(GetNowSelectPreset(), "JianZongDelay", JianZongGetCtrl("JianZongDelay").Text)
}

JianZongLoadConfig() {
    JianZongGetCtrl("JianZongSkillKey").Text := LoadPreset(GetNowSelectPreset(), "JianZongSkillKey", "A")
    JianZongGetCtrl("JianZongDelay").Text := LoadPreset(GetNowSelectPreset(), "JianZongDelay", "200")
}
