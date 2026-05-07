SendIP(keyCode) {
    Critical("On")
    try {
        SetKeyDelay(-1, 12)
        SendEvent("{Blind}{" keyCode "}")
    } finally {
        Critical("Off")
    }
}
