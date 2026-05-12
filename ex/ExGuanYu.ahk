; 关羽：子进程轮询监听键边沿；按下后登记延时，到点必发一次，提前松开不取消。

GuanYuRegisterHotkeys() {
    return
}

GuanYuUnregisterHotkeys() {
    return
}

ExGuanYu_Run() {
    presetName := LoadLastPresetTrimmed()
    if (presetName = "" || !LoadPreset(presetName, "GuanYuState", false)) {
        return
    }
    shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "GuanYuShotKey"))
    if (shotKey = "") {
        return
    }
    skillKeys := GuanYuUniqueSkillKeysByPressKey(GuanYuLoadKeys(presetName))
    if (skillKeys.Length = 0) {
        return
    }
    delayMs := Round(LoadPreset(presetName, "GuanYuDelay", 300) + 0)
    if (delayMs < 20) {
        delayMs := 20
    } else if (delayMs > 500) {
        delayMs := 500
    }
    shotToken := GetKeycode.ToSendToken(shotKey)
    if (shotToken = "") {
        return
    }
    pressKeys := []
    keyDownState := Map()
    pendingTriggerAt := Map()
    for sk in skillKeys {
        pressKey := GetKeycode.ToProbeKey(GetKeycode.CanonMainKey(sk))
        if (pressKey = "") {
            continue
        }
        pressKeys.Push(pressKey)
        keyDownState[pressKey] := false
        pendingTriggerAt[pressKey] := 0
    }
    loop {
        if WinActive("ahk_group DNF") {
            now := A_TickCount
            for pressKey in pressKeys {
                isDown := GetKeyState(pressKey, "P")
                wasDown := keyDownState.Get(pressKey, false)
                if (isDown && !wasDown) {
                    pendingTriggerAt[pressKey] := now + delayMs
                }
                triggerAt := pendingTriggerAt.Get(pressKey, 0)
                if (triggerAt > 0 && now >= triggerAt) {
                    SendIP(shotToken)
                    pendingTriggerAt[pressKey] := 0
                }
                keyDownState[pressKey] := isDown
            }
        } else {
            for pressKey in pressKeys {
                keyDownState[pressKey] := false
                pendingTriggerAt[pressKey] := 0
            }
        }
        Sleep(1)
    }
}

GuanYuUniqueSkillKeysByPressKey(skillKeys) {
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
