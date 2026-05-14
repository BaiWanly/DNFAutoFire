#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gAutoRunGui := 0
global gAutoRunCtrls := Map()

GuiRegistry.Define("AutoRun", AutoRunBuildGui)

AutoRunBuildGui() {
    global gAutoRunGui, gAutoRunCtrls
    gAutoRunGui := Gui("+ToolWindow -Theme")
    gAutoRunCtrls := Map()
    GuiTheme_Apply(gAutoRunGui)
    gAutoRunGui.OnEvent("Escape", AutoRunGuiEscape)
    gAutoRunGui.OnEvent("Close", AutoRunGuiClose)
    gAutoRunGui.Add("Text", "x16 y54 w72 h26 +0x200", ExText.AutoRunLeftLabel())
    gAutoRunCtrls["AutoRunLeftKey"] := gAutoRunGui.Add("Edit", "vAutoRunLeftKey x96 y54 w168 h24 +ReadOnly -WantCtrlA -E0x200 Border")
    RegisterEditPressKeyCapture(gAutoRunCtrls["AutoRunLeftKey"], GetKeycode.AfterCaptureEdit.Bind(gAutoRunCtrls["AutoRunLeftKey"]))
    gAutoRunGui.Add("Text", "x16 y94 w72 h26 +0x200", ExText.AutoRunRightLabel())
    gAutoRunCtrls["AutoRunRightKey"] := gAutoRunGui.Add("Edit", "vAutoRunRightKey x96 y94 w168 h24 +ReadOnly -WantCtrlA -E0x200 Border")
    RegisterEditPressKeyCapture(gAutoRunCtrls["AutoRunRightKey"], GetKeycode.AfterCaptureEdit.Bind(gAutoRunCtrls["AutoRunRightKey"]))
    ExWindowHost.AddAutoFooter(gAutoRunGui, 138, ExText.SaveButton(), AutoRunSave, 16, 6, 36)
    ExWindowHost.AddInlineHeaderLeft(gAutoRunGui, 16, 16, ExWindowHost.MakeHeaderTitle(ExText.AutoRunTitle()), AutoRunHelp, 120, 26, 6)
    return gAutoRunGui
}

AutoRunGetCtrl(name) {
    global gAutoRunCtrls
    GuiRegistry.Ensure("AutoRun")
    return gAutoRunCtrls.Has(name) ? gAutoRunCtrls[name] : ""
}

ShowGuiAutoRun(*) {
    global gAutoRunGui
    gAutoRunGui := GuiRegistry.Ensure("AutoRun")
    ExWindowHost.ShowOwnedFit(gAutoRunGui, ExText.AutoRunTitle())
    AutoRunLoadConfig()
}

HideGuiAutoRun() {
    if !GuiRegistry.IsBuilt("AutoRun") {
        return
    }
    ExWindowHost.HideOwned(gAutoRunGui)
}

AutoRunGuiEscape(*) {
    HideGuiAutoRun()
}

AutoRunGuiClose(*) {
    HideGuiAutoRun()
}

AutoRunHelp(*) {
    ExWindowHost.ShowHelp(ExText.AutoRunHelp(), ExText.AutoRunHelpTitle(), gAutoRunGui)
}

AutoRunSave(*) {
    SavePreset(GetNowSelectPreset(), "AutoRunLeftKey", AutoRunGetCtrl("AutoRunLeftKey").Text)
    SavePreset(GetNowSelectPreset(), "AutoRunRightKey", AutoRunGetCtrl("AutoRunRightKey").Text)
    HideGuiAutoRun()
}

AutoRunLoadConfig() {
    l := GetKeycode.CanonMainKey(Trim(LoadPreset(GetNowSelectPreset(), "AutoRunLeftKey", "Left")))
    r := GetKeycode.CanonMainKey(Trim(LoadPreset(GetNowSelectPreset(), "AutoRunRightKey", "Right")))
    AutoRunGetCtrl("AutoRunLeftKey").Text := l != "" ? l : "Left"
    AutoRunGetCtrl("AutoRunRightKey").Text := r != "" ? r : "Right"
}
