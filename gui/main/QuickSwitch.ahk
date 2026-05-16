#Requires AutoHotkey v2.0

global gQuickSwitchGui := Gui("-MinimizeBox -MaximizeBox -SysMenu +AlwaysOnTop +0x800000")
global gQuickSwitchCtrls := Map()

gQuickSwitchGui.OnEvent("Escape", QuickSwitchGuiEscape)
gQuickSwitchGui.OnEvent("Close", QuickSwitchGuiClose)
gQuickSwitchCtrls["QuickSwitchList"] := gQuickSwitchGui.Add("ListBox", "vQuickSwitchList x12 y12 w244 h132")
gQuickSwitchCtrls["QuickSwitchList"].OnEvent("DoubleClick", QuickSwitchChangeList)
gQuickSwitchGui.SetFont()
gQuickSwitchGui.Add("Text", "x12 y152 w244 h44", MainText["QuickSwitchHint"])
gQuickSwitchGui.Add("Button", "x12 y204 w118 h38", MainText["QuickSwitchStart"]).OnEvent("Click", QuickSwitchStart)
gQuickSwitchGui.Add("Button", "x138 y204 w118 h38", MainText["QuickSwitchStop"]).OnEvent("Click", QuickSwitchStop)

QuickSwitchGetCtrl(name) {
    global gQuickSwitchCtrls
    return gQuickSwitchCtrls.Has(name) ? gQuickSwitchCtrls[name] : ""
}

QuickSwitchGuiEscape(*) {
    HideGuiQuickSwitch()
}

QuickSwitchGuiClose(*) {
    HideGuiQuickSwitch()
}

QuickSwitchStart(*) {
    presetName := QuickSwitchGetCtrl("QuickSwitchList").Text
    HideGuiQuickSwitch()
    StopAutoFire()
    EnterRunningMode(presetName)
}

QuickSwitchStop(*) {
    HideGuiQuickSwitch()
    SwitchToStoppedState()
    gMainGui.Show("w" MainLayout.GuiWidth() " h" MainLayout.GuiHeight())
    SetTimer(MainMutedLinkPoll, 100)
}

ShowGuiQuickSwitch(*) {
    HideGuiMain()
    gQuickSwitchGui.Title := MainText["QuickSwitchTitle"]
    gQuickSwitchGui.Show("w268 h256")
    nowSelectPreset := GetNowSelectPreset()
    presetList := LoadAllPresetString()
    ctrl := QuickSwitchGetCtrl("QuickSwitchList")
    ctrl.Delete()
    idx := 0
    cnt := 0
    for i, item in StrSplit(presetList, "|") {
        if (item != "") {
            ctrl.Add([item])
            cnt++
            if (item = nowSelectPreset) {
                idx := cnt
            }
        }
    }
    if (idx > 0) {
        ctrl.Choose(idx)
    } else if (cnt > 0) {
        ctrl.Choose(1)
    }
    ctrl.Focus()
    OnMessage(0x0100, QuickSwitchOnSpacePress)
}

HideGuiQuickSwitch() {
    gQuickSwitchGui.Hide()
    OnMessage(0x0100, QuickSwitchOnSpacePress, 0)
}

QuickSwitchOnSpacePress(wParam, lParam, msg, hwnd) {
    global gQuickSwitchGui
    if (!IsObject(gQuickSwitchGui) || !WinExist("ahk_id " gQuickSwitchGui.Hwnd) || !WinActive("ahk_id " gQuickSwitchGui.Hwnd)) {
        return
    }
    key := GetKeyName(Format("vk{1:02X}", wParam))
    if (key = "Space" || key = "Enter") {
        QuickSwitchStart()
    }
}

QuickSwitchChangeList(*) {
    QuickSwitchStart()
}
