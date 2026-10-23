#Requires AutoHotkey v2.0

global gGuanYuGui := Gui("-MinimizeBox -MaximizeBox")
global gGuanYuCtrls := Map()
global gGuanYuLayout := ExLayout.Window()

UiApplyWindow(gGuanYuGui)
gGuanYuGui.OnEvent("Escape", GuanYuGuiEscape)
gGuanYuGui.OnEvent("Close", GuanYuGuiClose)

global gGuanYuKeys := UiSkillKeyEditor(gGuanYuGui, gGuanYuCtrls, "GuanYu", exText["GuanYuListTitle"], exText["GuanYuShotTitle"], exText["GuanYuAdd"], exText["GuanYuDelete"], GuanYuSave, GuanYuHelp, exText["CommonSave"], exText["GuanYuPageTitle"], exText["GuanYuDelayTitle"], "", gGuanYuLayout)

GuanYuGetCtrl(name) {
    global gGuanYuCtrls
    return gGuanYuCtrls.Has(name) ? gGuanYuCtrls[name] : ""
}

ShowGuiGuanYu(*) {
    global gMainGui, gGuanYuGui, gGuanYuLayout
    if IsObject(gMainGui) {
        gGuanYuGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gGuanYuGui.Title := exText["GuanYuTitle"]
    gGuanYuGui.Show("w" gGuanYuLayout.Width() " h" gGuanYuLayout.Height())
    GuanYuLoadConfig()
    DisableGuiMain()
}

HideGuiGuanYu() {
    gGuanYuGui.Hide()
    EnableGuiMain()
}

GuanYuGuiEscape(*) {
    GuanYuSave()
}

GuanYuGuiClose(*) {
    GuanYuSave()
}

GuanYuHelp(*) {
    UiHelpMsgBox(exText["GuanYuHelp"], exText["GuanYuHelpTitle"])
}

GuanYuSave(*) {
    GuanYuSaveConfig()
    HideGuiGuanYu()
}

GuanYuSaveConfig() {
    global gGuanYuKeys
    cfg := PresetConfigSection(GetNowSelectPreset())
    delay := Round((Trim(GuanYuGetCtrl("GuanYuDelay").Text) = "" ? ConfigDefaults.Preset["GuanYuDelay"] : GuanYuGetCtrl("GuanYuDelay").Text) + 0)
    delay := Max(0, Min(500, delay))
    GuanYuGetCtrl("GuanYuDelay").Text := delay
    cfg.Save(Map(
        "GuanYuSkillKeys", KeyListToString(gGuanYuKeys.items),
        "GuanYuShotKey", UiPressKeyEdit_Value(GuanYuGetCtrl("GuanYuShotKey")),
        "GuanYuDelay", delay
    ))
}

GuanYuLoadConfig() {
    global gGuanYuKeys
    cfg := PresetConfigSection(GetNowSelectPreset())
    gGuanYuKeys.Load(cfg.Get("GuanYuSkillKeys"))
    GuanYuGetCtrl("GuanYuShotKey").Text := cfg.Get("GuanYuShotKey")
    GuanYuGetCtrl("GuanYuDelay").Text := Max(0, Min(500, Round(cfg.Get("GuanYuDelay") + 0)))
}
