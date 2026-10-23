#Requires AutoHotkey v2.0

global gLvRenGui := Gui("-MinimizeBox -MaximizeBox")
global gLvRenCtrls := Map()
global gLvRenLayout := ExLayout.Window()

UiApplyWindow(gLvRenGui)
gLvRenGui.OnEvent("Escape", LvRenGuiEscape)
gLvRenGui.OnEvent("Close", LvRenGuiClose)

global gLvRenKeys := UiSkillKeyEditor(gLvRenGui, gLvRenCtrls, "LvRen", exText["LvRenListTitle"], exText["LvRenShotTitle"], exText["LvRenAdd"], exText["LvRenDelete"], LvRenSave, LvRenHelp, exText["CommonSave"], exText["LvRenPageTitle"], "", "", gLvRenLayout)

LvRenGetCtrl(name) {
    global gLvRenCtrls
    return gLvRenCtrls.Has(name) ? gLvRenCtrls[name] : ""
}

ShowGuiLvRen(*) {
    global gMainGui, gLvRenGui, gLvRenLayout
    if IsObject(gMainGui) {
        gLvRenGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gLvRenGui.Title := exText["LvRenTitle"]
    gLvRenGui.Show("w" gLvRenLayout.Width() " h" gLvRenLayout.Height())
    LvRenLoadConfig()
    DisableGuiMain()
}

HideGuiLvRen() {
    gLvRenGui.Hide()
    EnableGuiMain()
}

LvRenGuiEscape(*) {
    LvRenSave()
}

LvRenGuiClose(*) {
    LvRenSave()
}

LvRenHelp(*) {
    UiHelpMsgBox(exText["LvRenHelp"], exText["LvRenHelpTitle"])
}

LvRenSave(*) {
    LvRenSaveConfig()
    HideGuiLvRen()
}

LvRenSaveConfig() {
    global gLvRenKeys
    cfg := PresetConfigSection(GetNowSelectPreset())
    cfg.Save(Map(
        "LvRenSkillKeys", KeyListToString(gLvRenKeys.items),
        "LvRenShotKey", UiPressKeyEdit_Value(LvRenGetCtrl("LvRenShotKey"))
    ))
}

LvRenLoadConfig() {
    global gLvRenKeys
    cfg := PresetConfigSection(GetNowSelectPreset())
    gLvRenKeys.Load(cfg.Get("LvRenSkillKeys"))
    LvRenGetCtrl("LvRenShotKey").Text := cfg.Get("LvRenShotKey")
}
