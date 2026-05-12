; 宠物技能：子进程轮询监听键边沿，每次按下发一发。

PetSkillRegisterHotkeys() {
    return
}

PetSkillUnregisterHotkeys() {
    return
}

ExPetSkill_Run() {
    presetName := LoadLastPresetTrimmed()
    if (presetName = "" || !LoadPreset(presetName, "PetSkillState", false)) {
        return
    }
    shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "PetSkillShotKey"))
    if (shotKey = "") {
        return
    }
    skillKeys := PetSkillUniqueSkillKeysByPressKey(PetSkillLoadKeys(presetName))
    if (skillKeys.Length = 0) {
        return
    }
    shotToken := GetKeycode.ToSendToken(shotKey)
    if (shotToken = "") {
        return
    }
    keyDownState := Map()
    pressKeys := []
    for sk in skillKeys {
        pressKey := GetKeycode.ToProbeKey(GetKeycode.CanonMainKey(sk))
        if (pressKey = "") {
            continue
        }
        pressKeys.Push(pressKey)
        keyDownState[pressKey] := false
    }
    loop {
        if WinActive("ahk_group DNF") {
            for pressKey in pressKeys {
                isDown := GetKeyState(pressKey, "P")
                wasDown := keyDownState.Get(pressKey, false)
                if (isDown && !wasDown) {
                    SendIP(shotToken)
                }
                keyDownState[pressKey] := isDown
            }
        } else {
            for pressKey in pressKeys {
                keyDownState[pressKey] := false
            }
        }
        Sleep(1)
    }
}

PetSkillUniqueSkillKeysByPressKey(skillKeys) {
    seen := Map()
    out := []
    if !IsObject(skillKeys) {
        return out
    }
    for sk in skillKeys {
        canon := GetKeycode.CanonMainKey(sk)
        if (canon = "") {
            continue
        }
        probeKey := GetKeycode.ToProbeKey(canon)
        if (probeKey = "" || seen.Has(probeKey)) {
            continue
        }
        seen[probeKey] := true
        out.Push(canon)
    }
    return out
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
