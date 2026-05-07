#Requires AutoHotkey v2.0

global gQuickSwitchGui := Gui("-MinimizeBox -MaximizeBox -SysMenu +AlwaysOnTop -Theme +0x800000")
global gQuickSwitchCtrls := Map()

GuiTheme_Apply(gQuickSwitchGui)

gQuickSwitchGui.OnEvent("Escape", QuickSwitchGuiEscape)
gQuickSwitchGui.OnEvent("Close", QuickSwitchGuiClose)
gQuickSwitchGui.SetFont("s12 norm", GuiTheme_Face)
; 列表高度按行数即可，避免挤占下方说明与按钮；预设较多时显示滚动条
gQuickSwitchCtrls["QuickSwitchList"] := gQuickSwitchGui.Add("ListBox", "vQuickSwitchList x12 y12 w244 h132 -E0x200 Border")
gQuickSwitchCtrls["QuickSwitchList"].OnEvent("DoubleClick", QuickSwitchChangeList)
gQuickSwitchGui.SetFont("s10 norm c334155", GuiTheme_Face)
gQuickSwitchGui.Add("Text", "x12 y152 w244 h44", "使用键盘上下键选择配置，按空格或回车快速切换，按ESC关闭窗口")
GuiTheme_FlatBtn(gQuickSwitchGui, "x12 y204 w118 h38", "切换并启动连发", QuickSwitchStart, true)
GuiTheme_FlatBtn(gQuickSwitchGui, "x138 y204 w118 h38", "停止连发", QuickSwitchStop, false)

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
    ChangePreset(presetName)
    StartAutoFire()
    HideGuiQuickSwitch()
}

QuickSwitchStop(*) {
    StopAutoFire()
    HideGuiQuickSwitch()
}

ShowGuiQuickSwitch(*) {
    HideGuiMain()
    gQuickSwitchGui.Title := "快速切换"
    gQuickSwitchGui.Show("w268 h260")
    nowSelectPreset := GetNowSelectPreset()
    presetList := LoadAllPresetString()
    ctrl := QuickSwitchGetCtrl("QuickSwitchList")
    ctrl.Delete()
    idx := 0
    cnt := 0
    presetItems := StrSplit(presetList, "|")
    loop presetItems.Length {
        if !presetItems.Has(A_Index) {
            continue
        }
        item := presetItems[A_Index]
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
