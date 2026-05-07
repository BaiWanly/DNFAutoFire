#Requires AutoHotkey v2.0

global gSettingGui := Gui("-MinimizeBox -MaximizeBox -Theme")
global gSettingCtrls := Map()
global __SettingGeneralCtrls := []
global __SettingAboutCtrls := []
global gSettingSuppressQuickKeyChange := false

GuiTheme_Apply(gSettingGui)

gSettingGui.OnEvent("Escape", SettingGuiEscape)
gSettingGui.OnEvent("Close", SettingGuiClose)

; 不用 Tab：无主题(-Theme)下 SysTabControl 会画出横穿内容的横线且易错位；改用顶部按钮切换页面
gSettingCtrls["NavGeneral"] := GuiTheme_FlatBtn(gSettingGui, "x16 y14 w118 h28", "通用设置", (*) => SettingShowPage(1), false)
gSettingCtrls["NavAbout"] := GuiTheme_FlatBtn(gSettingGui, "x142 y14 w118 h28", "关于", (*) => SettingShowPage(2), false)

gSettingCtrls["SettingAutoStart"] := gSettingGui.Add("CheckBox", "vSettingAutoStart x16 y52 h22", "软件打开后自动启动连发")
__SettingGeneralCtrls.Push(gSettingCtrls["SettingAutoStart"])
gSettingCtrls["SettingOnSystemStart"] := gSettingGui.Add("CheckBox", "vSettingOnSystemStart x16 y80 h22", "开机后自动启动")
__SettingGeneralCtrls.Push(gSettingCtrls["SettingOnSystemStart"])
gSettingCtrls["SettingBlockWin"] := gSettingGui.Add("CheckBox", "vSettingBlockWin x16 y108 h22", "游戏内屏蔽Win键")
__SettingGeneralCtrls.Push(gSettingCtrls["SettingBlockWin"])
__SettingGeneralCtrls.Push(gSettingGui.Add("Text", "x16 y136 w200 h20 +0x200", "快速切换热键"))
gSettingCtrls["SettingQuickChangeHotKey"] := gSettingGui.Add("Hotkey", "vSettingQuickChangeHotKey x16 y158 w200 h22 -E0x200 Border")
gSettingCtrls["SettingQuickChangeHotKey"].OnEvent("Change", SettingQuickChangeHotKeyChanged)
__SettingGeneralCtrls.Push(gSettingCtrls["SettingQuickChangeHotKey"])
gSettingCtrls["SettingAutoPresetSwitch"] := gSettingGui.Add("CheckBox", "vSettingAutoPresetSwitch x16 y186 h22 Checked0", "自动识别")
__SettingGeneralCtrls.Push(gSettingCtrls["SettingAutoPresetSwitch"])
__btnSettingPreset := GuiTheme_FlatBtn(gSettingGui, "x16 y214 w200 h30", "自动识别设置", ShowGuiPresetAutoSwitch, false)
__SettingGeneralCtrls.Push(__btnSettingPreset)
__SettingGeneralCtrls.Push(gSettingGui.Add("Text", "x16 y252 w352 h78", "1. 未识别到自动切换到首个配置`n2. 游戏窗口位置、大小、分辨率变化，都需要重新截取识别图像。（或调整回原来的窗口大小和位置）"))
__btnSettingSave := GuiTheme_FlatBtn(gSettingGui, "x278 y336 w88 h40", "保存", SettingSave, true)
__SettingGeneralCtrls.Push(__btnSettingSave)

__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y52 w352 h44", "作者： 某亚瑟`n图标： Ousumu"))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y100 w352 h22 +0x200", "原帖地址："))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y122 w352 h40", "<a href=`"https://bbs.colg.cn/thread-8894989-1-1.html`">https://bbs.colg.cn/thread-8894989-1-1.html</a>"))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y170 w352 h22 +0x200", "二次开发："))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y192 w352 h40", "<a href=`"https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722`">https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722</a>"))

for ctrl in __SettingAboutCtrls
    ctrl.Visible := false

SettingShowPage(page) {
    global __SettingGeneralCtrls, __SettingAboutCtrls
    if (page != 1 && page != 2)
        page := 1
    for ctrl in __SettingGeneralCtrls
        ctrl.Visible := (page = 1)
    for ctrl in __SettingAboutCtrls
        ctrl.Visible := (page = 2)
}

SettingGetCtrl(name) {
    global gSettingCtrls
    return gSettingCtrls.Has(name) ? gSettingCtrls[name] : ""
}

