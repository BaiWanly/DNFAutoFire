#Requires AutoHotkey v2.0

; 自动奔跑独立运行时：单独子进程承载方向键热键与双击补发，
; 避免与其余 EX 功能共用同一进程的定时器和键盘钩子。

class AutoRunRuntime {
    static _ctx := 0

    static Run(presetName := "") {
        ProcessSetPriority("High")
        SetStoreCapsLockMode(false)
        RegisterGameWindowGroup()
        try InstallKeybdHook()
        try UnlockSystemTimeLimit()
        OnExit(ObjBindMethod(AutoRunRuntime, "OnExit"))

        presetName := presetName = "" ? ResolvePresetName(LoadLastPreset()) : NormalizePresetName(presetName)
        autoRun := AutoRunRuntime_Build(presetName)
        if !IsObject(autoRun) {
            return
        }

        this._ctx := {
            autoRun: autoRun,
            wasActive: WinActive("ahk_group DNF") != 0
        }

        this._EnableHooks()
        Suspend(false)

        loop {
            this._WatchFocusLoss()
            Sleep(50)
        }
    }

    static _EnableHooks() {
        ar := this._ctx.autoRun
        HotIfWinActive("ahk_group DNF")
        Hotkey("~$" ar.rightKey, ObjBindMethod(AutoRunRuntime, "RightDown"), "On")
        Hotkey("~$" ar.rightKey " Up", ObjBindMethod(AutoRunRuntime, "RightUp"), "On")
        Hotkey("~$" ar.leftKey, ObjBindMethod(AutoRunRuntime, "LeftDown"), "On")
        Hotkey("~$" ar.leftKey " Up", ObjBindMethod(AutoRunRuntime, "LeftUp"), "On")
        if (ar.pauseHotkey != "") {
            Hotkey("~$" ar.pauseHotkey, ObjBindMethod(AutoRunRuntime, "TogglePause"), "On")
        }
        HotIf()
    }

    static _DisableHooks() {
        ctx := this._ctx
        if !IsObject(ctx) || !IsObject(ctx.autoRun) {
            return
        }
        ar := ctx.autoRun
        try SetTimer(ar.rightTickFn, 0)
        try SetTimer(ar.leftTickFn, 0)
        try {
            HotIfWinActive("ahk_group DNF")
            try Hotkey("~$" ar.rightKey, "Off")
            try Hotkey("~$" ar.rightKey " Up", "Off")
            try Hotkey("~$" ar.leftKey, "Off")
            try Hotkey("~$" ar.leftKey " Up", "Off")
            if (ar.pauseHotkey != "") {
                try Hotkey("~$" ar.pauseHotkey, "Off")
            }
            HotIf()
        } catch {
            try HotIf()
        }
    }

    static _StopActive() {
        ar := this._ctx.autoRun
        ar.pressingRight := false
        ar.pressingLeft := false
        ar.doubleRight := false
        ar.doubleLeft := false
        ar.rightCounter := 0
        ar.leftCounter := 0
        try SetTimer(ar.rightTickFn, 0)
        try SetTimer(ar.leftTickFn, 0)
    }

    static _Paused() {
        ar := this._ctx.autoRun
        return ar.paused || GlobalPause_IsPaused()
    }

    static TogglePause(*) {
        ar := this._ctx.autoRun
        ar.paused := !ar.paused
    }

    static RightDown(*) {
        ar := this._ctx.autoRun
        if this._Paused() {
            return
        }
        if !ar.pressingRight {
            ar.pressingRight := true
            ar.doubleRight := false
            ar.rightCounter := 0
            SetTimer(ar.rightTickFn, ar.tickMs)
        }
    }

    static RightUp(*) {
        ar := this._ctx.autoRun
        ar.pressingRight := false
        SetTimer(ar.rightTickFn, 0)
        SendEvent(ar.rightUpSend)
    }

