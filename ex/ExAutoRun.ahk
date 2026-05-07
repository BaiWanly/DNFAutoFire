; 自动奔跑：主进程事件驱动。KeyRouter 监听方向键，单次负定时器发送连跑指令。

class ExAutoRun {
    static _sides := Map()
    static _registered := false

    static RegisterHotkeys() {
        this.UnregisterHotkeys()
        if !MainCheckboxOn("AutoRun") {
            return
        }
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        leftKey := LoadPresetSafe(presetName, "AutoRunLeftKey")
        rightKey := LoadPresetSafe(presetName, "AutoRunRightKey")
        if (leftKey = "")
            leftKey := "Left"
        if (rightKey = "")
            rightKey := "Right"

        sides := Map()
        this._addSide(sides, "R", rightKey)
        this._addSide(sides, "L", leftKey)
        this._sides := sides

        for _, s in this._sides {
            KeyRouter.SubscribeDown(s.scID, s.downFn)
            KeyRouter.SubscribeUp(s.scID, s.upFn)
        }
        this._registered := true
    }

    static _addSide(sides, tag, logicalKey) {
        scID := AutoFireMainHotkeyIdFromOrigin(logicalKey)
        pulseSend := "{" logicalKey " Down}{" logicalKey " Up}{" logicalKey " Down}"
        upSend := "{" logicalKey " Up}"
        timerFn := ObjBindMethod(ExAutoRun, "Pulse", tag)
        sides[tag] := {
            scID: scID,
            pulseSend: pulseSend,
            upSend: upSend,
            timerFn: timerFn,
            downFn: ObjBindMethod(ExAutoRun, "Down", tag),
            upFn: ObjBindMethod(ExAutoRun, "Up", tag)
        }
    }

    static UnregisterHotkeys() {
        for _, s in this._sides {
            SetTimer(s.timerFn, 0)
        }
        this._sides := Map()
        this._registered := false
    }

    static Down(tag, *) {
        s := ExAutoRun._sides.Get(tag, "")
        if !IsObject(s) {
            return
        }
        SetTimer(s.timerFn, -25)
    }

    static Up(tag, *) {
        s := ExAutoRun._sides.Get(tag, "")
        if !IsObject(s) {
            return
        }
        SetTimer(s.timerFn, 0)
        SendEvent(s.upSend)
    }

    static Pulse(tag) {
        s := ExAutoRun._sides.Get(tag, "")
        if !IsObject(s) {
            return
        }
        if WinActive("ahk_group DNF") {
            SendEvent(s.pulseSend)
        }
    }
}
