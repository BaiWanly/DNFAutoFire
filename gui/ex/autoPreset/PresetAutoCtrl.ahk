#Requires AutoHotkey v2.0

class PresetAutoCtrl {
    static OpenSkillRegionPick(*) {
        PresetRegionPickOpen("skill")
    }

    static Show(*) {
        global gMainGui, gSettingGui, gPresetAutoGui
        gPresetAutoGui := GuiRegistry.Ensure("PresetAuto")
        if IsObject(gSettingGui) && WinExist("ahk_id " gSettingGui.Hwnd) {
            gPresetAutoGui.Opt("+Owner" gSettingGui.Hwnd)
        } else if IsObject(gMainGui) {
            gPresetAutoGui.Opt("+Owner" gMainGui.Hwnd)
        }
        gPresetAutoGui.Title := GuiText.AutoPresetSettingsTitle()
        this.RefreshPreviews()
        GuiTheme_ShowFit(gPresetAutoGui)
    }

    static Hide() {
        if !GuiRegistry.IsBuilt("PresetAuto") {
            return
        }
        PresetRegionPickCommitIfOpen()
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

    static RefreshTownPreview() {
        global gPresetAutoTownPvW, gPresetAutoTownPvH
        pic := PresetAutoGetCtrl("TownPreview")
        if !IsObject(pic) {
            return
        }
        path := PresetTownIconGlobalPath()
        pic.Value := ""
        PresetAutoLockTownPreviewFrame(pic)
        if FileExist(path) {
            tmp := A_Temp "\DAF_town_fit_preview.png"
            if PresetSkillIcon_RenderFitPreviewToFile(path, gPresetAutoTownPvW, gPresetAutoTownPvH, tmp) && FileExist(tmp) {
                pic.Value := tmp
            } else {
                pic.Value := path
            }
            PresetAutoLockTownPreviewFrame(pic)
        }
    }

    static RefreshPreviews() {
        this.RefreshCalibratePreview()
        this.RefreshTownPreview()
    }

    static RefreshCalibratePreviewIfVisible() {
        global gPresetAutoGui
        if IsObject(gPresetAutoGui) && WinExist("ahk_id " gPresetAutoGui.Hwnd) {
            this.RefreshPreviews()
        }
    }

    static UpdateCalibrateIcon(*) {
        PresetRegionPickCommitIfOpen()
        try {
            PresetCalibrateIcon_UpdateCurrent()
            this.RefreshPreviews()
        } catch Error as e {
            MsgBox(e.Message,, "Icon!")
        }
    }

    static UpdateTownIcon(*) {
        PresetRegionPickCommitIfOpen()
        try {
            PresetTownIcon_UpdateCurrent()
            this.RefreshPreviews()
        } catch Error as e {
            MsgBox(e.Message,, "Icon!")
        }
    }
}
