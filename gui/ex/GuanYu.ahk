#Requires AutoHotkey v2.0

global gGuanYuGui := Gui("+ToolWindow")
global gGuanYuCtrls := Map()
global __GuanYuSkillKeys := []

UiApplyWindow(gGuanYuGui)
gGuanYuGui.OnEvent("Escape", GuanYuGuiEscape)
gGuanYuGui.OnEvent("Close", GuanYuGuiClose)

UiSkillKeyEditor(gGuanYuGui, gGuanYuCtrls, "GuanYu", "已添加技能键", "猛攻发射键", "添加技能键", "删除技能键", "设置发射键", GuanYuAddKey, GuanYuDeleteKey, GuanYuSetShotKey, GuanYuSave, GuanYuHelp, "手动延迟(ms)")

GuanYuGetCtrl(name) {
    global gGuanYuCtrls
    return gGuanYuCtrls.Has(name) ? gGuanYuCtrls[name] : ""
}

ShowGuiGuanYu(*) {
    global gMainGui, gGuanYuGui
    if IsObject(gMainGui) {
        gGuanYuGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gGuanYuGui.Title := "关羽自动战戟猛攻"
    gGuanYuGui.Show("w184 h270")
    GuanYuLoadConfig()
    DisableGuiMain()
}

HideGuiGuanYu() {
    gGuanYuGui.Hide()
    EnableGuiMain()
}

GuanYuGuiEscape(*) {
    GuanYuSave()
}

GuanYuGuiClose(*) {
    GuanYuSave()
}

GuanYuHelp(*) {
    MsgBox("1、添加触发猛攻的技能键`n2、设置游戏中猛攻的发射键（默认Space）`n3、可手动设置发射前延迟(ms，默认300)`n4、保存配置，启动连发并使用", "如何使用关羽自动战戟猛攻", "Iconi")
}

GuanYuAddKey(*) {
    global __GuanYuSkillKeys
    key := GetPressKey()
    if IsValueInArray(key, __GuanYuSkillKeys) {
        MsgBox("请勿重复添加按键",, "Icon!")
    } else {
        __GuanYuSkillKeys.Push(key)
    }
    GuanYuChangeListGui(__GuanYuSkillKeys)
    ctrl := GuanYuGetCtrl("GuanYuKeysListBox")
    for i, item in __GuanYuSkillKeys {
        if (item = key) {
            ctrl.Choose(i)
            break
        }
    }
}

GuanYuDeleteKey(*) {
    global __GuanYuSkillKeys
    DeleteValueInArray(GuanYuGetCtrl("GuanYuKeysListBox").Text, __GuanYuSkillKeys)
    GuanYuChangeListGui(__GuanYuSkillKeys)
}

GuanYuSave(*) {
    GuanYuSaveConfig()
    HideGuiGuanYu()
}

GuanYuSetShotKey(*) {
    GuanYuGetCtrl("GuanYuShotKey").Text := GetPressKey()
}

GuanYuChangeListGui(keys) {
    ctrl := GuanYuGetCtrl("GuanYuKeysListBox")
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

GuanYuSaveConfig() {
    global __GuanYuSkillKeys
    keysString := ""
    for v in __GuanYuSkillKeys {
        keysString .= v "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    delay := Round((Trim(GuanYuGetCtrl("GuanYuDelay").Text) = "" ? 300 : GuanYuGetCtrl("GuanYuDelay").Text) + 0)
    if (delay < 0) {
        delay := 0
    } else if (delay > 500) {
        delay := 500
    }
    GuanYuGetCtrl("GuanYuDelay").Text := delay
    SavePreset(GetNowSelectPreset(), "GuanYuSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "GuanYuShotKey", GuanYuGetCtrl("GuanYuShotKey").Text)
    SavePreset(GetNowSelectPreset(), "GuanYuDelay", delay)
}

GuanYuLoadConfig() {
    global __GuanYuSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "GuanYuShotKey", "Space")
    delay := Round(LoadPreset(GetNowSelectPreset(), "GuanYuDelay", 300) + 0)
    if (delay < 0) {
        delay := 0
    } else if (delay > 500) {
        delay := 500
    }
    __GuanYuSkillKeys := GuanYuLoadKeys(GetNowSelectPreset())
    GuanYuChangeListGui(__GuanYuSkillKeys)
    GuanYuGetCtrl("GuanYuShotKey").Text := shotKey
    GuanYuGetCtrl("GuanYuDelay").Text := delay
}
