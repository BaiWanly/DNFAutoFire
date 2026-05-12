; 旅人：子进程轮询监听键数组，任一按住则按主间隔连续发射。

LvRenRegisterHotkeys() {
    return
}

LvRenUnregisterHotkeys() {
    return
}

ExLvRen_Run() {
    presetName := LoadLastPresetTrimmed()
    if (presetName = "" || !LoadPreset(presetName, "LvRenState", false)) {
        return
    }
    shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "LvRenShotKey"))
    if (shotKey = "") {
        return
    }
    skillKeys := LvRenUniqueSkillKeysByPressKey(LvRenLoadKeys(presetName))
    if (skillKeys.Length = 0) {
        return
    }
    intervalMs := PresetManager.NormalizeInterval(LoadPreset(presetName, "MainAutoFireInterval", 20))
    shotToken := GetKeycode.ToSendToken(shotKey)
    if (shotToken = "") {
        return
    }
    pressKeys := []
    for sk in skillKeys {
        pressKey := GetKeycode.ToProbeKey(GetKeycode.CanonMainKey(sk))
        if (pressKey != "") {
            pressKeys.Push(pressKey)
        }
    }
    nextSendAt := 0
    loop {
        if WinActive("ahk_group DNF") {
            active := false
            for pressKey in pressKeys {
                if GetKeyState(pressKey, "P") {
                    active := true
                    break
                }
            }
            now := A_TickCount
            if active {
                if (nextSendAt = 0 || now >= nextSendAt) {
                    SendIP(shotToken)
                    nextSendAt := now + intervalMs
                }
            } else {
                nextSendAt := 0
            }
        } else {
            nextSendAt := 0
        }
        Sleep(1)
    }
}

LvRenUniqueSkillKeysByPressKey(skillKeys) {
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
