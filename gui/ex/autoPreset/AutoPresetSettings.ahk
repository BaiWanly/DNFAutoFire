#Requires AutoHotkey v2.0

#Include ./AutoPresetSettingsCtrl.ahk
#Include ./PresetRegionPicker.ahk

global gAutoPresetSettingsMargin := 16
global gAutoPresetSettingsListW := 150
global gAutoPresetSettingsColumnGap := 16
global gAutoPresetSettingsRightW := gAutoPresetSettingsListW
global gAutoPresetSettingsRightX := gAutoPresetSettingsMargin + gAutoPresetSettingsListW + gAutoPresetSettingsColumnGap
global gAutoPresetSettingsSkillPvW := gAutoPresetSettingsRightW
global gAutoPresetSettingsSkillPvH := 84
global gAutoPresetSettingsPreviewX := gAutoPresetSettingsRightX
global gAutoPresetSettingsPreviewY := 160
global gAutoPresetSettingsActionGap := 8
global gAutoPresetSettingsHalfBtnW := (gAutoPresetSettingsSkillPvW - gAutoPresetSettingsActionGap) // 2
global gAutoPresetSettingsHalfBtnRightX := gAutoPresetSettingsPreviewX + gAutoPresetSettingsHalfBtnW + gAutoPresetSettingsActionGap
global gAutoPresetSettingsActionRowY := gAutoPresetSettingsPreviewY + gAutoPresetSettingsSkillPvH + 12
global gAutoPresetSettingsDetailY := gAutoPresetSettingsActionRowY + 36
global gAutoPresetSettingsDetailBtnH := 32
global gAutoPresetSettingsFooterY := gAutoPresetSettingsDetailY + 46
global gAutoPresetSettingsListY := 76
global gAutoPresetSettingsListBottom := gAutoPresetSettingsDetailY + gAutoPresetSettingsDetailBtnH
global gAutoPresetSettingsListH := gAutoPresetSettingsListBottom - gAutoPresetSettingsListY

global gAutoPresetSettingsGui := Gui("-MinimizeBox -MaximizeBox -Theme", GuiText.AutoPresetSettingsTitle())
global gAutoPresetSettingsCtrls := Map()
global gAutoPresetSelectedPreset := ""
global gAutoPresetSettingsSwitchUi := ""

GuiTheme_Apply(gAutoPresetSettingsGui)

gAutoPresetSettingsGui.OnEvent("Escape", AutoPresetSettingsGuiEscape)
gAutoPresetSettingsGui.OnEvent("Close", AutoPresetSettingsGuiClose)

ExWindowHost.AddInlineHeaderLeft(gAutoPresetSettingsGui, gAutoPresetSettingsMargin, 16, MainWindowText.PresetSkillButton(), AutoPresetSettingsOpenHelp, 120)
gAutoPresetSettingsGui.Add("Text", "x" gAutoPresetSettingsMargin " y52 w140 h20 +0x200", GuiText.AutoPresetPresetListLabel())
gAutoPresetSettingsCtrls["PresetList"] := GuiTheme_AddListBox(gAutoPresetSettingsGui, "AutoPresetPresetList", gAutoPresetSettingsMargin, gAutoPresetSettingsListY, gAutoPresetSettingsListW, gAutoPresetSettingsListH)
gAutoPresetSettingsCtrls["PresetList"].OnEvent("Change", AutoPresetSettingsPresetChanged)

