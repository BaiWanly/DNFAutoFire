#Requires AutoHotkey v2.0

global gSettingGui := Gui("-MinimizeBox -MaximizeBox -Theme")
global gSettingCtrls := Map()
global __SettingGeneralCtrls := []
global __SettingAboutCtrls := []

gSettingGui.OnEvent("Escape", SettingGuiEscape)
gSettingGui.OnEvent("Close", SettingGuiClose)

; 不用 Tab：无主题(-Theme)下 SysTabControl 会画出横穿内容的横线且易错位；改用顶部按钮切换页面
gSettingCtrls["NavGeneral"] := gSettingGui.Add("Button", "x16 y10 w118 h26", "通用设置")
gSettingCtrls["NavGeneral"].OnEvent("Click", (*) => SettingShowPage(1))
gSettingCtrls["NavAbout"] := gSettingGui.Add("Button", "x142 y10 w118 h26", "关于")
gSettingCtrls["NavAbout"].OnEvent("Click", (*) => SettingShowPage(2))

gSettingCtrls["SettingAutoStart"] := gSettingGui.Add("CheckBox", "vSettingAutoStart x16 y44 h20", "软件打开后自动启动连发")
__SettingGeneralCtrls.Push(gSettingCtrls["SettingAutoStart"])
gSettingCtrls["SettingOnSystemStart"] := gSettingGui.Add("CheckBox", "vSettingOnSystemStart x16 y70 h20", "开机后自动启动")
__SettingGeneralCtrls.Push(gSettingCtrls["SettingOnSystemStart"])
gSettingCtrls["SettingBlockWin"] := gSettingGui.Add("CheckBox", "vSettingBlockWin x16 y96 h20", "游戏内屏蔽Win键")
__SettingGeneralCtrls.Push(gSettingCtrls["SettingBlockWin"])
gSettingCtrls["SettingAutoPresetSwitch"] := gSettingGui.Add("CheckBox", "vSettingAutoPresetSwitch x16 y122 h20 Checked0", "自动识别")
__SettingGeneralCtrls.Push(gSettingCtrls["SettingAutoPresetSwitch"])
__btnSettingPreset := gSettingGui.Add("Button", "x16 y150 w200 h30", "自动识别设置")
__btnSettingPreset.OnEvent("Click", ShowGuiPresetAutoSwitch)
__SettingGeneralCtrls.Push(__btnSettingPreset)
__SettingGeneralCtrls.Push(gSettingGui.Add("Text", "x16 y190 w352 h126", "1. 没有单独设置的角色或识别不成功会自动切换到第一个配置`n`n2. 窗口位置、大小、分辨率变化，都需要重新截取血条图像和技能识别图像（或调整回原来的窗口大小和位置）`n`n3. 技能加点、技能栏排列变化只需要重新截取技能识别图像"))
__btnSettingSave := gSettingGui.Add("Button", "x278 y324 w88 h38", "保存")
__btnSettingSave.OnEvent("Click", SettingSave)
__SettingGeneralCtrls.Push(__btnSettingSave)

__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y44 w352 h120", "作者： 某亚瑟`n图标： Ousumu"))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y72 w352 h24 +0x200", "原帖地址："))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y94 w352 h24", "<a href=`"https://bbs.colg.cn/thread-8894989-1-1.html`">https://bbs.colg.cn/thread-8894989-1-1.html</a>"))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y116 w352 h24 +0x200", "二次开发："))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y138 w352 h24", "<a href=`"https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722`">https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722</a>"))

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
    gSettingGui.Show("w380 h372")
    SettingLoad()
    SettingShowPage(1)
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
    gSettingGui.Show("w380 h372")
    SettingLoad()
    SettingShowPage(2)
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

    SettingNow()
    HideGuiSetting()
}

SettingLoad() {
    SettingGetCtrl("SettingAutoStart").Value := LoadConfig("SettingAutoStart", false)
    SettingGetCtrl("SettingOnSystemStart").Value := LoadConfig("SettingOnSystemStart", false)
    SettingGetCtrl("SettingBlockWin").Value := LoadConfig("SettingBlockWin", false)
    SettingGetCtrl("SettingAutoPresetSwitch").Value := Trim(LoadConfig("SettingAutoPresetSwitch", "0")) = "1"
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
