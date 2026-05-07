; 自动连招：KeyRouter 监听触发键 + 负定时器链执行技能间隔（主进程，非阻塞）

global _ComboSkills := []
global _ComboTriggerPressKey := ""
global _ComboSentMap := Map()
global _ComboLoopMode := false
global _ComboBreakOnRelease := false
global _ComboMainIntervalMs := 20
global _ComboRunning := false
global _ComboAbortRequested := false
global _ComboPendingTimer := ""
global _ComboSkillsCount := 0
global _ComboActiveProfileIdx := 0
global _ComboRuntimeProfiles := []

ComboUnregisterHotkeys() {
    global _ComboSkillsCount, _ComboSentMap, _ComboRuntimeProfiles, _ComboActiveProfileIdx
    ComboFinish()
    _ComboSkillsCount := 0
    _ComboSentMap := Map()
    _ComboRuntimeProfiles := []
    _ComboActiveProfileIdx := 0
}

ComboClearPendingTimer() {
    global _ComboPendingTimer
    if (_ComboPendingTimer != "") {
        try SetTimer(_ComboPendingTimer, 0)
        _ComboPendingTimer := ""
    }
}

ComboSchedule(fn, delayMs) {
    ComboClearPendingTimer()
    global _ComboPendingTimer
    _ComboPendingTimer := fn
    SetTimer(fn, -delayMs)
}

ComboCloneRuntimeProfile(pr) {
    skillsCopy := []
    if IsObject(pr) && IsObject(pr.skills) {
        loop pr.skills.Length {
            if !pr.skills.Has(A_Index) {
                continue
            }
            it := pr.skills[A_Index]
            if !IsObject(it) {
                continue
            }
            skillsCopy.Push({ key: it.key, delay: it.delay })
        }
    }
    trig := IsObject(pr) ? pr.trigger : ""
    loopOn := IsObject(pr) && pr.loop ? true : false
    return { trigger: trig, loop: loopOn, skills: skillsCopy }
}

ComboRegisterHotkeys() {
    global _ComboMainIntervalMs, _ComboRuntimeProfiles
    ComboUnregisterHotkeys()
    if !MainCheckboxOn("Combo") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "ComboState", false) {
        return
    }
    profiles := ComboLoadProfilesFromPreset(presetName)
    _ComboRuntimeProfiles := []
    loop profiles.Length {
        if !profiles.Has(A_Index) {
            continue
        }
        _ComboRuntimeProfiles.Push(ComboCloneRuntimeProfile(profiles[A_Index]))
    }
    mainIntervalMs := Round(LoadPreset(presetName, "MainAutoFireInterval", 20) + 0)
    if (mainIntervalMs < 1) {
        mainIntervalMs := 1
    } else if (mainIntervalMs > 200) {
        mainIntervalMs := 200
    }
    _ComboMainIntervalMs := mainIntervalMs

    loop _ComboRuntimeProfiles.Length {
        if !_ComboRuntimeProfiles.Has(A_Index) {
            continue
        }
        i := A_Index
        p := _ComboRuntimeProfiles[i]
        if (Trim(p.trigger) = "" || p.skills.Length = 0) {
            continue
        }
        id := AutoFireMainHotkeyIdFromOrigin(p.trigger)
        KeyRouter.SubscribeDown(id, ComboOnDown.Bind(i))
        KeyRouter.SubscribeUp(id, ComboOnUp.Bind(i))
    }
}

ComboOnDown(setIdx, *) {
    global _ComboSentMap, _ComboRunning, _ComboRuntimeProfiles
    if (setIdx < 1 || setIdx > _ComboRuntimeProfiles.Length || !_ComboRuntimeProfiles.Has(setIdx)) {
        return
    }
    p := _ComboRuntimeProfiles[setIdx]
    if (Trim(p.trigger) = "" || p.skills.Length = 0) {
        return
    }
    if (p.loop) {
        if !_ComboRunning {
            _ComboSentMap[setIdx] := true
            ComboStartFromDown(setIdx)
        }
        return
    }
    if _ComboSentMap.Get(setIdx, false) {
        return
    }
    _ComboSentMap[setIdx] := true
    ComboStartFromDown(setIdx)
}

