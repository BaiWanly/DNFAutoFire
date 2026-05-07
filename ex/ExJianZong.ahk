; 剑宗：按住技能键超过延迟后高频发该键（与原 while 内每 1ms 可 Send 等价）；KeyRouter + 主进程

global _JianZongShotKeyCode := ""
global _JianZongPressKey := ""
global _JianZongDelayMs := 200
global _JianZongHoldStartTick := 0

JianZongUnregisterHotkeys() {
    SetTimer(JianZongTick, 0)
    global _JianZongPressKey, _JianZongHoldStartTick
    _JianZongPressKey := ""
    _JianZongHoldStartTick := 0
}

JianZongRegisterHotkeys() {
    global _JianZongShotKeyCode, _JianZongPressKey, _JianZongDelayMs
    JianZongUnregisterHotkeys()
    if !MainCheckboxOn("JianZong") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "JianZongState", false) {
        return
    }
    skillKey := LoadPresetSafe(presetName, "JianZongSkillKey")
    if (skillKey = "") {
        return
    }
    delay := Round(LoadPreset(presetName, "JianZongDelay", 200) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 3000) {
        delay := 3000
    }
    _JianZongShotKeyCode := Key2NoVkSC(skillKey)
    _JianZongPressKey := Key2PressKey(skillKey)
    _JianZongDelayMs := delay

    id := AutoFireMainHotkeyIdFromOrigin(skillKey)
    KeyRouter.SubscribeDown(id, JianZongOnDown)
    KeyRouter.SubscribeUp(id, JianZongOnUp)
}

JianZongOnDown(*) {
    global _JianZongHoldStartTick
    _JianZongHoldStartTick := A_TickCount
    SetTimer(JianZongTick, 1)
}

JianZongOnUp(*) {
    SetTimer(JianZongTick, 0)
    global _JianZongHoldStartTick
    _JianZongHoldStartTick := 0
}

JianZongTickShouldStop() {
    global _JianZongPressKey
    if !WinActive("ahk_group DNF")
        return true
    if (_JianZongPressKey = "" || !GetKeyState(_JianZongPressKey, "P"))
        return true
    return false
}

JianZongTick() {
    global _JianZongShotKeyCode, _JianZongDelayMs, _JianZongHoldStartTick
    if JianZongTickShouldStop() {
        SetTimer(JianZongTick, 0)
        return
    }
    if (A_TickCount - _JianZongHoldStartTick <= _JianZongDelayMs) {
        return
    }
    static busy := false
    if busy {
        return
    }
    busy := true
    try {
        SendIP(_JianZongShotKeyCode)
    } finally {
        busy := false
    }
}
