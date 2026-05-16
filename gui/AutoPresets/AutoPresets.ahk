#Requires AutoHotkey v2.0

global gAutoPresetsGui := Gui("-MinimizeBox -MaximizeBox")
global gAutoPresetsCtrls := Map()
global gAutoPresetsSelectedPreset := ""

; 布局常量（供预览框 Move 使用）
global __ap_marginX := 16
global __ap_windowW := 360
global __ap_contentR := 344
global __ap_listW := 120
global __ap_rightX := 224
global __ap_rightW := 120
global __ap_pvW := 120
global __ap_pvH := 120
global __ap_pvY := 434
global __ap_calX := 76
global __ap_calPvW := 120
global __ap_calPvH := 120
global __ap_townW := 72

UiApplyWindow(gAutoPresetsGui)
gAutoPresetsGui.OnEvent("Escape", AutoPresetsGuiEscape)
gAutoPresetsGui.OnEvent("Close", AutoPresetsGuiClose)

marginX := __ap_marginX
windowW := __ap_windowW
contentR := __ap_contentR
listW := __ap_listW
rightX := __ap_rightX
rightW := __ap_rightW
pvW := __ap_pvW
pvH := __ap_pvH
pvY := __ap_pvY
calX := __ap_calX
calPvW := __ap_calPvW
calPvH := __ap_calPvH
townW := __ap_townW
rowActionY := pvY + pvH + 12
apEnableY := 44
apHotkeyY := 78
middleY := 126
middleLabelY := middleY
middlePreviewY := middleY + 30
pickBtnY := middlePreviewY + calPvH + 14
calBtnY := pickBtnY + 36
townBtnY := calBtnY + 32
lowerY := townBtnY + 52
listY := lowerY + 24
listH := 120
calY := middlePreviewY
btnRowY := rowActionY
saveY := listY + listH + 48
global __ap_calY := calY
global __ap_calTownX := calX + calPvW + 16