    static RightTick(*) {
        ar := this._ctx.autoRun
        if this._Paused() {
            return
        }
        ar.rightCounter++
        if (ar.pressingRight && !ar.doubleRight) {
            SendEvent(ar.rightPulseSend)
            ar.doubleRight := true
        }
        if (ar.rightCounter >= 3) {
            SetTimer(ar.rightTickFn, 0)
        }
    }

    static LeftDown(*) {
        ar := this._ctx.autoRun
        if this._Paused() {
            return
        }
        if !ar.pressingLeft {
            ar.pressingLeft := true
            ar.doubleLeft := false
            ar.leftCounter := 0
            SetTimer(ar.leftTickFn, ar.tickMs)
        }
    }

    static LeftUp(*) {
        ar := this._ctx.autoRun
        ar.pressingLeft := false
        SetTimer(ar.leftTickFn, 0)
        SendEvent(ar.leftUpSend)
    }

    static LeftTick(*) {
        ar := this._ctx.autoRun
        if this._Paused() {
            return
        }
        ar.leftCounter++
        if (ar.pressingLeft && !ar.doubleLeft) {
            SendEvent(ar.leftPulseSend)
            ar.doubleLeft := true
        }
        if (ar.leftCounter >= 3) {
            SetTimer(ar.leftTickFn, 0)
        }
    }

    static _WatchFocusLoss() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        isActive := WinActive("ahk_group DNF") != 0
        if (ctx.wasActive && !isActive) {
            this._StopActive()
        }
        ctx.wasActive := isActive
    }

    static OnExit(exitReason, exitCode) {
        this._DisableHooks()
        try RestoreSystemTimeLimit()
    }
}

AutoRunRuntime_Run(presetName := "") {
    AutoRunRuntime.Run(presetName)
}

AutoRunRuntime_HasRunnable(presetName) {
    presetName := presetName = "" ? ResolvePresetName(LoadLastPreset()) : NormalizePresetName(presetName)
    return IsObject(AutoRunRuntime_Build(presetName))
}

AutoRunRuntime_Build(presetName) {
    if !LoadPreset(presetName, "AutoRunState", false) {
        return 0
    }
    leftKey := LoadPreset(presetName, "AutoRunLeftKey", "Left")
    rightKey := LoadPreset(presetName, "AutoRunRightKey", "Right")
    if (leftKey = "") {
        leftKey := "Left"
    }
    if (rightKey = "") {
        rightKey := "Right"
    }
    tickMs := ExAction_Clamp(LoadPreset(presetName, "AutoRunDelay", 30), 1, 400)
    pauseHotkeyName := Trim(LoadPreset(presetName, "AutoRunPauseHotkey", ""))
    pauseHotkey := pauseHotkeyName = "" ? "" : Key2PressKey(GetOriginKeyName(pauseHotkeyName))
    leftSendKey := AutoRunRuntime_SendKey(leftKey)
    rightSendKey := AutoRunRuntime_SendKey(rightKey)
    ar := {
        leftKey: leftKey,
        rightKey: rightKey,
        pauseHotkey: pauseHotkey,
        paused: false,
        tickMs: tickMs,
        rightPulseSend: "{" rightSendKey " Down}{" rightSendKey " Up}{" rightSendKey " Down}",
        rightUpSend: "{" rightSendKey " Up}",
        leftPulseSend: "{" leftSendKey " Down}{" leftSendKey " Up}{" leftSendKey " Down}",
        leftUpSend: "{" leftSendKey " Up}",
        pressingRight: false,
        doubleRight: false,
        rightCounter: 0,
        pressingLeft: false,
        doubleLeft: false,
        leftCounter: 0
    }
    ar.rightTickFn := ObjBindMethod(AutoRunRuntime, "RightTick")
    ar.leftTickFn := ObjBindMethod(AutoRunRuntime, "LeftTick")
    return ar
}

AutoRunRuntime_SendKey(key) {
    key := GetOriginKeyName(key)
    if (key = "Left" || key = "Right" || key = "Up" || key = "Down") {
        return key
    }
    return Key2NoVkSC(key)
}
