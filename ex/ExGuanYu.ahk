; 关羽：按下监听键边沿后延迟一发发射键；KeyRouter + 主进程

global _GuanYuShotKeyCode := ""
global _GuanYuDelayMs := 300
global _GuanYuPendingTimerByPressKey := Map()

GuanYuUnregisterHotkeys() {
    global _GuanYuPendingTimerByPressKey
    for pressKey, fn in _GuanYuPendingTimerByPressKey {
        try SetTimer(fn, 0)
    }
    _GuanYuPendingTimerByPressKey := Map()
}

GuanYuRegisterHotkeys() {
    global _GuanYuShotKeyCode, _GuanYuDelayMs
    if !MainCheckboxOn("GuanYu") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "GuanYuState", false) {
        return
    }
    shotKey := LoadPresetSafe(presetName, "GuanYuShotKey")
    if (shotKey = "") {
        return
    }
    skillKeys := GuanYuLoadKeys(presetName)
    skillKeys := GuanYuUniqueSkillKeysByPressKey(skillKeys)
    if (skillKeys.Length = 0) {
        return
    }
    delayMs := Round(LoadPreset(presetName, "GuanYuDelay", 300) + 0)
    if (delayMs < 20) {
        delayMs := 20
    } else if (delayMs > 500) {
        delayMs := 500
    }
    _GuanYuShotKeyCode := Key2NoVkSC(shotKey)
    _GuanYuDelayMs := delayMs

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
        KeyRouter.SubscribeDown(id, GuanYuOnSkillDown.Bind(pressKey))
        KeyRouter.SubscribeUp(id, GuanYuOnSkillUp.Bind(pressKey))
    }
}

GuanYuUniqueSkillKeysByPressKey(skillKeys) {
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

GuanYuOnSkillDown(pressKey, *) {
    global _GuanYuDelayMs, _GuanYuPendingTimerByPressKey
    fn := GuanYuExecuteDelayed.Bind(pressKey)
    _GuanYuPendingTimerByPressKey[pressKey] := fn
    SetTimer(fn, -_GuanYuDelayMs)
}

GuanYuOnSkillUp(pressKey, *) {
    global _GuanYuPendingTimerByPressKey
    if _GuanYuPendingTimerByPressKey.Has(pressKey) {
        try SetTimer(_GuanYuPendingTimerByPressKey[pressKey], 0)
        _GuanYuPendingTimerByPressKey.Delete(pressKey)
    }
}

GuanYuExecuteDelayed(pressKey, *) {
    global _GuanYuShotKeyCode, _GuanYuPendingTimerByPressKey
    if _GuanYuPendingTimerByPressKey.Has(pressKey) {
        _GuanYuPendingTimerByPressKey.Delete(pressKey)
    }
    if !WinActive("ahk_group DNF") {
        return
    }
    try {
        SendIP(_GuanYuShotKeyCode)
    } catch {
    }
}

GuanYuLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "GuanYuSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
