#Requires AutoHotkey v2.0

global gAutoPresetsGui := Gui("-MinimizeBox -MaximizeBox")
global gAutoPresetsCtrls := Map()
global gAutoPresetsSelectedPreset := ""
global gAutoPresetsSelectedSkillId := ""
global gAutoPresetsSelectedDungeonPath := ""
global gAutoPresetsSkillItems := []
global gAutoPresetsDungeonItems := []
global gAutoPresetsLayout := AutoPresetsLayout.Window()

UiApplyWindow(gAutoPresetsGui)
gAutoPresetsGui.OnEvent("Escape", AutoPresetsGuiEscape)
gAutoPresetsGui.OnEvent("Close", AutoPresetsGuiClose)

marginX := AutoPresetsLayout.MarginX()
windowW := AutoPresetsLayout.WindowWidth()
contentR := AutoPresetsLayout.ContentRight()
listW := AutoPresetsLayout.ListWidth()
skillListX := AutoPresetsLayout.SkillIconListX()
skillListW := AutoPresetsLayout.SkillIconListWidth()
rightX := AutoPresetsLayout.RightX()
rightW := AutoPresetsLayout.RightWidth()
pvW := AutoPresetsLayout.PreviewWidth()
pvH := AutoPresetsLayout.PreviewHeight()
pvY := AutoPresetsLayout.PreviewY()
DungeonX := AutoPresetsLayout.DungeonX()
DungeonListX := AutoPresetsLayout.DungeonListX()
DungeonListW := AutoPresetsLayout.DungeonListWidth()
DungeonListH := AutoPresetsLayout.DungeonListHeight()
DungeonPvW := AutoPresetsLayout.DungeonPreviewWidth()
DungeonPvH := AutoPresetsLayout.DungeonPreviewHeight()
rowActionY := AutoPresetsLayout.RowActionY()
apEnableY := AutoPresetsLayout.EnableY()
apHotkeyY := AutoPresetsLayout.HotkeyY()
DungeonY := AutoPresetsLayout.DungeonY()
pickBtnY := AutoPresetsLayout.PickBtnY()
DungeonBtnY := AutoPresetsLayout.DungeonBtnY()
lowerY := AutoPresetsLayout.LowerY()
listY := AutoPresetsLayout.ListY()
listH := AutoPresetsLayout.ListHeight()
saveY := AutoPresetsLayout.SaveY()

UiSectionWithHelp(gAutoPresetsGui, gAutoPresetsLayout, marginX, 12, AutoPresetsText["SectionTitle"], AutoPresetsHelp, contentR)
gAutoPresetsCtrls["AutoPresetsEnableVisible"] := gAutoPresetsGui.Add("CheckBox", UiLayoutRect(gAutoPresetsLayout, marginX, apEnableY, contentR - marginX, 20, "vAutoPresetsEnableVisible"), AutoPresetsText["Enable"])
gAutoPresetsCtrls["AutoPresetsEnableVisible"].OnEvent("Click", AutoPresetsSyncEnableFromUi)
UiLabel(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, marginX, apHotkeyY, 140, 20), AutoPresetsText["ExtraHotkey"])
UiPressKeyEdit(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetHotkey", UiLayoutRect(gAutoPresetsLayout, 144, apHotkeyY, contentR - 144, ExLayout.ControlHeight()))

UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, marginX, pickBtnY, (contentR - marginX - 8) // 2, ExLayout.ControlHeight()), AutoPresetsText["PickSkillRegion"], (*) => PresetRegionPickOpen("skill"), "secondary")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, marginX + (contentR - marginX + 8) // 2, pickBtnY, (contentR - marginX - 8) // 2, ExLayout.ControlHeight()), AutoPresetsText["PickDungeonRegion"], (*) => PresetRegionPickOpen("dungeon"), "secondary")
UiLabel(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, DungeonListX, DungeonY - 24, DungeonListW, 20), AutoPresetsText["DungeonResolutionList"])
UiListBox(gAutoPresetsCtrls, gAutoPresetsGui, "DungeonResolutionList", UiLayoutRect(gAutoPresetsLayout, DungeonListX, DungeonY, DungeonListW, DungeonListH), AutoPresetsOnDungeonResolutionChange)
gAutoPresetsCtrls["DungeonPreview"] := gAutoPresetsGui.Add("Picture", UiLayoutRect(gAutoPresetsLayout, DungeonX, DungeonY, DungeonPvW, DungeonPvH), "")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, DungeonX, DungeonBtnY, (DungeonPvW - 8) // 2, ExLayout.ControlHeight()), AutoPresetsText["CaptureDungeon"], AutoPresetsCaptureDungeonIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, DungeonX + (DungeonPvW + 8) // 2, DungeonBtnY, (DungeonPvW - 8) // 2, ExLayout.ControlHeight()), AutoPresetsText["DeleteDungeon"], AutoPresetsDeleteDungeonIcon, "secondary")

