#Requires AutoHotkey v2.0

; 单实例：与主脚本中 #SingleInstance Off 配合，用命名互斥体保证仅一个进程；
; 再次启动时尝试激活已有主窗口（标题含「DAF连发工具」）后退出。

global __SingleInstance_hMutex := 0

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
    if DllCall("kernel32\GetLastError", "UInt") != 183 { ; ERROR_ALREADY_EXISTS
        return
    }
    try {
        if hwnd := WinExist("DAF连发工具") {
            WinActivate(hwnd)
        }
    }
    h := __SingleInstance_hMutex
    __SingleInstance_hMutex := 0
    if h {
        DllCall("kernel32\CloseHandle", "Ptr", h)
    }
    ExitApp()
}

SingleInstance_ReleaseMutex() {
    global __SingleInstance_hMutex
    if (__SingleInstance_hMutex) {
        DllCall("kernel32\CloseHandle", "Ptr", __SingleInstance_hMutex)
        __SingleInstance_hMutex := 0
    }
}
