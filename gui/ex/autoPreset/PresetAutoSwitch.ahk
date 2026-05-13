#Requires AutoHotkey v2.0

#Include ./PresetAutoCtrl.ahk

global gPresetAutoGui := Gui("-MinimizeBox -MaximizeBox -Theme", GuiText.AutoPresetSettingsTitle())
global gPresetAutoCtrls := Map()
global gPresetAutoHeaderY := 16
global gPresetAutoCalPvW := 160
global gPresetAutoCalPvH := 160
global gPresetAutoBackstepPvW := 80
global gPresetAutoBackstepPvH := 160
global gPresetAutoPreviewGap := 12
global gPresetAutoPreviewX := 16
global gPresetAutoPreviewY := 48
global gPresetAutoBackstepPvX := gPresetAutoPreviewX + gPresetAutoCalPvW + gPresetAutoPreviewGap
global gPresetAutoBackstepPvY := gPresetAutoPreviewY
global gPresetAutoHintY := gPresetAutoPreviewY + gPresetAutoCalPvH + 10
global gPresetAutoActionW := gPresetAutoCalPvW + gPresetAutoPreviewGap + gPresetAutoBackstepPvW
global gPresetAutoActionY := gPresetAutoHintY + 44
global gPresetAutoHalfBtnGap := 8
global gPresetAutoHalfBtnW := (gPresetAutoActionW - gPresetAutoHalfBtnGap) // 2
global gPresetAutoHalfBtnRightX := gPresetAutoPreviewX + gPresetAutoHalfBtnW + gPresetAutoHalfBtnGap
global gRegionPickGui := false
global gRegionPickKeyHook := false
global gRegionPickNCHook := false
global gRegionPickNCCalcHook := false
global gRegionPickKind := "skill"

GuiTheme_Apply(gPresetAutoGui)

gPresetAutoGui.OnEvent("Escape", PresetAutoGuiEscape)
gPresetAutoGui.OnEvent("Close", PresetAutoGuiClose)

PresetSkillOpenSkillRegionPick(*) => PresetAutoCtrl.OpenSkillRegionPick()

ExWindowHost.AddInlineHeaderLeft(gPresetAutoGui, 16, gPresetAutoHeaderY, GuiText.PresetAutoHeaderTitle(), PresetAutoHelp, 120)
gPresetAutoCtrls["CalPreview"] := gPresetAutoGui.Add("Picture", "x" gPresetAutoPreviewX " y" gPresetAutoPreviewY " w" gPresetAutoCalPvW " h" gPresetAutoCalPvH, "")
gPresetAutoCtrls["BackstepPreview"] := gPresetAutoGui.Add("Picture", "x" gPresetAutoBackstepPvX " y" gPresetAutoBackstepPvY " w" gPresetAutoBackstepPvW " h" gPresetAutoBackstepPvH, "")
gPresetAutoCtrls["CalHint"] := gPresetAutoGui.Add("Text", "x" gPresetAutoPreviewX " y" gPresetAutoHintY " w" gPresetAutoActionW " h44", "")
GuiTheme_FlatBtn(gPresetAutoGui, "x" gPresetAutoPreviewX " y" gPresetAutoActionY " w" gPresetAutoActionW " h28", GuiText.PresetAutoPickSkillRegion(), PresetSkillOpenSkillRegionPick, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x" gPresetAutoPreviewX " y" (gPresetAutoActionY + 32) " w" gPresetAutoActionW " h28", GuiText.PresetAutoPickCalibrateRegion(), (*) => PresetRegionPickOpen("calibrate"), false)
GuiTheme_FlatBtn(gPresetAutoGui, "x" gPresetAutoPreviewX " y" (gPresetAutoActionY + 64) " w" gPresetAutoActionW " h28", GuiText.PresetAutoPickBackstepRegion(), (*) => PresetRegionPickOpen("backstep"), false)
GuiTheme_FlatBtn(gPresetAutoGui, "x" gPresetAutoPreviewX " y" (gPresetAutoActionY + 96) " w" gPresetAutoHalfBtnW " h28", GuiText.PresetAutoUpdateCalibrate(), PresetAutoUpdateCalibrateIcon, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x" gPresetAutoHalfBtnRightX " y" (gPresetAutoActionY + 96) " w" gPresetAutoHalfBtnW " h28", GuiText.PresetAutoUpdateBackstep(), PresetAutoUpdateBackstepIcon, false)
ExWindowHost.AddAutoFooter(gPresetAutoGui, gPresetAutoActionY + 122, GuiText.SaveButton(), PresetAutoSaveClose)

PresetAutoGetCtrl(name) {
    global gPresetAutoCtrls
    return gPresetAutoCtrls.Has(name) ? gPresetAutoCtrls[name] : ""
}

PresetAutoLockCalPreviewFrame(pic) {
    global gPresetAutoPreviewX, gPresetAutoPreviewY, gPresetAutoCalPvW, gPresetAutoCalPvH
    if IsObject(pic) {
        pic.Move(gPresetAutoPreviewX, gPresetAutoPreviewY, gPresetAutoCalPvW, gPresetAutoCalPvH)
    }
}

PresetAutoLockBackstepPreviewFrame(pic) {
    global gPresetAutoBackstepPvX, gPresetAutoBackstepPvY, gPresetAutoBackstepPvW, gPresetAutoBackstepPvH
    if IsObject(pic) {
        pic.Move(gPresetAutoBackstepPvX, gPresetAutoBackstepPvY, gPresetAutoBackstepPvW, gPresetAutoBackstepPvH)
    }
}

ShowGuiPresetAutoSwitch(*) => PresetAutoCtrl.Show()
HideGuiPresetAutoSwitch() => PresetAutoCtrl.Hide()
PresetAutoGuiEscape(*) => PresetAutoCtrl.Hide()
PresetAutoGuiClose(*) => PresetAutoCtrl.Hide()
PresetAutoSaveClose(*) => PresetAutoCtrl.SaveAndClose()
PresetAutoRefreshCalibratePreview() => PresetAutoCtrl.RefreshCalibratePreview()
PresetAutoRefreshCalibratePreviewIfVisible() => PresetAutoCtrl.RefreshCalibratePreviewIfVisible()
PresetAutoUpdateCalibrateIcon(*) => PresetAutoCtrl.UpdateCalibrateIcon()
PresetAutoUpdateBackstepIcon(*) => PresetAutoCtrl.UpdateBackstepIcon()
PresetAutoHelp(*) => ExWindowHost.ShowHelp(GuiText.SettingAutoPresetHelp(), GuiText.PresetAutoHelpTitle(), gPresetAutoGui)

#Include ./PresetRegionPicker.ahk
