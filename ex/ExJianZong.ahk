; 剑宗：子进程轮询按住时长，超过延时后高频发送技能键。

JianZongRegisterHotkeys() {
    return
}

JianZongUnregisterHotkeys() {
    return
}

ExJianZong_Run() {
    presetName := LoadLastPresetTrimmed()
    if (presetName = "" || !LoadPreset(presetName, "JianZongState", false)) {
        return
    }
    skillKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "JianZongSkillKey"))
    if (skillKey = "") {
        return
    }
    delayMs := Round(LoadPreset(presetName, "JianZongDelay", 200) + 0)
    if (delayMs < 20) {
        delayMs := 20
    } else if (delayMs > 3000) {
        delayMs := 3000
    }
    sendToken := GetKeycode.ToSendToken(skillKey)
    pressKey := GetKeycode.ToProbeKey(skillKey)
    if (sendToken = "" || pressKey = "") {
        return
    }
    holdStartAt := 0
    loop {
        if WinActive("ahk_group DNF") {
            if GetKeyState(pressKey, "P") {
                if !holdStartAt {
                    holdStartAt := A_TickCount
                } else if (A_TickCount - holdStartAt > delayMs) {
                    SendIP(sendToken)
                }
            } else {
                holdStartAt := 0
            }
        } else {
            holdStartAt := 0
        }
        Sleep(1)
    }
}
