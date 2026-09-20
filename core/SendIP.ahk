#Requires AutoHotkey v2.0

SendIP(keyCode, keyDelayMs := 8){
    if GlobalPause_IsPaused() {
        return
    }
    keyDelayMs := Round(keyDelayMs + 0)
    if (keyDelayMs < 0) {
        keyDelayMs := 0
    }
    lockTaken := SendIP_Lock()
    Critical("On")
    try {
        SetKeyDelay(-1, -1)
        SendIP_KeyEvent(keyCode, true)
        DllCall("Sleep", "UInt", keyDelayMs)
        SendIP_KeyEvent(keyCode, false)
        DllCall("Sleep", "UInt", 2)
    } finally {
        SendIP_Unlock(lockTaken)
        Critical("Off")
    }
}

; 分离式按下：供需要跨定时器保持按下的路径使用（一键连招「按下」）。
; 与 SendIP 的区别是按下保持期间不持锁、不占临界区，因此同进程的其他发送方不会被长时间阻塞，
; 保持中的键也能被随时抬起（SendIPUp）。返回是否真的发出了按下（全局暂停时为 false）。
SendIPDown(keyCode) {
    if GlobalPause_IsPaused() {
        return false
    }
    lockTaken := SendIP_Lock()
    Critical("On")
    try {
        SetKeyDelay(-1, -1)
        SendIP_KeyEvent(keyCode, true)
    } finally {
        SendIP_Unlock(lockTaken)
        Critical("Off")
    }
    return true
}

; 分离式抬起：不检查全局暂停，保证暂停或重置时已按下的键一定被释放
SendIPUp(keyCode) {
    lockTaken := SendIP_Lock()
    Critical("On")
    try {
        SetKeyDelay(-1, -1)
        SendIP_KeyEvent(keyCode, false)
        DllCall("Sleep", "UInt", 2)
    } finally {
        SendIP_Unlock(lockTaken)
        Critical("Off")
    }
}

SendIP_KeyEvent(keyCode, isDown) {
    suffix := isDown ? " DownTemp}" : " Up}"
    SendEvent("{Blind}{" keyCode suffix)
}

SendIP_Lock() {
    lockHandle := SendIP_LockHandle()
    if !lockHandle {
        return false
    }
    waitResult := DllCall("WaitForSingleObject", "ptr", lockHandle, "UInt", 0xFFFFFFFF, "UInt")
    return (waitResult = 0 || waitResult = 0x80)
}

SendIP_Unlock(lockTaken) {
    if !lockTaken {
        return
    }
    DllCall("ReleaseMutex", "ptr", SendIP_LockHandle())
}

SendIP_LockHandle() {
    static hMutex := 0
    if (hMutex) {
        return hMutex
    }
    mutexName := "DNFAutoFire.SendIP." StrReplace(A_ScriptFullPath, "\", ".")
    hMutex := DllCall("CreateMutex", "ptr", 0, "int", false, "str", mutexName, "ptr")
    return hMutex
}
