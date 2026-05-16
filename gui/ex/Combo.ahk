#Requires AutoHotkey v2.0

global gComboGui := Gui("-MinimizeBox -MaximizeBox")
global gComboCtrls := Map()
global __ComboSkillItems := []
global __ComboProfiles := []
global __ComboProfileIndex := 1
global __ComboProfileLoading := false
global gComboProfileDragCurrentProfile := ""
global gComboEditCtrls := Map()
global gComboEditIndex := 0
global gComboEditKey := ""

UiApplyWindow(gComboGui)
gComboGui.OnEvent("Escape", ComboGuiEscape)
gComboGui.OnEvent("Close", ComboGuiClose)

UiExPageTitle(gComboGui, exText["ComboTitleLine"], 620)
UiHelpButton(gComboGui, UiRect(582, 14, 22, 22), ComboHelp)

UiLabel(gComboGui, UiRect(16, 52, 196, 22, "+0x200"), exText["ComboProfileList"])
UiListBox(gComboCtrls, gComboGui, "ComboProfilesListBox", UiRect(16, 74, 196, 210), ComboProfileListChange)
UiListBoxDragSort_Attach(gComboCtrls["ComboProfilesListBox"], ComboProfileDragGetItems, ComboProfileDragRender, ComboProfileDragCommit, ComboProfileDragClick)
UiPlainButton(gComboGui, UiRect(16, 292, 94, 26), exText["ComboAddProfile"], ComboAddProfile)
UiPlainButton(gComboGui, UiRect(118, 292, 94, 26), exText["ComboRemoveProfile"], ComboRemoveProfile)

UiLabel(gComboGui, UiRect(228, 52, 344, 22, "+0x200"), exText["ComboSkillList"])
UiListBox(gComboCtrls, gComboGui, "ComboSkillsListBox", UiRect(228, 74, 364, 210))
gComboCtrls["ComboSkillsListBox"].OnEvent("DoubleClick", ComboEditSkill)
UiListBoxDragSort_Attach(gComboCtrls["ComboSkillsListBox"], ComboDragGetItems, ComboDragRender, ComboDragCommit)
UiPlainButton(gComboGui, UiRect(228, 292, 112, 26), exText["ComboAddSkill"], ComboAddSkill)
UiPlainButton(gComboGui, UiRect(348, 292, 112, 26), exText["ComboDeleteSkill"], ComboDeleteSkill)

UiLabel(gComboGui, UiRect(228, 334, 44, 22, "+0x200"), exText["ComboTriggerKey"])
UiEdit(gComboCtrls, gComboGui, "ComboTriggerKey", UiRect(276, 332, 232, 24, "+ReadOnly -WantCtrlA -E0x200"))
UiPlainButton(gComboGui, UiRect(228, 360, 200, 28), exText["ComboSetTriggerKey"], ComboSetTriggerKey)
gComboCtrls["ComboLoopMode"] := gComboGui.Add("CheckBox", "vComboLoopMode x512 y334 h22", exText["ComboLoopMode"])

UiButton(gComboCtrls, gComboGui, "ComboApply", UiRect(160, 396, 140, 32), exText["ComboApply"], ComboApplyProfile, "secondary")
UiButton(gComboCtrls, gComboGui, "ComboSaveClose", UiRect(316, 396, 140, 32), exText["ComboSaveClose"], ComboSaveAndClose, "primary")

gComboEditGui := Gui("-MinimizeBox -MaximizeBox")
UiApplyWindow(gComboEditGui)
gComboEditGui.OnEvent("Escape", ComboEditCancel)
gComboEditGui.OnEvent("Close", ComboEditCancel)
UiLabel(gComboEditGui, UiRect(16, 16, 120, 22, "+0x200"), exText["ComboEditSkillKey"])
UiEdit(gComboEditCtrls, gComboEditGui, "ComboEditCurrentKey", UiRect(16, 38, 120, 24, "+ReadOnly -WantCtrlA -E0x200"))
UiPlainButton(gComboEditGui, UiRect(16, 68, 120, 28), exText["ComboEditChangeKey"], ComboEditChangeKey)
UiLabel(gComboEditGui, UiRect(148, 16, 100, 22, "+0x200"), exText["ComboEditDelay"])
UiEdit(gComboEditCtrls, gComboEditGui, "ComboEditDelay", UiRect(148, 38, 100, 24, "+Number -E0x200"))
UiPlainButton(gComboEditGui, UiRect(148, 68, 48, 28), exText["ComboEditOk"], ComboEditSave, "primary")
UiPlainButton(gComboEditGui, UiRect(200, 68, 48, 28), exText["ComboEditCancel"], ComboEditCancel)

