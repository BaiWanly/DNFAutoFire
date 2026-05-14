#Requires AutoHotkey v2.0

; 自定义单实例控制：重复启动时关闭现有实例，再由新实例继续启动。
global __SingleInstance_hMutex := 0
global __SingleInstance_WaitTimeoutMs := 1200
global __SingleInstance_PollIntervalMs := 30

SingleInstance_MutexName() {
    p := A_ScriptFullPath
    if (StrLen(p) > 220) {
        h := 0
        loop parse p {
            h := Mod(h * 31 + Ord(A_LoopField), 0x7FFFFFFF)
        }
        p := Format("h%x", h)
    }
    return "Local\DAFAutoFire_" StrReplace(p, "\", "_")
}

SingleInstance_TryHandOffAndExit() {
    global __SingleInstance_hMutex
    name := SingleInstance_MutexName()
    DllCall("kernel32\SetLastError", "UInt", 0)
    __SingleInstance_hMutex := DllCall("kernel32\CreateMutexW", "Ptr", 0, "Int", false, "WStr", name, "Ptr")
    if DllCall("kernel32\GetLastError", "UInt") != 183 {
        return
    }
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    try {
        hwnd := WinExist("DAF连发工具 - DNF AutoFire")
        if !hwnd {
            hwnd := WinExist("DAF连发工具")
        }
        pid := hwnd ? WinGetPID("ahk_id " hwnd) : 0
        processHandle := SingleInstance_OpenProcessHandle(pid)
        if hwnd {
            WinClose("ahk_id " hwnd)
        }
    }
    DetectHiddenWindows(false)
    h := __SingleInstance_hMutex
    __SingleInstance_hMutex := 0
    if h {
        DllCall("kernel32\CloseHandle", "Ptr", h)
    }
    SingleInstance_WaitForPreviousExit(name, hwnd, processHandle)
}

SingleInstance_OpenProcessHandle(pid) {
    static SYNCHRONIZE := 0x00100000
    if !pid {
        return 0
    }
    return DllCall("kernel32\OpenProcess", "UInt", SYNCHRONIZE, "Int", false, "UInt", pid, "Ptr")
}

SingleInstance_WaitForPreviousExit(name, hwnd, processHandle := 0) {
    global __SingleInstance_WaitTimeoutMs, __SingleInstance_PollIntervalMs
    static WAIT_OBJECT_0 := 0
    static WAIT_TIMEOUT := 258
    if processHandle {
        waitResult := DllCall("kernel32\WaitForSingleObject", "Ptr", processHandle, "UInt", __SingleInstance_WaitTimeoutMs, "UInt")
        DllCall("kernel32\CloseHandle", "Ptr", processHandle)
        if (waitResult = WAIT_OBJECT_0) {
            return
        }
        if (waitResult != WAIT_TIMEOUT) {
            return
        }
    }
    winRef := hwnd ? "ahk_id " hwnd : ""
    deadline := A_TickCount + __SingleInstance_WaitTimeoutMs
    while (A_TickCount < deadline) {
        if !SingleInstance_PreviousInstanceExists(name, winRef) {
            return
        }
        Sleep(__SingleInstance_PollIntervalMs)
    }
}

SingleInstance_PreviousInstanceExists(name, winRef := "") {
    if (winRef != "" && WinExist(winRef)) {
        return true
    }
    DllCall("kernel32\SetLastError", "UInt", 0)
    h := DllCall("kernel32\CreateMutexW", "Ptr", 0, "Int", false, "WStr", name, "Ptr")
    exists := DllCall("kernel32\GetLastError", "UInt") = 183
    if h {
        DllCall("kernel32\CloseHandle", "Ptr", h)
    }
    return exists
}

SingleInstance_ReleaseMutex() {
    global __SingleInstance_hMutex
    if (__SingleInstance_hMutex) {
        DllCall("kernel32\CloseHandle", "Ptr", __SingleInstance_hMutex)
        __SingleInstance_hMutex := 0
    }
}
