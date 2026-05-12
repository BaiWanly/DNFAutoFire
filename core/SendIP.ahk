SendIP(keyCode, pressDurationMs := 8) {
    Critical("On")
    try {
        SetKeyDelay(-1, -1)
        SendEvent("{Blind}{" keyCode " DownTemp}")
        if (pressDurationMs > 0) {
            Sleep(pressDurationMs)
        }
        SendEvent("{Blind}{" keyCode " Up}")
        Sleep(2)
    } finally {
        Critical("Off")
    }
}
