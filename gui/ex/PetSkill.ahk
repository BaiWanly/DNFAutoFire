#Requires AutoHotkey v2.0

global gPetSkillGui := Gui("+ToolWindow")
global gPetSkillCtrls := Map()
global __PetSkillSkillKeys := []

UiApplyWindow(gPetSkillGui)
gPetSkillGui.OnEvent("Escape", PetSkillGuiEscape)
gPetSkillGui.OnEvent("Close", PetSkillGuiClose)

UiSkillKeyEditor(gPetSkillGui, gPetSkillCtrls, "PetSkill", "已添加触发键", "宠物技能键", "添加触发键", "删除触发键", "设置宠物键", PetSkillAddKey, PetSkillDeleteKey, PetSkillSetShotKey, PetSkillSave, PetSkillHelp)

PetSkillGetCtrl(name) {
    global gPetSkillCtrls
    return gPetSkillCtrls.Has(name) ? gPetSkillCtrls[name] : ""
}

ShowGuiPetSkill(*) {
    global gMainGui, gPetSkillGui
    if IsObject(gMainGui) {
        gPetSkillGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gPetSkillGui.Title := "自动宠物技能"
    gPetSkillGui.Show("w184 h210")
    PetSkillLoadConfig()
    DisableGuiMain()
}

HideGuiPetSkill() {
    gPetSkillGui.Hide()
    EnableGuiMain()
}

PetSkillGuiEscape(*) {
    PetSkillSave()
}

PetSkillGuiClose(*) {
    PetSkillSave()
}

PetSkillHelp(*) {
    MsgBox("1、添加你想触发宠物技能时按下的技能键`n2、设置游戏中的宠物技能键（默认Z）`n3、保存配置，启动连发并使用", "如何使用自动宠物技能", "Iconi")
}

PetSkillAddKey(*) {
    global __PetSkillSkillKeys
    key := GetPressKey()
    if IsValueInArray(key, __PetSkillSkillKeys) {
        MsgBox("请勿重复添加按键",, "Icon!")
    } else {
        __PetSkillSkillKeys.Push(key)
    }
    PetSkillChangeListGui(__PetSkillSkillKeys)
    ctrl := PetSkillGetCtrl("PetSkillKeysListBox")
    for i, item in __PetSkillSkillKeys {
        if (item = key) {
            ctrl.Choose(i)
            break
        }
    }
}

PetSkillDeleteKey(*) {
    global __PetSkillSkillKeys
    DeleteValueInArray(PetSkillGetCtrl("PetSkillKeysListBox").Text, __PetSkillSkillKeys)
    PetSkillChangeListGui(__PetSkillSkillKeys)
}

PetSkillSave(*) {
    PetSkillSaveConfig()
    HideGuiPetSkill()
}

PetSkillSetShotKey(*) {
    PetSkillGetCtrl("PetSkillShotKey").Text := GetPressKey()
}

PetSkillChangeListGui(keys) {
    ctrl := PetSkillGetCtrl("PetSkillKeysListBox")
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

PetSkillSaveConfig() {
    global __PetSkillSkillKeys
    keysString := ""
    for i, v in __PetSkillSkillKeys {
        keysString .= v "|"
    }
    keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    SavePreset(GetNowSelectPreset(), "PetSkillSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "PetSkillShotKey", PetSkillGetCtrl("PetSkillShotKey").Text)
}

PetSkillLoadConfig() {
    global __PetSkillSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "PetSkillShotKey", "Z")
    __PetSkillSkillKeys := PetSkillLoadKeys(GetNowSelectPreset())
    PetSkillChangeListGui(__PetSkillSkillKeys)
    PetSkillGetCtrl("PetSkillShotKey").Text := shotKey
}