ComboOnUp(setIdx, *) {
    global _ComboSentMap, _ComboRunning, _ComboBreakOnRelease, _ComboActiveProfileIdx
    _ComboSentMap[setIdx] := false
    if (_ComboRunning && _ComboActiveProfileIdx = setIdx && _ComboBreakOnRelease) {
        ComboAbortSequence()
    }
}

ComboPrepareProfile(setIdx) {
    global _ComboRuntimeProfiles, _ComboSkills, _ComboSkillsCount, _ComboTriggerPressKey, _ComboLoopMode, _ComboBreakOnRelease
    if (setIdx < 1 || setIdx > _ComboRuntimeProfiles.Length || !_ComboRuntimeProfiles.Has(setIdx)) {
        return false
    }
    p := _ComboRuntimeProfiles[setIdx]
    if (Trim(p.trigger) = "" || p.skills.Length = 0) {
        return false
    }
    _ComboSkills := p.skills
    _ComboSkillsCount := p.skills.Length
    _ComboTriggerPressKey := Key2PressKey(p.trigger)
    _ComboLoopMode := p.loop
    _ComboBreakOnRelease := _ComboLoopMode
    return true
}

ComboShouldAbort() {
    global _ComboAbortRequested, _ComboBreakOnRelease, _ComboTriggerPressKey
    if _ComboAbortRequested || !WinActive("ahk_group DNF")
        return true
    if (_ComboBreakOnRelease && _ComboTriggerPressKey != "" && !GetKeyState(_ComboTriggerPressKey, "P"))
        return true
    return false
}

ComboStartFromDown(setIdx) {
    global _ComboRunning, _ComboAbortRequested, _ComboActiveProfileIdx
    if _ComboRunning {
        return
    }
    if !ComboPrepareProfile(setIdx) {
        return
    }
    _ComboActiveProfileIdx := setIdx
    _ComboRunning := true
    _ComboAbortRequested := false
    ComboLeadDone()
}

ComboLeadDone(*) {
    if ComboShouldAbort() {
        ComboFinish()
        return
    }
    ComboSendSkillAt(1)
}

ComboSendSkillAt(idx) {
    global _ComboSkills, _ComboSkillsCount
    if ComboShouldAbort() {
        ComboFinish()
        return
    }
    if (idx > _ComboSkillsCount) {
        ComboChainComplete()
        return
    }
    if !_ComboSkills.Has(idx) {
        ComboChainComplete()
        return
    }
    item := _ComboSkills[idx]
    if !IsObject(item) {
        ComboSendSkillAt(idx + 1)
        return
    }
    try {
        SendIP(Key2NoVkSC(item.key))
    } catch {
    }
    delay := item.delay + 0
    if (delay <= 0) {
        ComboSendSkillAt(idx + 1)
        return
    }
    ComboSchedule(ComboAfterSkillGap.Bind(idx + 1), delay)
}

ComboAfterSkillGap(nextIdx, *) {
    if ComboShouldAbort() {
        ComboFinish()
        return
    }
    ComboSendSkillAt(nextIdx)
}

ComboChainComplete() {
    global _ComboLoopMode, _ComboTriggerPressKey, _ComboMainIntervalMs
    if ComboShouldAbort() {
        ComboFinish()
        return
    }
    if (_ComboLoopMode && _ComboTriggerPressKey != "" && GetKeyState(_ComboTriggerPressKey, "P")) {
        if (_ComboMainIntervalMs > 0) {
            ComboSchedule(ComboLeadDone, _ComboMainIntervalMs)
        } else {
            ComboLeadDone()
        }
        return
    }
    ComboFinish()
}

ComboAbortSequence() {
    global _ComboAbortRequested
    _ComboAbortRequested := true
    ComboClearPendingTimer()
    ComboFinish()
}

ComboFinish() {
    global _ComboRunning, _ComboAbortRequested, _ComboActiveProfileIdx
    ComboClearPendingTimer()
    _ComboRunning := false
    _ComboAbortRequested := false
    _ComboActiveProfileIdx := 0
}