UiLabel(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, marginX, lowerY, listW, 20), AutoPresetsText["PresetList"])
UiListBox(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetPresetList", UiLayoutRect(gAutoPresetsLayout, marginX, listY, listW, listH), AutoPresetsOnPresetListChange)
UiLabel(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, skillListX, lowerY, contentR - skillListX, 20), AutoPresetsText["SkillIconList"])
UiListBox(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetSkillIconList", UiLayoutRect(gAutoPresetsLayout, skillListX, listY, skillListW, listH), AutoPresetsOnSkillIconListChange)
gAutoPresetsCtrls["AutoPresetSkillIconList"].OnEvent("DoubleClick", AutoPresetsRenameSkillIcon)
OnMessage(0x0202, AutoPresetsSkillIconListOnLButtonUp)
UiEdit(gAutoPresetsCtrls, gAutoPresetsGui, "AutoPresetSelectedName", UiLayoutRect(gAutoPresetsLayout, rightX, lowerY + 1, 1, 1, "+ReadOnly Hidden -E0x200"))
gAutoPresetsCtrls["SkillPreview"] := gAutoPresetsGui.Add("Picture", UiLayoutRect(gAutoPresetsLayout, rightX, pvY, pvW, pvH), "")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, rightX, rowActionY, (pvW - 8) // 2, ExLayout.ControlHeight()), AutoPresetsText["CaptureReference"], AutoPresetsUpdateSkillIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiLayoutRect(gAutoPresetsLayout, rightX + (pvW + 8) // 2, rowActionY, (pvW - 8) // 2, ExLayout.ControlHeight()), AutoPresetsText["DeleteReference"], AutoPresetsDeleteSkillIcon, "secondary")
UiPlainButton(gAutoPresetsGui, UiExSaveButtonRect(gAutoPresetsLayout, saveY, contentR), AutoPresetsText["Save"], AutoPresetsGuiSave, "primary")

AutoPresetsGetCtrl(name) {
    global gAutoPresetsCtrls
    return gAutoPresetsCtrls.Has(name) ? gAutoPresetsCtrls[name] : ""
}

AutoPresetsLockSkillPreview(pic) {
    if IsObject(pic) {
        pic.Move(AutoPresetsLayout.RightX(), AutoPresetsLayout.PreviewY(), AutoPresetsLayout.PreviewWidth(), AutoPresetsLayout.PreviewHeight())
    }
}

AutoPresetsLockDungeonPreview(pic) {
    if IsObject(pic) {
        pic.Move(AutoPresetsLayout.DungeonX(), AutoPresetsLayout.DungeonY(), AutoPresetsLayout.DungeonPreviewWidth(), AutoPresetsLayout.DungeonPreviewHeight())
    }
}

AutoPresetsResolveSelectedSkillItem() {
    global gAutoPresetsSkillItems, gAutoPresetsSelectedSkillId
    listCtrl := AutoPresetsGetCtrl("AutoPresetSkillIconList")
    if IsObject(listCtrl) {
        idx := listCtrl.Value
        if (idx >= 1 && idx <= gAutoPresetsSkillItems.Length) {
            return gAutoPresetsSkillItems[idx]
        }
    }
    if (gAutoPresetsSelectedSkillId != "") {
        for item in gAutoPresetsSkillItems {
            if (item["id"] = gAutoPresetsSelectedSkillId) {
                return item
            }
        }
    }
    return ""
}

AutoPresetsSelectSkillIconById(skillId) {
    global gAutoPresetsSkillItems, gAutoPresetsSelectedSkillId
    listCtrl := AutoPresetsGetCtrl("AutoPresetSkillIconList")
    if !IsObject(listCtrl) {
        return
    }
    gAutoPresetsSelectedSkillId := skillId
    idx := 0
    loop gAutoPresetsSkillItems.Length {
        if (gAutoPresetsSkillItems[A_Index]["id"] = skillId) {
            idx := A_Index
            break
        }
    }
    if (idx > 0) {
        listCtrl.Value := idx
    }
    AutoPresetsRefreshSkillPreview()
}

AutoPresetsDungeonPathToResolution(path) {
    SplitPath(path, &fileName)
    return RegExReplace(fileName, "\.png$")
}

AutoPresetsResolveSelectedResolution() {
    global gAutoPresetsSelectedDungeonPath
    return gAutoPresetsSelectedDungeonPath = "" ? "" : AutoPresetsDungeonPathToResolution(gAutoPresetsSelectedDungeonPath)
}

AutoPresetsSyncDungeonResolutionList(selectPath := "") {
    global gAutoPresetsDungeonItems, gAutoPresetsSelectedDungeonPath
    gAutoPresetsDungeonItems := AutoPresetsDungeonIconPaths()
    names := []
    for path in gAutoPresetsDungeonItems {
        names.Push(AutoPresetsDungeonPathToResolution(path))
    }
    listCtrl := AutoPresetsGetCtrl("DungeonResolutionList")
    if !IsObject(listCtrl) {
        return
    }
    MainSetListBoxFromArray(listCtrl, names)
    pickPath := selectPath
    if (pickPath = "") {
        try {
            curPath := AutoPresetsDungeonIconCurrentPath()
            for path in gAutoPresetsDungeonItems {
                if (path = curPath) {
                    pickPath := path
                    break
                }
            }
        } catch {
        }
    }
    if (pickPath = "" && gAutoPresetsDungeonItems.Length > 0) {
        pickPath := gAutoPresetsDungeonItems[1]
    }
    gAutoPresetsSelectedDungeonPath := pickPath
    idx := 0
    loop gAutoPresetsDungeonItems.Length {
        if (gAutoPresetsDungeonItems[A_Index] = pickPath) {
            idx := A_Index
            break
        }
    }
    if (idx > 0) {
        listCtrl.Value := idx
    }
    AutoPresetsRefreshDungeonPreview()
    AutoPresetsSyncSkillIconList()
}

AutoPresetsOnDungeonResolutionChange(*) {
    global gAutoPresetsDungeonItems, gAutoPresetsSelectedDungeonPath
    listCtrl := AutoPresetsGetCtrl("DungeonResolutionList")
    if !IsObject(listCtrl) {
        gAutoPresetsSelectedDungeonPath := ""
        AutoPresetsRefreshDungeonPreview()
        AutoPresetsSyncSkillIconList()
        return
    }
    idx := listCtrl.Value
    if (idx >= 1 && idx <= gAutoPresetsDungeonItems.Length) {
        gAutoPresetsSelectedDungeonPath := gAutoPresetsDungeonItems[idx]
    } else {
        gAutoPresetsSelectedDungeonPath := ""
    }
    AutoPresetsRefreshDungeonPreview()
    AutoPresetsSyncSkillIconList()
}

AutoPresetsSyncSkillIconList(selectSkillId := "") {
    global gAutoPresetsSkillItems, gAutoPresetsSelectedSkillId
    presetName := AutoPresetsResolveSelectedPreset()
    resolutionKey := AutoPresetsResolveSelectedResolution()
    gAutoPresetsSkillItems := AutoPresetsSkillIcons_Load(presetName, resolutionKey)
    names := []
    for item in gAutoPresetsSkillItems {
        names.Push(item["name"])
    }
    listCtrl := AutoPresetsGetCtrl("AutoPresetSkillIconList")
    if !IsObject(listCtrl) {
        return
    }
    MainSetListBoxFromArray(listCtrl, names)
    pickId := selectSkillId
    if (pickId = "" && gAutoPresetsSkillItems.Length > 0) {
        pickId := gAutoPresetsSkillItems[gAutoPresetsSkillItems.Length]["id"]
    }
    if (pickId != "") {
        AutoPresetsSelectSkillIconById(pickId)
    } else {
        gAutoPresetsSelectedSkillId := ""
        AutoPresetsRefreshSkillPreview()
    }
}

AutoPresetsOnSkillIconListChange(*) {
    global gAutoPresetsSkillItems, gAutoPresetsSelectedSkillId
    listCtrl := AutoPresetsGetCtrl("AutoPresetSkillIconList")
    if !IsObject(listCtrl) {
        gAutoPresetsSelectedSkillId := ""
        AutoPresetsRefreshSkillPreview()
        return
    }
    idx := listCtrl.Value
    if (idx >= 1 && idx <= gAutoPresetsSkillItems.Length) {
        gAutoPresetsSelectedSkillId := gAutoPresetsSkillItems[idx]["id"]
    } else {
        gAutoPresetsSelectedSkillId := ""
    }
    AutoPresetsRefreshSkillPreview()
}

AutoPresetsSkillIconListOnLButtonUp(wParam, lParam, msg, hwnd) {
    listCtrl := AutoPresetsGetCtrl("AutoPresetSkillIconList")
    if !IsObject(listCtrl) || hwnd != listCtrl.Hwnd {
        return
    }
    idx := UiListBoxDragSort_IndexFromClientPoint(listCtrl, lParam & 0xFFFF, (lParam >> 16) & 0xFFFF)
    if (idx <= 0) {
        return
    }
    global gAutoPresetsSkillItems, gAutoPresetsSelectedSkillId
    if (idx > gAutoPresetsSkillItems.Length) {
        return
    }
    skillId := gAutoPresetsSkillItems[idx]["id"]
    if (skillId != gAutoPresetsSelectedSkillId) {
        return
    }
    AutoPresetsRefreshSkillPreview()
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
    AutoPresetsSyncSkillIconList()
}

AutoPresetsRefreshEnableCheckbox() {
    v := AutoPresets_LoadEnabledGlobal() ? 1 : 0
    c := AutoPresetsGetCtrl("AutoPresetsEnableVisible")
    if IsObject(c) {
        c.Value := v
    }
}

AutoPresetsRefreshSkillPreview() {
    pic := AutoPresetsGetCtrl("SkillPreview")
    if !IsObject(pic) {
        return
    }
    item := AutoPresetsResolveSelectedSkillItem()
    path := IsObject(item) ? item["path"] : ""
    pic.Value := ""
    AutoPresetsLockSkillPreview(pic)
    if (path != "" && FileExist(path)) {
        tmp := AutoPresetsSkillIcon_FitPreviewTempPath()
        if AutoPresetsSkillIcon_RenderFitPreviewToFile(path, AutoPresetsLayout.PreviewWidth(), AutoPresetsLayout.PreviewHeight(), tmp) && FileExist(tmp) {
            pic.Value := tmp
        } else {
            pic.Value := path
        }
        AutoPresetsLockSkillPreview(pic)
    }
}

AutoPresetsRefreshDungeonPreview() {
    global gAutoPresetsSelectedDungeonPath
    picT := AutoPresetsGetCtrl("DungeonPreview")
    if !IsObject(picT) {
        return
    }
    picT.Value := ""
    AutoPresetsLockDungeonPreview(picT)
    p := gAutoPresetsSelectedDungeonPath
    if (p = "") {
        p := AutoPresetsDungeonIconPreviewPath()
    }
    if (p != "" && FileExist(p)) {
        tmp := A_Temp "\DAF_dungeon_fit_preview.png"
        if AutoPresetsSkillIcon_RenderFitPreviewToFile(p, AutoPresetsLayout.DungeonPreviewWidth(), AutoPresetsLayout.DungeonPreviewHeight(), tmp) && FileExist(tmp) {
            picT.Value := tmp
        } else {
            picT.Value := p
        }
        AutoPresetsLockDungeonPreview(picT)
    }
}

AutoPresetsAfterRegionPick(kind) {
    global gAutoPresetsGui, gAutoPresetsSelectedSkillId
    if IsObject(gAutoPresetsGui) && WinExist("ahk_id " gAutoPresetsGui.Hwnd) {
        AutoPresetsRefreshDungeonPreview()
        if (kind = "skill") {
            item := AutoPresetsResolveSelectedSkillItem()
            if IsObject(item) {
                AutoPresetsSkillIcon_UpdateForPreset(AutoPresetsResolveSelectedPreset(), item["id"], AutoPresetsResolveSelectedResolution())
            }
            AutoPresetsSyncSkillIconList(gAutoPresetsSelectedSkillId)
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
    AutoPresetsSyncDungeonResolutionList()
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
    global gMainGui, gAutoPresetsGui, gAutoPresetsLayout
    if IsObject(gMainGui) {
        gAutoPresetsGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gAutoPresetsGui.Title := AutoPresetsText["SectionTitle"]
    AutoPresetsLoadToGui()
    gAutoPresetsGui.Show("w" gAutoPresetsLayout.Width(windowW) " h" gAutoPresetsLayout.Height())
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
    hk := Trim(UiPressKeyEdit_Value(AutoPresetsGetCtrl("AutoPresetHotkey")))
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

AutoPresetsUpdateSkillIcon(*) {
    PresetRegionPickCommitIfOpen()
    try {
        added := AutoPresetsSkillIcon_Add(AutoPresetsResolveSelectedPreset(), AutoPresetsResolveSelectedResolution())
        AutoPresetsSyncSkillIconList(added["id"])
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

AutoPresetsDeleteSkillIcon(*) {
    name := AutoPresetsResolveSelectedPreset()
    item := AutoPresetsResolveSelectedSkillItem()
    if (name = "" || !IsObject(item)) {
        return
    }
    AutoPresetsSkillIcon_Delete(name, item["id"], AutoPresetsResolveSelectedResolution())
    AutoPresetsSyncSkillIconList()
}

AutoPresetsRenameSkillIcon(*) {
    name := AutoPresetsResolveSelectedPreset()
    item := AutoPresetsResolveSelectedSkillItem()
    if (name = "" || !IsObject(item)) {
        return
    }
    ret := InputBox(AutoPresetsText["RenameSkillIconPrompt"], AutoPresetsText["RenameSkillIconTitle"], "w280 h130", item["name"])
    if (ret.Result != "OK") {
        return
    }
    newName := Trim(ret.Value)
    if (newName = "") {
        return
    }
    if !AutoPresetsSkillIcon_Rename(name, item["id"], newName, AutoPresetsResolveSelectedResolution()) {
        return
    }
    AutoPresetsSyncSkillIconList(item["id"])
}

AutoPresetsCaptureDungeonIcon(*) {
    PresetRegionPickCommitIfOpen()
    try {
        path := AutoPresetsDungeonIcon_UpdateCurrent()
        AutoPresetsSyncDungeonResolutionList(path)
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

AutoPresetsDeleteDungeonIcon(*) {
    global gAutoPresetsSelectedDungeonPath
    path := gAutoPresetsSelectedDungeonPath
    if (path = "" || !FileExist(path)) {
        return
    }
    try FileDelete(path)
    gAutoPresetsSelectedDungeonPath := ""
    AutoPresetsSyncDungeonResolutionList()
}

#Include ./AutoPresetsRegionPick.ahk
