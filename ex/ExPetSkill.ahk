; 宠物技能：监听键边沿发一发发射键；KeyRouter + 主进程

global _PetSkillShotKeyCode := ""

PetSkillUnregisterHotkeys() {
}

PetSkillRegisterHotkeys() {
    global _PetSkillShotKeyCode
    PetSkillUnregisterHotkeys()
    if !MainCheckboxOn("PetSkill") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "PetSkillState", false) {
        return
    }
    shotKey := LoadPresetSafe(presetName, "PetSkillShotKey")
    if (shotKey = "") {
        return
    }
    skillKeys := PetSkillLoadKeys(presetName)
    skillKeys := PetSkillUniqueSkillKeysByPressKey(skillKeys)
    if (skillKeys.Length = 0) {
        return
    }
    _PetSkillShotKeyCode := Key2NoVkSC(shotKey)

    loop skillKeys.Length {
        if !skillKeys.Has(A_Index) {
            continue
        }
        sk := skillKeys[A_Index]
        if (sk = "") {
            continue
        }
        pressKey := Key2PressKey(sk)
        if (pressKey = "") {
            continue
        }
        id := AutoFireMainHotkeyIdFromOrigin(sk)
        KeyRouter.SubscribeDown(id, PetSkillOnDown.Bind(pressKey))
    }
}

PetSkillUniqueSkillKeysByPressKey(skillKeys) {
    seen := Map()
    out := []
    if !IsObject(skillKeys) {
        return out
    }
    n := skillKeys is Array ? skillKeys.Length : 0
    loop n {
        if !skillKeys.Has(A_Index) {
            continue
        }
        sk := skillKeys[A_Index]
        if (sk = "") {
            continue
        }
        pk := Key2PressKey(sk)
        if (pk = "") || seen.Has(pk) {
            continue
        }
        seen[pk] := true
        out.Push(sk)
    }
    return out
}

PetSkillOnDown(pressKey, *) {
    global _PetSkillShotKeyCode
    if !WinActive("ahk_group DNF") {
        return
    }
    try {
        SendIP(_PetSkillShotKeyCode)
    } catch {
    }
}

PetSkillLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "PetSkillSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
