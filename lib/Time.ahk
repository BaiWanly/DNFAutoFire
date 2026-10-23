; 解除系统的Time限制，让Time可以小于10ms
UnlockSystemTimeLimit(){
    DllCall("Winmm\timeBeginPeriod", "UInt", 1)
}

; 恢复系统的Time限制
RestoreSystemTimeLimit(){
    DllCall("Winmm\timeEndPeriod", "UInt", 1)
}
