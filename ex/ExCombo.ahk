; 自动连招：子进程轮询多个 profile 触发键，保持同一时刻只跑一个序列。

ComboRegisterHotkeys() {
    return
}

ComboUnregisterHotkeys() {
    return
}

ExCombo_Run() {
    presetName := LoadLastPresetTrimmed()
    if (presetName = "" || !LoadPreset(presetName, "ComboState", false)) {
        return
    }
    profiles := ComboLoadProfilesFromPreset(presetName)
    runtimeProfiles := []
    for profile in profiles {
        runtime := ComboBuildRuntimeProfile(profile)
        if IsObject(runtime) {
            runtimeProfiles.Push(runtime)
        }
    }
    if (runtimeProfiles.Length = 0) {
        return
    }
    loop {
        if !WinActive("ahk_group DNF") {
            for profile in runtimeProfiles {
                profile.waitingRelease := false
            }
            Sleep(1)
            continue
        }
        for profile in runtimeProfiles {
            triggerDown := GetKeyState(profile.triggerPressKey, "P")
            if (profile.loop) {
                if (triggerDown) {
                    ComboRunProfile(profile)
                }
            } else {
                if (triggerDown && !profile.waitingRelease) {
                    ComboRunProfile(profile)
                    profile.waitingRelease := true
                } else if !triggerDown {
                    profile.waitingRelease := false
                }
            }
        }
        Sleep(1)
    }
}

ComboBuildRuntimeProfile(profile) {
    if !IsObject(profile) || !IsObject(profile.skills) || profile.skills.Length = 0 {
        return 0
    }
    triggerKey := GetKeycode.CanonMainKey(Trim(profile.trigger))
    if (triggerKey = "") {
        return 0
    }
    triggerPressKey := GetKeycode.ToProbeKey(triggerKey)
    if (triggerPressKey = "") {
        return 0
    }
    skills := []
    for item in profile.skills {
        if !IsObject(item) {
            continue
        }
        skillKey := GetKeycode.CanonMainKey(item.key)
        if (skillKey = "") {
            continue
        }
        sendToken := GetKeycode.ToSendToken(skillKey)
        if (sendToken = "") {
            continue
        }
        delayMs := Round(item.delay + 0)
        if (delayMs < 20) {
            delayMs := 20
        } else if (delayMs > 3000) {
            delayMs := 3000
        }
        skills.Push({ sendToken: sendToken, delay: delayMs })
    }
    if (skills.Length = 0) {
        return 0
    }
    return {
        triggerPressKey: triggerPressKey,
        loop: profile.loop ? true : false,
        waitingRelease: false,
        skills: skills
    }
}

ComboRunProfile(profile) {
    for item in profile.skills {
        if (profile.loop && !GetKeyState(profile.triggerPressKey, "P")) {
            return
        }
        SendIP(item.sendToken)
        if (item.delay <= 0) {
            continue
        }
        beginTick := A_TickCount
        while (A_TickCount - beginTick < item.delay) {
            if !WinActive("ahk_group DNF") {
                return
            }
            if (profile.loop && !GetKeyState(profile.triggerPressKey, "P")) {
                return
            }
            Sleep(1)
        }
    }
}
