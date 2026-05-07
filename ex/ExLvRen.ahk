; 旅人：与战法相同模式——监听键任一按住则以主间隔发发射键（KeyRouter + 主进程）

global _LvRenKeyHeld := Map()
global _LvRenActiveCount := 0
global _LvRenShotKeyCode := ""
global _LvRenShotIntervalMs := 20

LvRenUnregisterHotkeys() {
    global _LvRenKeyHeld, _LvRenActiveCount
    SetTimer(LvRenShotTick, 0)
    _LvRenKeyHeld := Map()
    _LvRenActiveCount := 0
}

LvRenRegisterHotkeys() {
    global _LvRenShotKeyCode, _LvRenShotIntervalMs
    LvRenUnregisterHotkeys()
    if !MainCheckboxOn("LvRen") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "LvRenState", false) {
        return
    }
    shotKey := LoadPresetSafe(presetName, "LvRenShotKey")
    if (shotKey = "") {
        return
    }
    skillKeys := LvRenLoadKeys(presetName)
    skillKeys := LvRenUniqueSkillKeysByPressKey(skillKeys)
    if (skillKeys.Length = 0) {
        return
    }
    intervalMs := Round(LoadPreset(presetName, "MainAutoFireInterval", 20) + 0)
    if (intervalMs < 1) {
        intervalMs := 1
    } else if (intervalMs > 200) {
        intervalMs := 200
    }
    _LvRenShotKeyCode := Key2NoVkSC(shotKey)
    _LvRenShotIntervalMs := intervalMs

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
        KeyRouter.SubscribeDown(id, LvRenSkillDown.Bind(pressKey))
        KeyRouter.SubscribeUp(id, LvRenSkillUp.Bind(pressKey))
    }
}

LvRenUniqueSkillKeysByPressKey(skillKeys) {
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

LvRenSkillDown(pressKey, *) {
    global _LvRenKeyHeld, _LvRenActiveCount, _LvRenShotIntervalMs
    if _LvRenKeyHeld.Get(pressKey, false) {
        return
    }
    _LvRenKeyHeld[pressKey] := true
    _LvRenActiveCount += 1
    if (_LvRenActiveCount = 1) {
        LvRenShotTick()
        SetTimer(LvRenShotTick, _LvRenShotIntervalMs)
    }
}

LvRenSkillUp(pressKey, *) {
    global _LvRenKeyHeld, _LvRenActiveCount
    if !_LvRenKeyHeld.Get(pressKey, false) {
        return
    }
    _LvRenKeyHeld[pressKey] := false
    _LvRenActiveCount -= 1
    if (_LvRenActiveCount <= 0) {
        _LvRenActiveCount := 0
        SetTimer(LvRenShotTick, 0)
    }
}

LvRenShotTick() {
    global _LvRenShotKeyCode
    if !WinActive("ahk_group DNF") {
        return
    }
    static busy := false
    if busy {
        return
    }
    busy := true
    try {
        SendIP(_LvRenShotKeyCode)
    } finally {
        busy := false
    }
}

LvRenLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "LvRenSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