ComboGetCtrl(name) {
    global gComboCtrls
    return gComboCtrls.Has(name) ? gComboCtrls[name] : ""
}

ShowGuiCombo(*) {
    global gMainGui, gComboGui
    if IsObject(gMainGui) {
        gComboGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gComboGui.Title := exText["ComboTitle"]
    gComboGui.Show("w620 h440")
    ComboLoadConfig()
    DisableGuiMain()
}

HideGuiCombo() {
    global gComboGui
    gComboGui.Hide()
    EnableGuiMain()
}

ComboGuiEscape(*) {
    if !ComboSaveConfig() {
        return
    }
    HideGuiCombo()
}

ComboGuiClose(*) {
    ComboGuiEscape()
}

ComboHelp(*) {
    UiHelpMsgBox(exText["ComboHelp"], exText["ComboHelpTitle"])
}

ComboSetTriggerKey(*) {
    raw := GetPressKey()
    key := ComboCanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(exText["ComboUnsupportedMainKey"], exText["ComboTitle"], "Icon!")
        }
        return
    }
    ComboGetCtrl("ComboTriggerKey").Text := key
}

ComboMakeDisplay(item) {
    return item.key " - " item.delay "ms"
}

ComboRefreshList() {
    global __ComboSkillItems
    ctrl := ComboGetCtrl("ComboSkillsListBox")
    ctrl.Delete()
    count := 0
    loop __ComboSkillItems.Length {
        if !__ComboSkillItems.Has(A_Index) {
            continue
        }
        item := __ComboSkillItems[A_Index]
        if !IsObject(item) {
            continue
        }
        ctrl.Add([ComboMakeDisplay(item)])
        count++
    }
    if (count > 0) {
        ctrl.Choose(count)
    }
}

ComboAddSkill(*) {
    global __ComboSkillItems
    raw := GetPressKey()
    key := ComboCanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(exText["ComboUnsupportedKey"], exText["ComboTitle"], "Icon!")
        }
        return
    }
    __ComboSkillItems.Push({ key: key, delay: 20 })
    ComboRefreshList()
}

ComboDeleteSkill(*) {
    global __ComboSkillItems
    ctrl := ComboGetCtrl("ComboSkillsListBox")
    if (ctrl.Text = "") {
        return
    }
    idx := ctrl.Value
    if (idx >= 1 && idx <= __ComboSkillItems.Length) {
        __ComboSkillItems.RemoveAt(idx)
        ComboRefreshList()
    }
}

ComboEditSkill(ctrl, *) {
    global __ComboSkillItems, gComboEditIndex
    idx := ctrl.Value
    if (idx < 1 || idx > __ComboSkillItems.Length || !__ComboSkillItems.Has(idx)) {
        return
    }
    gComboEditIndex := idx
    ComboShowEditDialog(__ComboSkillItems[idx])
}

ComboCloneSkillItems(items) {
    out := []
    if !IsObject(items) {
        return out
    }
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        it := items[A_Index]
        if !IsObject(it) {
            continue
        }
        out.Push({ key: it.key, delay: it.delay })
    }
    return out
}

ComboProfileSummary(p) {
    if !IsObject(p) {
        return ""
    }
    t := Trim(String(p.trigger))
    if (t = "") {
        t := exText["ComboUnsetTrigger"]
    }
    skills := IsObject(p.skills) ? p.skills : []
    return t " : " skills.Length exText["ComboSkillCountSuffix"]
}

ComboFlushEditorToProfileAt(idx) {
    global __ComboProfiles, __ComboSkillItems
    if (idx < 1 || idx > __ComboProfiles.Length || !__ComboProfiles.Has(idx)) {
        return
    }
    p := __ComboProfiles[idx]
    p.trigger := ComboGetCtrl("ComboTriggerKey").Text
    p.loop := ComboGetCtrl("ComboLoopMode").Value
    p.skills := ComboCloneSkillItems(__ComboSkillItems)
}

ComboLoadProfileToEditor(idx) {
    global __ComboProfiles, __ComboSkillItems
    if (idx < 1 || idx > __ComboProfiles.Length || !__ComboProfiles.Has(idx)) {
        return
    }
    p := __ComboProfiles[idx]
    __ComboSkillItems := ComboCloneSkillItems(p.skills)
    ComboRefreshList()
    ComboGetCtrl("ComboTriggerKey").Text := p.trigger
    ComboGetCtrl("ComboLoopMode").Value := p.loop
}

