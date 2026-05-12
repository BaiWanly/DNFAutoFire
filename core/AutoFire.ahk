#Requires AutoHotkey v2.0

AutoFire_Run(keyName, intervalMs, pressDurationMs) {
    keyName := GetKeycode.CanonMainKey(keyName)
    if (keyName = "") {
        return
    }
    intervalMs := PresetManager.NormalizeInterval(intervalMs)
    pressDurationMs := PresetManager.NormalizePressDuration(pressDurationMs)
    probeKey := GetKeycode.ToProbeKey(keyName)
    sendToken := GetKeycode.ToSendToken(keyName)
    if (probeKey = "" || sendToken = "") {
        return
    }
    nextSendAt := 0
    loop {
        if WinActive("ahk_group DNF") {
            if GetKeyState(probeKey, "P") {
                if (probeKey = "Tab" && (GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P"))) {
                    Sleep(1)
                    continue
                }
                now := A_TickCount
                if (nextSendAt = 0 || now >= nextSendAt) {
                    SendIP(sendToken, pressDurationMs)
                    nextSendAt := now + intervalMs
                }
            } else {
                nextSendAt := 0
            }
        } else {
            nextSendAt := 0
        }
        Sleep(1)
    }
}
