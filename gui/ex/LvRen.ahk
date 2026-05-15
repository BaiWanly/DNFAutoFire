#Requires AutoHotkey v2.0

global gLvRenGui := Gui("+ToolWindow")
global gLvRenCtrls := Map()
global __LvRenSkillKeys := []

UiApplyWindow(gLvRenGui)
gLvRenGui.OnEvent("Escape", LvRenGuiEscape)
gLvRenGui.OnEvent("Close", LvRenGuiClose)

UiSkillKeyEditor(gLvRenGui, gLvRenCtrls, "LvRen", "已添加技能键", "流星发射键", "添加技能键", "删除技能键", "设置发射键", LvRenAddKey, LvRenDeleteKey, LvRenSetShotKey, LvRenSave, LvRenHelp)

LvRenGetCtrl(name) {
    global gLvRenCtrls
    return gLvRenCtrls.Has(name) ? gLvRenCtrls[name] : ""
}

ShowGuiLvRen(*) {
    global gMainGui, gLvRenGui
    if IsObject(gMainGui) {
        gLvRenGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gLvRenGui.Title := "旅人自动流星"
    gLvRenGui.Show("w184 h210")
    LvRenLoadConfig()
    DisableGuiMain()
}

HideGuiLvRen() {
    gLvRenGui.Hide()
    EnableGuiMain()
}

LvRenGuiEscape(*) {
    LvRenSave()
}

LvRenGuiClose(*) {
    LvRenSave()
}

LvRenHelp(*) {
    MsgBox("1、添加你想要发射流星的技能键`n2、设置游戏中流星的发射键（默认为Z）`n3、保存配置，启动连发并使用`n`nPS：建议和连发功能一起打开，效果更好", "如何使用旅人自动流星", "Iconi")
}

LvRenAddKey(*) {
    global __LvRenSkillKeys
    key := GetPressKey()
    if IsValueInArray(key, __LvRenSkillKeys) {
        MsgBox("请勿重复添加按键",, "Icon!")
    } else {
        __LvRenSkillKeys.Push(key)
    }
    LvRenChangeListGui(__LvRenSkillKeys)
    ctrl := LvRenGetCtrl("LvRenKeysListBox")
    for i, item in __LvRenSkillKeys {
        if (item = key) {
            ctrl.Choose(i)
            break
        }
    }
}

LvRenDeleteKey(*) {
    global __LvRenSkillKeys
    DeleteValueInArray(LvRenGetCtrl("LvRenKeysListBox").Text, __LvRenSkillKeys)
    LvRenChangeListGui(__LvRenSkillKeys)
}

LvRenSave(*) {
    LvRenSaveConfig()
    HideGuiLvRen()
}

LvRenSetShotKey(*) {
    LvRenGetCtrl("LvRenShotKey").Text := GetPressKey()
}

LvRenChangeListGui(keys) {
    ctrl := LvRenGetCtrl("LvRenKeysListBox")
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

LvRenSaveConfig() {
    global __LvRenSkillKeys
    keysString := ""
    for i, v in __LvRenSkillKeys {
        keysString .= v "|"
    }
    keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    SavePreset(GetNowSelectPreset(), "LvRenSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "LvRenShotKey", LvRenGetCtrl("LvRenShotKey").Text)
}

LvRenLoadConfig() {
    global __LvRenSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "LvRenShotKey", "Z")
    __LvRenSkillKeys := LvRenLoadKeys(GetNowSelectPreset())
    LvRenChangeListGui(__LvRenSkillKeys)
    LvRenGetCtrl("LvRenShotKey").Text := shotKey
}
