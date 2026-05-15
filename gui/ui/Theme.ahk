#Requires AutoHotkey v2.0

global UiTheme := Map(
    "FontName", "微软雅黑",
    "FontSize", "s9",
    "TextColor", "c222222",
    "MutedColor", "c666666",
    "KeyOffColor", "c1B57B7",
    "KeyOnColor", "cD72638",
    "WindowBg", "F7F8FA"
)

UiApplyWindow(gui) {
    global UiTheme
    gui.BackColor := UiTheme["WindowBg"]
    gui.SetFont(UiTheme["FontSize"] " " UiTheme["TextColor"], UiTheme["FontName"])
}

UiSetDefaultFont(gui, options := "") {
    global UiTheme
    fontOptions := options = "" ? UiTheme["FontSize"] " " UiTheme["TextColor"] : options
    gui.SetFont(fontOptions, UiTheme["FontName"])
}

UiSetKeyFont(gui, size, enabled := false) {
    global UiTheme
    color := enabled ? UiTheme["KeyOnColor"] : UiTheme["KeyOffColor"]
    weight := enabled ? "Bold" : "Norm"
    gui.SetFont(size " " color " " weight, UiTheme["FontName"])
}
