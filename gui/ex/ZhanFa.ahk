#Requires AutoHotkey v2.0

global gZhanFaGui := Gui("-MinimizeBox -MaximizeBox")
global gZhanFaCtrls := Map()
global __ZhanFaSkillKeys := []
global gZhanFaLayout := ExLayout.Window()

UiApplyWindow(gZhanFaGui)
gZhanFaGui.OnEvent("Escape", ZhanFaGuiEscape)
gZhanFaGui.OnEvent("Close", ZhanFaGuiClose)

UiSkillKeyEditor(gZhanFaGui, gZhanFaCtrls, "ZhanFa", exText["ZhanFaListTitle"], exText["ZhanFaShotTitle"], exText["ZhanFaAdd"], exText["ZhanFaDelete"], ZhanFaAddKey, ZhanFaDeleteKey, ZhanFaSave, ZhanFaHelp, exText["CommonSave"], exText["ZhanFaPageTitle"], "", exText["ZhanFaBigShotTitle"], gZhanFaLayout)
UiListBoxDragSort_Attach(gZhanFaCtrls["ZhanFaKeysListBox"], ZhanFaDragGetItems, UiListBoxDragSort_RenderStrings, ZhanFaDragCommit)

ZhanFaGetCtrl(name) {
    global gZhanFaCtrls
    return gZhanFaCtrls.Has(name) ? gZhanFaCtrls[name] : ""
}

ShowGuiZhanFa(*) {
    global gMainGui, gZhanFaGui, gZhanFaLayout
    if IsObject(gMainGui) {
        gZhanFaGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gZhanFaGui.Title := exText["ZhanFaTitle"]
    gZhanFaGui.Show("w" gZhanFaLayout.Width() " h" gZhanFaLayout.Height())
    ZhanFaLoadConfig()
    DisableGuiMain()
}

HideGuiZhanFa() {
    gZhanFaGui.Hide()
    EnableGuiMain()
}

ZhanFaGuiEscape(*) {
    ZhanFaSave()
}

ZhanFaGuiClose(*) {
    ZhanFaSave()
}

ZhanFaHelp(*) {
    UiHelpMsgBox(exText["ZhanFaHelp"], exText["ZhanFaHelpTitle"], exText["ZhanFaHelpExtra"], exText["ZhanFaHelpExtraTitle"])
}

ZhanFaAddKey(*) {
    global __ZhanFaSkillKeys
    key := GetPressKey()
    if IsValueInArray(key, __ZhanFaSkillKeys) {
        MsgBox(exText["DuplicateKey"],, "Icon!")
    } else {
        __ZhanFaSkillKeys.Push(key)
    }
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
    ctrl := ZhanFaGetCtrl("ZhanFaKeysListBox")
    for i, item in __ZhanFaSkillKeys {
        if (item = key) {
            ctrl.Choose(i)
            break
        }
    }
}

ZhanFaDeleteKey(*) {
    global __ZhanFaSkillKeys
    DeleteValueInArray(ZhanFaGetCtrl("ZhanFaKeysListBox").Text, __ZhanFaSkillKeys)
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
}

ZhanFaSave(*) {
    ZhanFaSaveConfig()
    HideGuiZhanFa()
}

ZhanFaChangeListGui(keys) {
    ctrl := ZhanFaGetCtrl("ZhanFaKeysListBox")
    ctrl.Delete()
    cnt := 0
    for key in keys {
        if (key != "") {
            ctrl.Add([key])
            cnt++
        }
    }
    if (cnt > 0) {
        ctrl.Choose(1)
    }
}

ZhanFaDragGetItems(*) {
    global __ZhanFaSkillKeys
    return UiListBoxDragSort_CopyArray(__ZhanFaSkillKeys)
}

ZhanFaDragCommit(items, selectedIndex) {
    global __ZhanFaSkillKeys
    __ZhanFaSkillKeys := items
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
    if (selectedIndex > 0 && selectedIndex <= __ZhanFaSkillKeys.Length) {
        try ZhanFaGetCtrl("ZhanFaKeysListBox").Choose(selectedIndex)
    }
}

ZhanFaSaveConfig() {
    global __ZhanFaSkillKeys
    keysString := ""
    for i, v in __ZhanFaSkillKeys {
        keysString .= v "|"
    }
    keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    SavePreset(GetNowSelectPreset(), "ZhanFaSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "ZhanFaShotKey", UiPressKeyEdit_Value(ZhanFaGetCtrl("ZhanFaShotKey")))
    SavePreset(GetNowSelectPreset(), "ZhanFaBigShotKey", UiPressKeyEdit_Value(ZhanFaGetCtrl("ZhanFaShotKey2")))
}

ZhanFaLoadConfig() {
    global __ZhanFaSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "ZhanFaShotKey", "Space")
    bigShotKey := LoadPreset(GetNowSelectPreset(), "ZhanFaBigShotKey", "")
    __ZhanFaSkillKeys := ZhanFaLoadKeys(GetNowSelectPreset())
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
    ZhanFaGetCtrl("ZhanFaShotKey").Text := shotKey
    ZhanFaGetCtrl("ZhanFaShotKey2").Text := bigShotKey
}
