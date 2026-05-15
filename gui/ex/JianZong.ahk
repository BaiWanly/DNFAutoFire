#Requires AutoHotkey v2.0

global gJianZongGui := Gui("+ToolWindow")
global gJianZongCtrls := Map()

UiApplyWindow(gJianZongGui)
gJianZongGui.OnEvent("Escape", JianZongGuiEscape)
gJianZongGui.OnEvent("Close", JianZongGuiClose)

xForm := UiColumnX(1)
UiLabel(gJianZongGui, UiRect(xForm, UiRowY(1), 80, 20), "延迟时间(ms)")
UiEdit(gJianZongCtrls, gJianZongGui, "JianZongDelay", UiRect(xForm, UiRowY(2), 80, 20, "+Number"))
UiLabel(gJianZongGui, UiRect(xForm, UiRowY(3), 80, 20), "帝国剑术键")
UiEdit(gJianZongCtrls, gJianZongGui, "JianZongSkillKey", UiRect(xForm, UiRowY(4), 80, 20, "+ReadOnly"))
UiPlainButton(gJianZongGui, UiRect(xForm, UiRowY(5), 80, 22), "设置按键", JianZongSetSkillKey)
UiPlainButton(gJianZongGui, UiRect(xForm, UiRowY(6), 80, 26), "保存", JianZongSave)
UiHelpButton(gJianZongGui, UiRect(94, UiRowY(1), 18, 18), JianZongHelp)

JianZongGetCtrl(name) {
    global gJianZongCtrls
    return gJianZongCtrls.Has(name) ? gJianZongCtrls[name] : ""
}

ShowGuiJianZong(*) {
    global gMainGui, gJianZongGui
    if IsObject(gMainGui) {
        gJianZongGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gJianZongGui.Title := "太宗帝剑延迟"
    gJianZongGui.Show("w120 h160")
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
    MsgBox("1、设置游戏中帝国剑术的技能按键`n2、设置帝国剑术第一刀后的延迟时间，单位毫秒键`n3、保存配置，启动连发并使用`n`nPS：该按键不能打开连发，否则功能失效", "如何使用太宗帝剑延迟", "Iconi")
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