gAutoPresetSettingsCtrls["SettingAutoPresetSwitch"] := gAutoPresetSettingsGui.Add("CheckBox", "vSettingAutoPresetSwitch Hidden x-2000 y-2000 w1 h1")
gAutoPresetSettingsSwitchUi := ToggleGdip(gAutoPresetSettingsGui, gAutoPresetSettingsRightX, 16, 36, 20)
gAutoPresetSettingsSwitchUi.OnClick(AutoPresetSettingsToggleEnabled)
gAutoPresetSettingsCtrls["SettingAutoPresetSwitchLabel"] := gAutoPresetSettingsGui.Add("Text", "x" (gAutoPresetSettingsRightX + 44) " y15 w90 h22 +0x200 +0x100", GuiText.SettingAutoPresetSwitch())
gAutoPresetSettingsCtrls["SettingAutoPresetSwitchLabel"].OnEvent("Click", AutoPresetSettingsToggleEnabled)
GuiTheme_RegisterHandCursor(gAutoPresetSettingsCtrls["SettingAutoPresetSwitchLabel"])
gAutoPresetSettingsGui.Add("Text", "x" gAutoPresetSettingsRightX " y52 w120 h20 +0x200", GuiText.PresetAutoHotkeyLabel())
gAutoPresetSettingsCtrls["AutoPresetHotkey"] := gAutoPresetSettingsGui.Add("Edit", "vAutoPresetHotkey x" gAutoPresetSettingsRightX " y72 w" gAutoPresetSettingsRightW " h22 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gAutoPresetSettingsCtrls["AutoPresetHotkey"], AutoPresetSettingsHotkeyAfterCapture)
gAutoPresetSettingsGui.Add("Text", "x" gAutoPresetSettingsRightX " y104 w120 h20 +0x200", GuiText.AutoPresetSelectedPresetLabel())
gAutoPresetSettingsCtrls["SelectedPresetName"] := gAutoPresetSettingsGui.Add("Edit", "vAutoPresetSelectedPresetName x" gAutoPresetSettingsRightX " y124 w" gAutoPresetSettingsRightW " h22 +ReadOnly -E0x200 Border")
gAutoPresetSettingsCtrls["SkillPreview"] := gAutoPresetSettingsGui.Add("Picture", "x" gAutoPresetSettingsPreviewX " y" gAutoPresetSettingsPreviewY " w" gAutoPresetSettingsSkillPvW " h" gAutoPresetSettingsSkillPvH, "")
gAutoPresetSettingsCtrls["UpdateSkill"] := GuiTheme_FlatBtn(gAutoPresetSettingsGui, "x" gAutoPresetSettingsPreviewX " y" gAutoPresetSettingsActionRowY " w" gAutoPresetSettingsHalfBtnW " h28", ExText.PresetSkillIconCapture(), AutoPresetSettingsUpdateSkillIcon, false)
gAutoPresetSettingsCtrls["DeleteSkill"] := GuiTheme_FlatBtn(gAutoPresetSettingsGui, "x" gAutoPresetSettingsHalfBtnRightX " y" gAutoPresetSettingsActionRowY " w" gAutoPresetSettingsHalfBtnW " h28", ExText.PresetSkillIconDelete(), AutoPresetSettingsDeleteSkillIcon, false)
gAutoPresetSettingsCtrls["OpenDetail"] := GuiTheme_FlatBtn(gAutoPresetSettingsGui, "x" gAutoPresetSettingsRightX " y" gAutoPresetSettingsDetailY " w" gAutoPresetSettingsSkillPvW " h" gAutoPresetSettingsDetailBtnH, GuiText.SettingAutoPresetButton(), AutoPresetSettingsOpenDetail, false)
ExWindowHost.AddAutoFooter(gAutoPresetSettingsGui, gAutoPresetSettingsFooterY, ExText.SaveButton(), AutoPresetSettingsSave)

AutoPresetSettingsGetCtrl(name) {
    global gAutoPresetSettingsCtrls
    return gAutoPresetSettingsCtrls.Has(name) ? gAutoPresetSettingsCtrls[name] : ""
}

AutoPresetSettingsLockSkillPreviewFrame(pic) {
    global gAutoPresetSettingsPreviewX, gAutoPresetSettingsPreviewY, gAutoPresetSettingsSkillPvW, gAutoPresetSettingsSkillPvH
    if IsObject(pic) {
        pic.Move(gAutoPresetSettingsPreviewX, gAutoPresetSettingsPreviewY, gAutoPresetSettingsSkillPvW, gAutoPresetSettingsSkillPvH)
    }
}

ShowGuiAutoPresetSettings(*) => AutoPresetSettingsCtrl.Show()
HideGuiAutoPresetSettings(*) => AutoPresetSettingsCtrl.Hide()
AutoPresetSettingsGuiEscape(*) => AutoPresetSettingsCtrl.Hide()
AutoPresetSettingsGuiClose(*) => AutoPresetSettingsCtrl.Hide()
AutoPresetSettingsToggleEnabled(*) => AutoPresetSettingsCtrl.ToggleEnabled()
AutoPresetSettingsPresetChanged(*) => AutoPresetSettingsCtrl.OnPresetSelectionChange()
AutoPresetSettingsHotkeyAfterCapture(key) => AutoPresetSettingsCtrl.AfterHotkeyCapture(key)
AutoPresetSettingsSyncPresetList(*) => AutoPresetSettingsCtrl.SyncPresetList()
AutoPresetSettingsGetSelectedPreset() => AutoPresetSettingsCtrl.GetSelectedPreset()
AutoPresetSettingsOpenHelp(*) => AutoPresetSettingsCtrl.OpenHelp()
AutoPresetSettingsOpenDetail(*) => AutoPresetSettingsCtrl.OpenDetailSettings()
AutoPresetSettingsUpdateSkillIcon(*) => AutoPresetSettingsCtrl.UpdateSkillIcon()
AutoPresetSettingsDeleteSkillIcon(*) => AutoPresetSettingsCtrl.DeleteSkillIcon()
AutoPresetSettingsSave(*) => AutoPresetSettingsCtrl.SaveAndClose()