UiSection(gAutoPresetsGui, UiRect(marginX, 12, contentR - marginX - 32, 20), AutoPresetsText["SectionTitle"])
UiHelpButton(gAutoPresetsGui, UiRect(contentR - 22, 12, 22, 22), AutoPresetsHelp)
gAutoPresetsGui.SetFont()
gAutoPresetsCtrls["AutoPresetsEnableVisible"] := gAutoPresetsGui.Add("CheckBox", "vAutoPresetsEnableVisible x" marginX " y" apEnableY " w310 h20", AutoPresetsText["Enable"])
gAutoPresetsCtrls["AutoPresetsEnableVisible"].OnEvent("Click", AutoPresetsSyncEnableFromUi)
UiLabel(gAutoPresetsGui, UiRect(marginX, apHotkeyY, 140, 20), AutoPresetsText["ExtraHotkey"])
UiEdit(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetHotkey", UiRect(144, apHotkeyY - 1, 112, 22, "+ReadOnly -WantCtrlA -E0x200"))
UiPlainButton(gAutoPresetsGui, UiRect(264, apHotkeyY - 2, 72, 24), AutoPresetsText["Capture"], AutoPresetsCaptureHotkey, "secondary")

UiLabel(gAutoPresetsGui, UiRect(marginX, middleLabelY, contentR - marginX, 18), AutoPresetsText["CalTownReference"])
gAutoPresetsCtrls["CalPreview"] := gAutoPresetsGui.Add("Picture", "x" calX " y" calY " w" calPvW " h" calPvH, "")
gAutoPresetsCtrls["TownPreview"] := gAutoPresetsGui.Add("Picture", "x" (calX + calPvW + 16) " y" calY " w" townW " h" calPvH, "")
UiPlainButton(gAutoPresetsGui, UiRect(76, pickBtnY, 192, 30), AutoPresetsText["PickRegion"], AutoPresetsOpenPickMenu, "secondary")
UiPlainButton(gAutoPresetsGui, UiRect(76, calBtnY, 192, 28), AutoPresetsText["UpdateCalibrate"], AutoPresetsUpdateCalibrateIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiRect(76, townBtnY, 192, 28), AutoPresetsText["UpdateTown"], AutoPresetsUpdateTownIcon, "secondary")

UiLabel(gAutoPresetsGui, UiRect(marginX, lowerY, listW, 20), AutoPresetsText["PresetList"])
UiListBox(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetPresetList", UiRect(marginX, listY, listW, listH), AutoPresetsOnPresetListChange)
UiLabel(gAutoPresetsGui, UiRect(rightX, lowerY, rightW, 20), AutoPresetsText["SkillReference"])
UiEdit(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetSelectedName", UiRect(rightX, lowerY + 1, 1, 1, "+ReadOnly Hidden -E0x200"))
gAutoPresetsCtrls["SkillPreview"] := gAutoPresetsGui.Add("Picture", "x" rightX " y" pvY " w" pvW " h" pvH, "")
UiPlainButton(gAutoPresetsGui, UiRect(rightX, rowActionY, (pvW - 8) // 2, 28), AutoPresetsText["CaptureReference"], AutoPresetsUpdateSkillIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiRect(rightX + (pvW + 8) // 2, rowActionY, (pvW - 8) // 2, 28), AutoPresetsText["DeleteReference"], AutoPresetsDeleteSkillIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiRect((windowW - 120) // 2, saveY, 120, 30), AutoPresetsText["Save"], AutoPresetsGuiSave, "primary")

AutoPresetsGetCtrl(name) {
    global gAutoPresetsCtrls
    return gAutoPresetsCtrls.Has(name) ? gAutoPresetsCtrls[name] : ""
}

AutoPresetsLockSkillPreview(pic) {
    global __ap_rightX, __ap_pvY, __ap_pvW, __ap_pvH
    if IsObject(pic) {
        pic.Move(__ap_rightX, __ap_pvY, __ap_pvW, __ap_pvH)
    }
}

AutoPresetsLockCalPreview(pic) {
    global __ap_calX, __ap_calY, __ap_calPvW, __ap_calPvH
    if IsObject(pic) {
        pic.Move(__ap_calX, __ap_calY, __ap_calPvW, __ap_calPvH)
    }
}

AutoPresetsLockTownPreview(pic) {
    global __ap_calTownX, __ap_calY, __ap_townW, __ap_calPvH
    if IsObject(pic) {
        pic.Move(__ap_calTownX, __ap_calY, __ap_townW, __ap_calPvH)
    }
}

AutoPresetsResolveSelectedPreset() {
    global gAutoPresetsSelectedPreset
    presetList := LoadAllPreset()
    for n in presetList {
        if (n = gAutoPresetsSelectedPreset) {
            return gAutoPresetsSelectedPreset
        }
    }
    cur := GetNowSelectPreset()
    for n in presetList {
        if (n = cur) {
            return cur
        }
    }
    return presetList.Length >= 1 ? presetList[1] : ""
}

AutoPresetsSyncPresetList() {
    global gAutoPresetsSelectedPreset
    listCtrl := AutoPresetsGetCtrl("AutoPresetPresetList")
    nameCtrl := AutoPresetsGetCtrl("AutoPresetSelectedName")
    if !IsObject(listCtrl) {
        return
    }
    pipe := LoadAllPresetString()
    MainSetListBox(listCtrl, pipe)
    gAutoPresetsSelectedPreset := AutoPresetsResolveSelectedPreset()
    if (gAutoPresetsSelectedPreset != "") {
        idx := 0
        for i, txt in StrSplit(pipe, "|") {
            if (txt = gAutoPresetsSelectedPreset) {
                idx := i
                break
            }
        }
        if (idx > 0) {
            MainPresetListSafeChoose(listCtrl, idx, pipe)
        }
    }
    if IsObject(nameCtrl) {
        nameCtrl.Text := gAutoPresetsSelectedPreset
    }
}

AutoPresetsOnPresetListChange(*) {
    global gAutoPresetsSelectedPreset
    listCtrl := AutoPresetsGetCtrl("AutoPresetPresetList")
    nameCtrl := AutoPresetsGetCtrl("AutoPresetSelectedName")
    if !IsObject(listCtrl) {
        return
    }
    presetName := Trim(listCtrl.Text)
    if (presetName = "") {
        return
    }
    gAutoPresetsSelectedPreset := presetName
    if IsObject(nameCtrl) {
        nameCtrl.Text := presetName
    }
    AutoPresetsRefreshEnableCheckbox()
    AutoPresetsRefreshSkillPreview()
}

AutoPresetsRefreshEnableCheckbox() {
    v := AutoPresets_LoadEnabledGlobal() ? 1 : 0
    c := AutoPresetsGetCtrl("AutoPresetsEnableVisible")
    if IsObject(c) {
        c.Value := v
    }
}

AutoPresetsRefreshSkillPreview() {
    global __ap_pvW, __ap_pvH
    pic := AutoPresetsGetCtrl("SkillPreview")
    if !IsObject(pic) {
        return
    }
    path := AutoPresetsSkillIconPath(AutoPresetsResolveSelectedPreset())
    pic.Value := ""
    AutoPresetsLockSkillPreview(pic)
    if FileExist(path) {
        tmp := AutoPresetsSkillIcon_FitPreviewTempPath()
        if AutoPresetsSkillIcon_RenderFitPreviewToFile(path, __ap_pvW, __ap_pvH, tmp) && FileExist(tmp) {
            pic.Value := tmp
        } else {
            pic.Value := path
        }
        AutoPresetsLockSkillPreview(pic)
    }
}

AutoPresetsRefreshCalTownPreviews() {
    picC := AutoPresetsGetCtrl("CalPreview")
    picT := AutoPresetsGetCtrl("TownPreview")
    if IsObject(picC) {
        picC.Value := ""
        AutoPresetsLockCalPreview(picC)
        p := AutoPresetsCalibrateIconGlobalPath()
        if FileExist(p) {
            tmp := A_Temp "\DAF_cal_fit_preview.png"
            if AutoPresetsSkillIcon_RenderFitPreviewToFile(p, __ap_calPvW, __ap_calPvH, tmp) && FileExist(tmp) {
                picC.Value := tmp
            } else {
                picC.Value := p
            }
            AutoPresetsLockCalPreview(picC)
        }
    }
    if IsObject(picT) {
        picT.Value := ""
        AutoPresetsLockTownPreview(picT)
        p2 := AutoPresetsTownIconGlobalPath()
        if FileExist(p2) {
            tmp2 := A_Temp "\DAF_town_fit_preview.png"
            if AutoPresetsSkillIcon_RenderFitPreviewToFile(p2, __ap_townW, __ap_calPvH, tmp2) && FileExist(tmp2) {
                picT.Value := tmp2
            } else {
                picT.Value := p2
            }
            AutoPresetsLockTownPreview(picT)
        }
    }
}

AutoPresetsAfterRegionPick(kind) {
    global gAutoPresetsGui
    if IsObject(gAutoPresetsGui) && WinExist("ahk_id " gAutoPresetsGui.Hwnd) {
        AutoPresetsRefreshCalTownPreviews()
        if (kind = "skill") {
            AutoPresetsRefreshSkillPreview()
        }
    }
}

AutoPresetsLoadToGui() {
    global gAutoPresetsSelectedPreset
    gAutoPresetsSelectedPreset := GetNowSelectPreset()
    AutoPresetsSyncPresetList()
    hk := Trim(LoadConfig("AutoPresetHotkey", " "))
    if (hk = " ") {
        hk := ""
    }
    AutoPresetsGetCtrl("AutoPresetHotkey").Text := hk
    AutoPresetsRefreshEnableCheckbox()
    AutoPresetsRefreshSkillPreview()
    AutoPresetsRefreshCalTownPreviews()
}

AutoPresetsSyncEnableFromUi(*) {
    v := AutoPresetsGetCtrl("AutoPresetsEnableVisible").Value ? 1 : 0
    SaveConfig("AutoPresetsEnabled", v)
    m := MainGetCtrl("AutoPresets")
    if IsObject(m) {
        m.Value := v
    }
    if AutoPresets_IsSessionRunning() {
        AutoPresets_RegisterSessionHotkeys()
    }
}

ShowGuiAutoPresets(*) {
    global gMainGui, gAutoPresetsGui
    if IsObject(gMainGui) {
        gAutoPresetsGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gAutoPresetsGui.Title := AutoPresetsText["SectionTitle"]
    AutoPresetsLoadToGui()
    hGui := saveY + 30 + 24
    gAutoPresetsGui.Show("w" windowW " h" hGui)
    DisableGuiMain()
}

HideGuiAutoPresets() {
    global gAutoPresetsGui
    PresetRegionPickCommitIfOpen()
    gAutoPresetsGui.Hide()
    EnableGuiMain()
}

AutoPresetsGuiEscape(*) {
    AutoPresetsGuiSave()
}

AutoPresetsGuiClose(*) {
    AutoPresetsGuiSave()
}

AutoPresetsGuiSave(*) {
    PresetRegionPickCommitIfOpen()
    hk := Trim(AutoPresetsGetCtrl("AutoPresetHotkey").Text)
    SaveConfig("AutoPresetHotkey", hk)
    v := AutoPresetsGetCtrl("AutoPresetsEnableVisible").Value ? 1 : 0
    SaveConfig("AutoPresetsEnabled", v)
    m := MainGetCtrl("AutoPresets")
    if IsObject(m) {
        m.Value := v
    }
    HideGuiAutoPresets()
    if AutoPresets_IsSessionRunning() {
        AutoPresets_RegisterSessionHotkeys()
    }
}

AutoPresetsHelp(*) {
    UiHelpMsgBox(AutoPresetsText["Help"], AutoPresetsText["HelpTitle"])
}

AutoPresetsCaptureHotkey(*) {
    AutoPresetsGetCtrl("AutoPresetHotkey").Text := GetPressKey()
}

AutoPresetsUpdateSkillIcon(*) {
    PresetRegionPickCommitIfOpen()
    try {
        AutoPresetsSkillIcon_UpdateForPreset(AutoPresetsResolveSelectedPreset())
        AutoPresetsRefreshSkillPreview()
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

AutoPresetsDeleteSkillIcon(*) {
    name := AutoPresetsResolveSelectedPreset()
    if (name = "") {
        return
    }
    AutoPresets_OnPresetDeleted(name)
    AutoPresetsRefreshSkillPreview()
}

AutoPresetsUpdateCalibrateIcon(*) {
    PresetRegionPickCommitIfOpen()
    try {
        AutoPresetsCalibrateIcon_UpdateCurrent()
        AutoPresetsRefreshCalTownPreviews()
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

AutoPresetsUpdateTownIcon(*) {
    PresetRegionPickCommitIfOpen()
    try {
        AutoPresetsTownIcon_UpdateCurrent()
        AutoPresetsRefreshCalTownPreviews()
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

AutoPresetsOpenPickMenu(*) {
    m := Menu()
    m.Add(AutoPresetsText["SkillRegion"], (*) => PresetRegionPickOpen("skill"))
    m.Add(AutoPresetsText["CalibrateRegion"], (*) => PresetRegionPickOpen("calibrate"))
    m.Add(AutoPresetsText["TownRegion"], (*) => PresetRegionPickOpen("town"))
    m.Show()
}

#Include ./AutoPresetsRegionPick.ahk
