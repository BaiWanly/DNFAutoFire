#Requires AutoHotkey v2.0

global gZhanFaGui := Gui("-MinimizeBox -MaximizeBox")
global gZhanFaCtrls := Map()
global gZhanFaLayout := ExLayout.Window()

UiApplyWindow(gZhanFaGui)
gZhanFaGui.OnEvent("Escape", ZhanFaGuiEscape)
gZhanFaGui.OnEvent("Close", ZhanFaGuiClose)

global gZhanFaKeys := UiSkillKeyEditor(gZhanFaGui, gZhanFaCtrls, "ZhanFa", exText["ZhanFaListTitle"], exText["ZhanFaShotTitle"], exText["ZhanFaAdd"], exText["ZhanFaDelete"], ZhanFaSave, ZhanFaHelp, exText["CommonSave"], exText["ZhanFaPageTitle"], "", exText["ZhanFaBigShotTitle"], gZhanFaLayout)

ZhanFaGetCtrl(name) {
    global gZhanFaCtrls
    return gZhanFaCtrls.Has(name) ? gZhanFaCtrls[name] : ""
}

ShowGuiZhanFa(*) {
    global gMainGui, gZhanFaGui, gZhanFaLayout
    if IsObject(gMainGui) {
        gZhanFaGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gZhanFaGui.Title := exText["ZhanFaTitle"]
    gZhanFaGui.Show("w" gZhanFaLayout.Width() " h" gZhanFaLayout.Height())
    ZhanFaLoadConfig()
    DisableGuiMain()
}

HideGuiZhanFa() {
    gZhanFaGui.Hide()
    EnableGuiMain()
}

ZhanFaGuiEscape(*) {
    ZhanFaSave()
}

ZhanFaGuiClose(*) {
    ZhanFaSave()
}

ZhanFaHelp(*) {
    UiHelpMsgBox(exText["ZhanFaHelp"], exText["ZhanFaHelpTitle"], exText["ZhanFaHelpExtra"], exText["ZhanFaHelpExtraTitle"])
}

ZhanFaSave(*) {
    ZhanFaSaveConfig()
    HideGuiZhanFa()
}

ZhanFaSaveConfig() {
    global gZhanFaKeys
    cfg := PresetConfigSection(GetNowSelectPreset())
    cfg.Save(Map(
        "ZhanFaSkillKeys", KeyListToString(gZhanFaKeys.items),
        "ZhanFaShotKey", UiPressKeyEdit_Value(ZhanFaGetCtrl("ZhanFaShotKey")),
        "ZhanFaBigShotKey", UiPressKeyEdit_Value(ZhanFaGetCtrl("ZhanFaShotKey2"))
    ))
}

ZhanFaLoadConfig() {
    global gZhanFaKeys
    cfg := PresetConfigSection(GetNowSelectPreset())
    gZhanFaKeys.Load(cfg.Get("ZhanFaSkillKeys"))
    ZhanFaGetCtrl("ZhanFaShotKey").Text := cfg.Get("ZhanFaShotKey")
    ZhanFaGetCtrl("ZhanFaShotKey2").Text := cfg.Get("ZhanFaBigShotKey")
}
