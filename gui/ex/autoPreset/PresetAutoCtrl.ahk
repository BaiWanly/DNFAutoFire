#Requires AutoHotkey v2.0

class PresetAutoCtrl {
    static OpenSkillRegionPick(*) {
        PresetRegionPickOpen("skill")
    }

    static Show(*) {
        global gMainGui, gSettingGui, gPresetAutoGui
        if IsObject(gSettingGui) && WinExist("ahk_id " gSettingGui.Hwnd) {
            gPresetAutoGui.Opt("+Owner" gSettingGui.Hwnd)
        } else if IsObject(gMainGui) {
            gPresetAutoGui.Opt("+Owner" gMainGui.Hwnd)
        }
        gPresetAutoGui.Title := GuiText.PresetAutoTitle()
        this.RefreshPreviews()
        GuiTheme_ShowFit(gPresetAutoGui)
    }

    static Hide() {
        global gPresetAutoGui
        PresetRegionPickCancelIfOpen()
        gPresetAutoGui.Hide()
    }

    static SaveAndClose(*) {
        PresetRegionPickCommitIfOpen()
        this.Hide()
    }

    static RefreshCalibratePreview() {
        global gPresetAutoCalPvW, gPresetAutoCalPvH
        pic := PresetAutoGetCtrl("CalPreview")
        if !IsObject(pic) {
            return
        }
        hint := PresetAutoGetCtrl("CalHint")
        cpath := PresetCalibrateIconGlobalPath()
        pic.Value := ""
        PresetAutoLockCalPreviewFrame(pic)
        if IsObject(hint) {
            hint.Text := GuiText.PresetAutoPreviewHint()
        }
        if FileExist(cpath) {
            tmp := A_Temp "\DAF_cal_fit_preview.png"
            if PresetSkillIcon_RenderFitPreviewToFile(cpath, gPresetAutoCalPvW, gPresetAutoCalPvH, tmp) && FileExist(tmp) {
                pic.Value := tmp
            } else {
                pic.Value := cpath
            }
            PresetAutoLockCalPreviewFrame(pic)
        }
    }

    static RefreshBackstepPreview() {
        global gPresetAutoBackstepPvW, gPresetAutoBackstepPvH
        pic := PresetAutoGetCtrl("BackstepPreview")
        if !IsObject(pic) {
            return
        }
        path := PresetBackstepIconGlobalPath()
        pic.Value := ""
        PresetAutoLockBackstepPreviewFrame(pic)
        if FileExist(path) {
            tmp := A_Temp "\DAF_backstep_fit_preview.png"
            if PresetSkillIcon_RenderFitPreviewToFile(path, gPresetAutoBackstepPvW, gPresetAutoBackstepPvH, tmp) && FileExist(tmp) {
                pic.Value := tmp
            } else {
                pic.Value := path
            }
            PresetAutoLockBackstepPreviewFrame(pic)
        }
    }

    static RefreshPreviews() {
        this.RefreshCalibratePreview()
        this.RefreshBackstepPreview()
    }

    static RefreshCalibratePreviewIfVisible() {
        global gPresetAutoGui
        if IsObject(gPresetAutoGui) && WinExist("ahk_id " gPresetAutoGui.Hwnd) {
            this.RefreshPreviews()
        }
    }

    static UpdateCalibrateIcon(*) {
        PresetRegionPickCommitCalibrateRegionIfOpen()
        try {
            PresetCalibrateIcon_UpdateCurrent()
            this.RefreshPreviews()
        } catch Error as e {
            MsgBox(e.Message,, "Icon!")
        }
    }

    static UpdateBackstepIcon(*) {
        PresetRegionPickCommitBackstepRegionIfOpen()
        try {
            PresetBackstepIcon_UpdateCurrent()
            this.RefreshPreviews()
        } catch Error as e {
            MsgBox(e.Message,, "Icon!")
        }
    }
}