SettingGuiEscape(*) {
    HideGuiSetting()
}

SettingGuiClose(*) {
    HideGuiSetting()
}

ShowGuiSetting(*) {
    global gMainGui, gSettingGui
    try PresetRecognition_CancelPending()
    DisableGuiMain()
    if IsObject(gMainGui) {
        gSettingGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gSettingGui.Title := "软件设置"
    gSettingGui.Show("w392 h400")
    SettingLoad()
    SettingShowPage(1)
    GuiTheme_FlatChromeHwnd(SettingGetCtrl("SettingQuickChangeHotKey").Hwnd)
}

; 与 ShowGuiSetting 相同，但打开后显示「关于」页
ShowGuiSettingAbout(*) {
    global gMainGui, gSettingGui
    try PresetRecognition_CancelPending()
    DisableGuiMain()
    if IsObject(gMainGui) {
        gSettingGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gSettingGui.Title := "软件设置"
    gSettingGui.Show("w392 h400")
    SettingLoad()
    SettingShowPage(2)
    GuiTheme_FlatChromeHwnd(SettingGetCtrl("SettingQuickChangeHotKey").Hwnd)
}

HideGuiSetting() {
    gSettingGui.Hide()
    EnableGuiMain()
}

SettingSave(*) {
    global _OnSystemStart, _BlockWin
    settingAutoStart := SettingGetCtrl("SettingAutoStart").Value
    settingOnSystemStart := SettingGetCtrl("SettingOnSystemStart").Value
    settingBlockWin := SettingGetCtrl("SettingBlockWin").Value
    settingAutoPresetSwitch := SettingGetCtrl("SettingAutoPresetSwitch").Value

    SaveConfig("SettingAutoStart", settingAutoStart)
    SaveConfig("SettingOnSystemStart", settingOnSystemStart)
    SaveConfig("SettingBlockWin", settingBlockWin)
    SaveConfig("SettingAutoPresetSwitch", settingAutoPresetSwitch ? 1 : 0)

    _OnSystemStart := settingOnSystemStart
    _BlockWin := settingBlockWin

    QuickChangeHotKey_PersistAndRegister(SettingGetCtrl("SettingQuickChangeHotKey").Value)
    SettingNow()
    HideGuiSetting()
}

SettingLoad() {
    global gSettingSuppressQuickKeyChange
    SettingGetCtrl("SettingAutoStart").Value := LoadConfig("SettingAutoStart", false)
    SettingGetCtrl("SettingOnSystemStart").Value := LoadConfig("SettingOnSystemStart", false)
    SettingGetCtrl("SettingBlockWin").Value := LoadConfig("SettingBlockWin", false)
    SettingGetCtrl("SettingAutoPresetSwitch").Value := Trim(LoadConfig("SettingAutoPresetSwitch", "0")) = "1"
    qhk := LoadConfig("QuickChangeHotKey")
    if (qhk = "") {
        qhk := "!``"
    }
    gSettingSuppressQuickKeyChange := true
    SettingGetCtrl("SettingQuickChangeHotKey").Value := qhk
    gSettingSuppressQuickKeyChange := false
}

SettingQuickChangeHotKeyChanged(*) {
    global gSettingSuppressQuickKeyChange
    if (gSettingSuppressQuickKeyChange) {
        return
    }
    QuickChangeHotKey_PersistAndRegister(SettingGetCtrl("SettingQuickChangeHotKey").Value)
}

SettingNow() {
    if (_OnSystemStart) {
        FileCreateShortcut(A_ScriptFullPath, A_Startup "\DAF连发工具.lnk")
    } else {
        try FileDelete(A_Startup "\DAF连发工具.lnk")
    }
    if (_BlockWin) {
        Hotkey("$*LWin", BlockWin, "On")
        Hotkey("$*RWin", BlockWin, "On")
    } else {
        try Hotkey("$*LWin", "Off")
        try Hotkey("$*RWin", "Off")
    }
    PresetRecognition_UpdateHotkeys()
}

BlockWin(*) {
}

global _AutoStart := LoadConfig("SettingAutoStart", false)
global _OnSystemStart := LoadConfig("SettingOnSystemStart", false)
global _BlockWin := LoadConfig("SettingBlockWin", false)

if (_BlockWin) {
    Hotkey("$*LWin", BlockWin, "On")
    Hotkey("$*RWin", BlockWin, "On")
}
