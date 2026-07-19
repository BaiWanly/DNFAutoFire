GlobalPause_EventHandle() {
    static hEvent := 0
    if hEvent {
        return hEvent
    }
    eventName := "Local\DNFAutoFire.GlobalPause." StrReplace(A_ScriptFullPath, "\", ".")
    hEvent := DllCall("CreateEvent", "ptr", 0, "int", true, "int", false, "str", eventName, "ptr")
    return hEvent
}

GlobalPause_IsPaused() {
    hEvent := GlobalPause_EventHandle()
    return hEvent && DllCall("WaitForSingleObject", "ptr", hEvent, "uint", 0, "uint") = 0
}

GlobalPause_SetPaused(paused) {
    hEvent := GlobalPause_EventHandle()
    if !hEvent {
        return false
    }
    DllCall(paused ? "SetEvent" : "ResetEvent", "ptr", hEvent)
    return paused
}

GlobalPause_Toggle() {
    return GlobalPause_SetPaused(!GlobalPause_IsPaused())
}