ComboRefreshProfileList() {
    global __ComboProfiles, __ComboProfileIndex, __ComboProfileLoading
    __ComboProfileLoading := true
    try {
        ctrl := ComboGetCtrl("ComboProfilesListBox")
        ctrl.Delete()
        loop __ComboProfiles.Length {
            if !__ComboProfiles.Has(A_Index) {
                continue
            }
            ctrl.Add([ComboProfileSummary(__ComboProfiles[A_Index])])
        }
        if (__ComboProfileIndex >= 1 && __ComboProfileIndex <= __ComboProfiles.Length) {
            ctrl.Choose(__ComboProfileIndex)
        } else if (__ComboProfiles.Length > 0) {
            ctrl.Choose(1)
        }
    } finally {
        __ComboProfileLoading := false
    }
}

ComboSetProfileListBoxFromItems(ctrl, items, selectedIndex) {
    ctrl.Delete()
    if IsObject(items) {
        loop items.Length {
            if !items.Has(A_Index) {
                continue
            }
            ctrl.Add([ComboProfileSummary(items[A_Index])])
        }
    }
    if (selectedIndex > 0) {
        try ctrl.Choose(selectedIndex)
    }
}

ComboProfileDragGetItems(*) {
    global __ComboProfiles, __ComboProfileIndex, gComboProfileDragCurrentProfile
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    gComboProfileDragCurrentProfile := ""
    if (__ComboProfileIndex >= 1 && __ComboProfileIndex <= __ComboProfiles.Length) {
        gComboProfileDragCurrentProfile := __ComboProfiles[__ComboProfileIndex]
    }
    return UiListBoxDragSort_CopyArray(__ComboProfiles)
}

ComboProfileDragRender(ctrl, items, selectedIndex) {
    global __ComboProfileLoading
    __ComboProfileLoading := true
    try {
        ComboSetProfileListBoxFromItems(ctrl, items, selectedIndex)
    } finally {
        __ComboProfileLoading := false
    }
}

ComboProfileDragCommit(items, selectedIndex) {
    global __ComboProfiles, __ComboProfileIndex, gComboProfileDragCurrentProfile
    __ComboProfiles := items
    newCurrentIndex := 0
    if IsObject(gComboProfileDragCurrentProfile) {
        loop __ComboProfiles.Length {
            if __ComboProfiles.Has(A_Index) && (__ComboProfiles[A_Index] == gComboProfileDragCurrentProfile) {
                newCurrentIndex := A_Index
                break
            }
        }
    }
    __ComboProfileIndex := newCurrentIndex > 0 ? newCurrentIndex : selectedIndex
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
    gComboProfileDragCurrentProfile := ""
}

ComboProfileDragClick(ctrl) {
    ComboProfileChangeToIndex(ctrl.Value)
}

ComboProfileListChange(ctrl, *) {
    global __ComboProfiles, __ComboProfileIndex, __ComboProfileLoading
    if __ComboProfileLoading || UiListBoxDragSort_IsActive(ctrl) {
        return
    }
    ComboProfileChangeToIndex(ctrl.Value)
}

ComboProfileChangeToIndex(newIdx) {
    global __ComboProfiles, __ComboProfileIndex
    if (newIdx < 1 || newIdx > __ComboProfiles.Length) {
        return
    }
    oldIdx := __ComboProfileIndex
    if (oldIdx >= 1 && oldIdx <= __ComboProfiles.Length && oldIdx != newIdx) {
        ComboFlushEditorToProfileAt(oldIdx)
    }
    __ComboProfileIndex := newIdx
    ComboLoadProfileToEditor(newIdx)
    ComboRefreshProfileList()
}

ComboAddProfile(*) {
    global __ComboProfiles, __ComboProfileIndex
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    maxCount := ComboProfileMaxCount()
    if (__ComboProfiles.Length >= maxCount) {
        MsgBox(exText["ComboMaxProfilesPrefix"] maxCount exText["ComboMaxProfilesSuffix"], exText["ComboTitle"], "Icon!")
        return
    }
    __ComboProfiles.Push({ trigger: "", loop: false, skills: [] })
    __ComboProfileIndex := __ComboProfiles.Length
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
}

ComboRemoveProfile(*) {
    global __ComboProfiles, __ComboProfileIndex
    if (__ComboProfiles.Length <= 1) {
        MsgBox(exText["ComboKeepOneProfile"], exText["ComboTitle"], "Icon!")
        return
    }
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    __ComboProfiles.RemoveAt(__ComboProfileIndex)
    if (__ComboProfileIndex > __ComboProfiles.Length) {
        __ComboProfileIndex := __ComboProfiles.Length
    }
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
}

ComboApplyProfile(*) {
    if !ComboSaveConfig() {
        return
    }
    ComboRefreshProfileList()
}

ComboSaveAndClose(*) {
    if !ComboSaveConfig() {
        return
    }
    ComboRefreshProfileList()
    HideGuiCombo()
}

