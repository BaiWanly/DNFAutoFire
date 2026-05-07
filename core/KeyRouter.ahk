#Requires AutoHotkey v2.0

; 统一按键分发：同一物理键只注册一对 Hotkey，按下/抬起时广播给所有订阅者（主连发、战法等）
;
; 契约：SubscribeDown / SubscribeUp 仅在「真实边沿」触发——Windows 在按住期间会反复产生 KeyDown（键位重复），
; 此处只把第一次 Down 当作按下边沿，后续重复 Down 不再转发。扩展功能无需再单独处理系统重复。
; （极少数焦点切换丢 KeyUp 时 held 状态可能偏差；停止连发 KeyRouter.ClearAll 会清空状态。）
; DNF 失焦时物理 KeyUp 可能发生在 HotIfWinActive 之外，故用定时器检测 active→inactive 并 FlushAllHeld。

class KeyRouter {
    static _downSubs := Map()
    static _upSubs := Map()
    static _registeredScIDs := Map()
    ; 是否已从「边沿 Down」进入按住态；用于屏蔽键位重复产生的 Down
    static _heldFromEdge := Map()
    static _focusWasActive := false
    static _focusWatcherStarted := false
    static _focusTimerFn := 0

    ; scID 如 "sc01e" / "sc01E" 或单键名 "a"；统一小写 sc 前缀扫描码，避免同一键重复注册
    static _NormScID(scID) {
        s := Trim(scID "")
        if (s = "") {
            return ""
        }
        if RegExMatch(s, "i)^sc[0-9A-F]+$") {
            return StrLower(s)
        }
        return s
    }

    ; callback 为已 Bind 的函数对象，调用时无参
    static SubscribeDown(scID, callback) {
        if !IsObject(callback) {
            return
        }
        id := KeyRouter._NormScID(scID)
        if (id = "") {
            return
        }
        if !this._downSubs.Has(id) {
            this._downSubs[id] := []
        }
        this._downSubs[id].Push(callback)
        this._EnsureHotkey(id)
    }

    static SubscribeUp(scID, callback) {
        if !IsObject(callback) {
            return
        }
        id := KeyRouter._NormScID(scID)
        if (id = "") {
            return
        }
        if !this._upSubs.Has(id) {
            this._upSubs[id] := []
        }
        this._upSubs[id].Push(callback)
        this._EnsureHotkey(id)
    }

    static _EnsureHotkey(scID) {
        if this._registeredScIDs.Has(scID) {
            return
        }
        this._registeredScIDs[scID] := true
        hkDown := "~$" scID
        hkUp := "~$" scID " up"
        try {
            HotIfWinActive("ahk_group DNF")
            Hotkey(hkDown, (*) => KeyRouter.OnKeyDown(scID), "On")
            Hotkey(hkUp, (*) => KeyRouter.OnKeyUp(scID), "On")
            HotIf()
        } catch {
            try HotIf()
            this._registeredScIDs.Delete(scID)
        }
    }

    static OnKeyDown(scID, *) {
        if this._heldFromEdge.Get(scID, false) {
            return
        }
        this._heldFromEdge[scID] := true
        if !this._downSubs.Has(scID) {
            return
        }
        for fn in this._downSubs[scID] {
            try fn()
        }
    }

    static OnKeyUp(scID, *) {
        if this._heldFromEdge.Has(scID) {
            this._heldFromEdge.Delete(scID)
        }
        if !this._upSubs.Has(scID) {
            return
        }
        for fn in this._upSubs[scID] {
            try fn()
        }
    }

    static ClearAll() {
        scList := []
        for scID in this._registeredScIDs {
            scList.Push(scID)
        }
        if (scList.Length) {
            try {
                HotIfWinActive("ahk_group DNF")
                for scID in scList {
                    try Hotkey("~$" scID, "Off")
                    try Hotkey("~$" scID " up", "Off")
                }
                HotIf()
            } catch {
                try HotIf()
            }
        }
        this._registeredScIDs := Map()
        this._downSubs := Map()
        this._upSubs := Map()
        this._heldFromEdge := Map()
    }

    ; 对所有仍处于「边沿按下」态的键合成 KeyUp，清除订阅者的定时器等（焦点切走时 HotIf 收不到 up）
    static FlushAllHeld() {
        scList := []
        for scID in this._heldFromEdge {
            scList.Push(scID)
        }
        for scID in scList {
            this.OnKeyUp(scID)
        }
    }

    static StartFocusWatcher() {
        if this._focusWatcherStarted {
            return
        }
        this._focusWatcherStarted := true
        this._focusWasActive := WinActive("ahk_group DNF")
        this._focusTimerFn := ObjBindMethod(KeyRouter, "_FocusTick")
        SetTimer(this._focusTimerFn, 80)
    }

    static StopFocusWatcher() {
        if !this._focusWatcherStarted {
            return
        }
        SetTimer(this._focusTimerFn, 0)
        this._focusWatcherStarted := false
        this._focusTimerFn := 0
    }

    static _FocusTick(*) {
        active := WinActive("ahk_group DNF")
        if (KeyRouter._focusWasActive && !active) {
            KeyRouter.FlushAllHeld()
        }
        KeyRouter._focusWasActive := active
    }
}
