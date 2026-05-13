#Requires AutoHotkey v2.0

#Include ./SettingController.ahk
#Include ../ex/ExWindowHost.ahk

global gSettingGui := Gui("-MinimizeBox -MaximizeBox -Theme")
global gSettingCtrls := Map()
global gSettingSwitchUi := Map()
global __SettingGeneralCtrls := []
global __SettingAboutCtrls := []
global gSettingSuppressQuickKeyChange := false

GuiTheme_Apply(gSettingGui)

gSettingGui.OnEvent("Escape", SettingGuiEscape)
gSettingGui.OnEvent("Close", SettingGuiClose)

gSettingCtrls["NavGeneral"] := GuiTheme_FlatBtn(gSettingGui, "x16 y16 w118 h28", GuiText.SettingNavGeneral(), (*) => SettingShowPage(1), false)
gSettingCtrls["NavAbout"] := GuiTheme_FlatBtn(gSettingGui, "x142 y16 w118 h28", GuiText.SettingNavAbout(), (*) => SettingShowPage(2), false)

SettingAddSwitchRow("SettingAutoStart", 58, GuiText.SettingAutoStart())
SettingAddSwitchRow("SettingOnSystemStart", 94, GuiText.SettingOnSystemStart())
SettingAddSwitchRow("SettingBlockWin", 130, GuiText.SettingBlockWin())
__SettingGeneralCtrls.Push(gSettingGui.Add("Text", "x16 y166 w104 h24 +0x200", GuiText.SettingQuickSwitchLabel()))
gSettingCtrls["SettingQuickChangeHotKey"] := gSettingGui.Add("Edit", "vSettingQuickChangeHotKey x126 y166 w112 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditClickHandler(gSettingCtrls["SettingQuickChangeHotKey"], SettingBeginQuickChangeHotKeyCapture)
GuiTheme_FlatChromeHwnd(gSettingCtrls["SettingQuickChangeHotKey"].Hwnd)
__SettingGeneralCtrls.Push(gSettingCtrls["SettingQuickChangeHotKey"])
gSettingCtrls["SettingQuickChangeHotKeyCapture"] := gSettingGui.Add("Hotkey", "vSettingQuickChangeHotKeyCapture x-2000 y-2000 w1 h1")
gSettingCtrls["SettingQuickChangeHotKeyCapture"].OnEvent("Change", SettingQuickChangeHotKeyCaptureChanged)
ExWindowHost.AddAutoFooter(gSettingGui, 206, GuiText.SaveButton(), SettingSave, 16, 8, 36)

__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y56 w352 h52", GuiText.AboutApp()))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y104 w352 h22 +0x200", GuiText.AboutOriginalPost()))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y126 w352 h40", "<a href=`"https://bbs.colg.cn/thread-8894989-1-1.html`">https://bbs.colg.cn/thread-8894989-1-1.html</a>"))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y174 w352 h22 +0x200", GuiText.AboutReleasePost()))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y196 w352 h40", "<a href=`"https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722`">https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722</a>"))

for ctrl in __SettingAboutCtrls {
    ctrl.Visible := false
}

SettingShowPage(page) => SettingController.ShowPage(page)

SettingGetCtrl(name) {
    global gSettingCtrls
    return gSettingCtrls.Has(name) ? gSettingCtrls[name] : ""
}

SettingGuiEscape(*) => SettingController.Hide()
SettingGuiClose(*) => SettingController.Hide()
ShowGuiSetting(*) => SettingController.Show()
ShowGuiSettingAbout(*) => SettingController.ShowAbout()
HideGuiSetting() => SettingController.Hide()
SettingSave(*) => SettingController.Save()
SettingLoad() => SettingController.Load()
SettingBeginQuickChangeHotKeyCapture() => SettingController.BeginQuickChangeHotKeyCapture()
SettingQuickChangeHotKeyCaptureChanged(*) => SettingController.OnQuickChangeHotKeyCaptureChanged()
SettingNow() => SettingController.ApplyNow()
SettingBlockWin(*) => SettingController.BlockWin()
SettingToggle(name, *) => SettingController.ToggleSwitch(name)

SettingAddSwitchRow(name, y, label) {
    global gSettingGui, gSettingCtrls, gSettingSwitchUi, __SettingGeneralCtrls
    toggleX := 16
    labelX := 60
    labelW := 208
    gSettingCtrls[name] := gSettingGui.Add("CheckBox", "v" name " Hidden x-2000 y-2000 w1 h1")
    ui := ToggleGdip(gSettingGui, toggleX, y + 2, 36, 20)
    ui.OnClick(SettingToggle.Bind(name))
    gSettingSwitchUi[name] := ui
    labelCtrl := gSettingGui.Add("Text", "x" labelX " y" y " w" labelW " h24 +0x200 +0x100", label)
    labelCtrl.OnEvent("Click", SettingToggle.Bind(name))
    GuiTheme_RegisterHandCursor(labelCtrl)
    __SettingGeneralCtrls.Push(ui.ctrl)
    __SettingGeneralCtrls.Push(labelCtrl)
}

global _AutoStart := LoadConfig("SettingAutoStart", false)
global _OnSystemStart := LoadConfig("SettingOnSystemStart", false)
global _BlockWin := LoadConfig("SettingBlockWin", false)

if (_BlockWin) {
    Hotkey("$*LWin", SettingBlockWin, "On")
    Hotkey("$*RWin", SettingBlockWin, "On")
}