ComboSaveConfig() {
    global __ComboProfiles, __ComboProfileIndex
    presetName := GetNowSelectPreset()
    ComboFlushEditorToProfileAt(__ComboProfileIndex)
    seen := Map()
    loop __ComboProfiles.Length {
        if !__ComboProfiles.Has(A_Index) {
            continue
        }
        t := Trim(String(__ComboProfiles[A_Index].trigger))
        if (t = "") {
            continue
        }
        c := ComboCanonMainKey(t)
        if (c = "") {
            continue
        }
        id := Key2SC(GetOriginKeyName(c))
        if (id = "") {
            continue
        }
        if seen.Has(id) {
            MsgBox(exText["ComboDuplicateTriggerPrefix"] t exText["ComboDuplicateTriggerSuffix"], exText["ComboTitle"], "Icon!")
            return false
        }
        seen[id] := true
    }
    SavePreset(presetName, "ComboProfiles", ComboSerializeProfiles(__ComboProfiles))
    SavePreset(presetName, "ComboTriggerKey", "")
    SavePreset(presetName, "ComboLoopMode", false)
    SavePreset(presetName, "ComboSkills", "")
    return true
}

ComboLoadConfig() {
    global __ComboProfiles, __ComboProfileIndex
    presetName := GetNowSelectPreset()
    __ComboProfiles := ComboLoadProfilesFromPreset(presetName)
    if (__ComboProfiles.Length = 0) {
        __ComboProfiles.Push({ trigger: "", loop: false, skills: [] })
    }
    __ComboProfileIndex := 1
    ComboRefreshProfileList()
    ComboLoadProfileToEditor(__ComboProfileIndex)
}

ComboShowEditDialog(item) {
    global gComboGui, gComboEditGui, gComboEditCtrls, gComboEditKey
    if !IsObject(item) {
        return
    }
    gComboEditKey := item.key
    gComboEditCtrls["ComboEditCurrentKey"].Text := gComboEditKey
    gComboEditCtrls["ComboEditDelay"].Text := ComboNormalizeDelay(item.delay)
    if IsObject(gComboGui) {
        gComboEditGui.Opt("+Owner" gComboGui.Hwnd)
    }
    gComboEditGui.Title := exText["ComboEditTitle"]
    gComboEditGui.Show("w268 h120")
}

ComboEditChangeKey(*) {
    global gComboEditCtrls, gComboEditKey
    raw := GetPressKey()
    key := ComboCanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(exText["ComboUnsupportedKey"], exText["ComboTitle"], "Icon!")
        }
        return
    }
    gComboEditKey := key
    gComboEditCtrls["ComboEditCurrentKey"].Text := key
}

ComboEditSave(*) {
    global __ComboSkillItems, gComboEditCtrls, gComboEditIndex, gComboEditKey
    if (gComboEditIndex < 1 || gComboEditIndex > __ComboSkillItems.Length || !__ComboSkillItems.Has(gComboEditIndex)) {
        ComboEditCancel()
        return
    }
    delay := ComboNormalizeDelay(gComboEditCtrls["ComboEditDelay"].Text)
    if (gComboEditKey = "") {
        gComboEditKey := __ComboSkillItems[gComboEditIndex].key
    }
    __ComboSkillItems[gComboEditIndex] := { key: gComboEditKey, delay: delay }
    ComboRefreshList()
    try ComboGetCtrl("ComboSkillsListBox").Choose(gComboEditIndex)
    ComboEditCancel()
}

ComboEditCancel(*) {
    global gComboEditGui, gComboEditIndex, gComboEditKey
    gComboEditIndex := 0
    gComboEditKey := ""
    gComboEditGui.Hide()
}

ComboSetListBoxFromItems(ctrl, items) {
    ctrl.Delete()
    if !IsObject(items) {
        return
    }
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        item := items[A_Index]
        if !IsObject(item) {
            continue
        }
        ctrl.Add([ComboMakeDisplay(item)])
    }
}

ComboDragGetItems(*) {
    global __ComboSkillItems
    items := []
    loop __ComboSkillItems.Length {
        if !__ComboSkillItems.Has(A_Index) {
            continue
        }
        item := __ComboSkillItems[A_Index]
        items.Push({ key: item.key, delay: item.delay })
    }
    return items
}

ComboDragRender(ctrl, items, selectedIndex) {
    ComboSetListBoxFromItems(ctrl, items)
    try ctrl.Choose(selectedIndex)
}

ComboDragCommit(items, selectedIndex) {
    global __ComboSkillItems
    __ComboSkillItems := items
    ComboRefreshList()
    if (selectedIndex > 0 && selectedIndex <= __ComboSkillItems.Length) {
        try ComboGetCtrl("ComboSkillsListBox").Choose(selectedIndex)
    }
}
