#Requires AutoHotkey v2.0

global gJianZongGui := Gui("-MinimizeBox -MaximizeBox")
global gJianZongCtrls := Map()
global gJianZongLayout := ExLayout.Window()

UiApplyWindow(gJianZongGui)
gJianZongGui.OnEvent("Escape", JianZongGuiEscape)
gJianZongGui.OnEvent("Close", JianZongGuiClose)

contentRight := 200
fieldX := 128
fieldW := contentRight - fieldX

UiExPageTitle(gJianZongGui, exText["JianZongPageTitle"], contentRight, gJianZongLayout, JianZongHelp)
UiLabel(gJianZongGui, UiLayoutRect(gJianZongLayout, ExLayout.MarginLeft(), 54, 110, 24), exText["JianZongDelay"])
UiEdit(gJianZongCtrls, gJianZongGui, "JianZongDelay", UiLayoutRect(gJianZongLayout, fieldX, 54, fieldW, ExLayout.ControlHeight(), "+Number -E0x200 Border"))
UiLabel(gJianZongGui, UiLayoutRect(gJianZongLayout, ExLayout.MarginLeft(), 86, 110, 24), exText["JianZongSkillKey"])
UiPressKeyEdit(gJianZongCtrls, gJianZongGui, "JianZongSkillKey", UiLayoutRect(gJianZongLayout, fieldX, 86, fieldW, ExLayout.ControlHeight()))
UiPlainButton(gJianZongGui, UiExSaveButtonRect(gJianZongLayout, 120, contentRight), exText["CommonSave"], JianZongSave, "primary")

JianZongGetCtrl(name) {
    global gJianZongCtrls
    return gJianZongCtrls.Has(name) ? gJianZongCtrls[name] : ""
}

ShowGuiJianZong(*) {
    global gMainGui, gJianZongGui, gJianZongLayout
    if IsObject(gMainGui) {
        gJianZongGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gJianZongGui.Title := exText["JianZongTitle"]
    gJianZongGui.Show("w" gJianZongLayout.Width() " h" gJianZongLayout.Height())
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

JianZongSaveConfig() {
    SavePreset(GetNowSelectPreset(), "JianZongSkillKey", UiPressKeyEdit_Value(JianZongGetCtrl("JianZongSkillKey")))
    SavePreset(GetNowSelectPreset(), "JianZongDelay", JianZongGetCtrl("JianZongDelay").Text)
}

JianZongLoadConfig() {
    JianZongGetCtrl("JianZongSkillKey").Text := LoadPreset(GetNowSelectPreset(), "JianZongSkillKey", "A")
    JianZongGetCtrl("JianZongDelay").Text := LoadPreset(GetNowSelectPreset(), "JianZongDelay", "200")
}
