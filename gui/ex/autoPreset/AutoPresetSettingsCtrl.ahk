#Requires AutoHotkey v2.0

class AutoPresetSettingsCtrl {
    static Show(*) {
        global gMainGui, gSettingGui, gAutoPresetSettingsGui
        gAutoPresetSettingsGui := GuiRegistry.Ensure("AutoPresetSettings")
        if IsObject(gSettingGui) && WinExist("ahk_id " gSettingGui.Hwnd) {
            gAutoPresetSettingsGui.Opt("+Owner" gSettingGui.Hwnd)
        } else if IsObject(gMainGui) {
            gAutoPresetSettingsGui.Opt("+Owner" gMainGui.Hwnd)
        }
        gAutoPresetSettingsGui.Title := GuiText.AutoPresetSettingsTitle()
        this.Load()
        GuiTheme_ShowFit(gAutoPresetSettingsGui)
    }

    static Hide(*) {
        if !GuiRegistry.IsBuilt("AutoPresetSettings") {
            return
        }
        PresetRegionPickCommitIfOpen()
        gAutoPresetSettingsGui.Hide()
    }

    static SaveAndClose(*) {
        this.Hide()
    }

    static Load() {
        ctrl := AutoPresetSettingsGetCtrl("SettingAutoPresetSwitch")
        if IsObject(ctrl) {
            ctrl.Value := Trim(LoadConfig("SettingAutoPresetSwitch", "0")) = "1"
        }
        hotkeyCtrl := AutoPresetSettingsGetCtrl("AutoPresetHotkey")
        if IsObject(hotkeyCtrl) {
            hotkeyCtrl.Text := Trim(LoadConfig("AutoPresetHotkey", ""))
        }
        this.SyncPresetList()
        this.PaintSwitch()
        this.RefreshSkillPreview()
    }

    static ToggleEnabled(*) {
        ctrl := AutoPresetSettingsGetCtrl("SettingAutoPresetSwitch")
        if !IsObject(ctrl) {
            return
        }
        ctrl.Value := ctrl.Value ? 0 : 1
        this.PaintSwitch()
        SaveConfig("SettingAutoPresetSwitch", ctrl.Value ? 1 : 0)
        PresetRecognition_UpdateHotkeys()
    }

    static AfterHotkeyCapture(key) {
        hk := Trim(key)
        SaveConfig("AutoPresetHotkey", hk)
        PresetRecognition_UpdateHotkeys()
    }

    static OpenDetailSettings(*) {
        ShowGuiPresetAutoSwitch()
    }

    static PaintSwitch() {
        global gAutoPresetSettingsSwitchUi
        ctrl := AutoPresetSettingsGetCtrl("SettingAutoPresetSwitch")
        if !IsObject(ctrl) || !IsObject(gAutoPresetSettingsSwitchUi) {
            return
        }
        gAutoPresetSettingsSwitchUi.Draw(Integer(ctrl.Value) = 1)
    }

    static ResolveSelectedPreset() {
        global gAutoPresetSelectedPreset
        presetList := LoadAllPreset()
        if IsObject(presetList) {
            loop presetList.Length {
                if !presetList.Has(A_Index) {
                    continue
                }
                if (presetList[A_Index] = gAutoPresetSelectedPreset) {
                    return gAutoPresetSelectedPreset
                }
            }
            currentPreset := GetNowSelectPreset()
            loop presetList.Length {
                if !presetList.Has(A_Index) {
                    continue
                }
                if (presetList[A_Index] = currentPreset) {
                    return currentPreset
                }
            }
            return presetList.Length >= 1 ? presetList[1] : ""
        }
        return ""
    }

    static SyncPresetList() {
        global gAutoPresetSelectedPreset
        listCtrl := AutoPresetSettingsGetCtrl("PresetList")
        nameCtrl := AutoPresetSettingsGetCtrl("SelectedPresetName")
        if !IsObject(listCtrl) {
            return
        }
        presetList := PresetManager.ListPipe()
        MainSetListBox(listCtrl, presetList)
        gAutoPresetSelectedPreset := this.ResolveSelectedPreset()
        if (gAutoPresetSelectedPreset != "") {
            idx := 0
            presetItems := StrSplit(presetList, "|")
            loop presetItems.Length {
                if !presetItems.Has(A_Index) {
                    continue
                }
                if (presetItems[A_Index] = gAutoPresetSelectedPreset) {
                    idx := A_Index
                    break
                }
            }
            if (idx > 0) {
                MainPresetListSafeChoose(listCtrl, idx, presetList)
            }
        }
        if IsObject(nameCtrl) {
            nameCtrl.Text := gAutoPresetSelectedPreset
        }
    }

    static OnPresetSelectionChange(*) {
        global gAutoPresetSelectedPreset
        listCtrl := AutoPresetSettingsGetCtrl("PresetList")
        nameCtrl := AutoPresetSettingsGetCtrl("SelectedPresetName")
        if !IsObject(listCtrl) {
            return
        }
        presetName := Trim(listCtrl.Text)
        if (presetName = "") {
            return
        }
        gAutoPresetSelectedPreset := presetName
        if IsObject(nameCtrl) {
            nameCtrl.Text := presetName
        }
        this.RefreshSkillPreview()
    }

    static GetSelectedPreset() {
        global gAutoPresetSelectedPreset
        gAutoPresetSelectedPreset := this.ResolveSelectedPreset()
        return gAutoPresetSelectedPreset
    }

    static OpenHelp(*) {
        ExWindowHost.ShowHelp(GuiText.SettingAutoPresetHelp(), GuiText.PresetAutoHelpTitle(), gAutoPresetSettingsGui)
    }

    static RefreshSkillPreview() {
        global gAutoPresetSettingsSkillPvW, gAutoPresetSettingsSkillPvH
        pic := AutoPresetSettingsGetCtrl("SkillPreview")
        if !IsObject(pic) {
            return
        }
        path := PresetSkillIconPath(this.GetSelectedPreset())
        pic.Value := ""
        AutoPresetSettingsLockSkillPreviewFrame(pic)
        if FileExist(path) {
            tmp := PresetSkillIcon_FitPreviewTempPath()
            if PresetSkillIcon_RenderFitPreviewToFile(path, gAutoPresetSettingsSkillPvW, gAutoPresetSettingsSkillPvH, tmp) && FileExist(tmp) {
                pic.Value := tmp
            } else {
                pic.Value := path
            }
            AutoPresetSettingsLockSkillPreviewFrame(pic)
        }
    }

    static UpdateSkillIcon(*) {
        PresetRegionPickCommitIfOpen()
        try {
            PresetSkillIcon_UpdateForPreset(this.GetSelectedPreset())
            this.RefreshSkillPreview()
        } catch Error as e {
            MsgBox(e.Message,, "Icon!")
        }
    }

    static DeleteSkillIcon(*) {
        name := this.GetSelectedPreset()
        if (name = "") {
            return
        }
        if !FileExist(PresetSkillIconPath(name)) {
            return
        }
        PresetSkillIcon_DeleteForPreset(name)
        this.RefreshSkillPreview()
    }
}
