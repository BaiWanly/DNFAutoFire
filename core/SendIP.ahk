SendIP(keyCode, keyDelayMs := 8){
    if GlobalPause_IsPaused() {
        return
    }
    keyDelayMs := Round(keyDelayMs + 0)
    if (keyDelayMs < 0) {
        keyDelayMs := 0
    }
    lockHandle := SendIP_LockHandle()
    lockTaken := false
    if (lockHandle) {
        waitResult := DllCall("WaitForSingleObject", "ptr", lockHandle, "UInt", 0xFFFFFFFF, "UInt")
        lockTaken := (waitResult = 0 || waitResult = 0x80)
    }
    Critical("On")
    try {
        SetKeyDelay(-1, -1)
        SendEvent("{Blind}{" keyCode " DownTemp}")
        DllCall("Sleep", "UInt", keyDelayMs)
        SendEvent("{Blind}{" keyCode " Up}")
        DllCall("Sleep", "UInt", 2)
    } finally {
        if (lockTaken) {
            DllCall("ReleaseMutex", "ptr", lockHandle)
        }
        Critical("Off")
    }
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
