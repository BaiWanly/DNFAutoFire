#Requires AutoHotkey v2.0

global gMainGui := Gui("-MinimizeBox -MaximizeBox +OwnDialogs")
global gMainCtrls := Map()
global _IsPresetUiSyncing := false

UiApplyWindow(gMainGui)
gMainGui.OnEvent("Escape", MainGuiEscape)
gMainGui.OnEvent("Close", MainGuiClose)

MainAdd(ctrlType, options, text := "") {
    global gMainGui, gMainCtrls
    return UiAdd(gMainCtrls, gMainGui, ctrlType, options, text)
}

MainGetCtrl(name) {
    global gMainCtrls
    return gMainCtrls.Has(name) ? gMainCtrls[name] : ""
}

; 主界面「其他功能」复选框是否勾选（供 core/Scripts.ahk 等使用，避免 v1 式未赋值全局变量触发 #Warn）
MainCheckboxOn(name) {
    c := MainGetCtrl(name)
    return IsObject(c) && c.Value
}

MainKeyFontSize(key) {
    if (key = "PrtSc" || key = "ScrLk" || key = "Pause" || key = "NumEnter" || key = "NumLk") {
        return "s7"
    }
    if (key ~= "^(Ins|Home|PgUp|Del|End|PgDn|Num[1-9])$") {
        return "s9"
    }
    return "s12"
}

MainAddKey(name, x, y, w := 36, h := 36, label := "") {
    global gMainGui, gMainCtrls
    label := label = "" ? name : label
    UiKeycap(gMainCtrls, gMainGui, name, UiRect(x, y, w, h), label, MainKeyFontSize(name), MainKeyClick)
}

MainAddKeyRow(startX, y, keys, keyH := 36, gap := 4) {
    x := startX
    for item in keys {
        name := item[1]
        if (name = "") {
            UiSpacer(&x, item[2])
            continue
        }
        w := item.Length >= 2 && item[2] != "" ? item[2] : 36
        label := item.Length >= 3 ? item[3] : name
        h := item.Length >= 4 ? item[4] : keyH
        MainAddKey(name, x, y, w, h, label)
        UiMoveX(&x, w, gap)
    }
}

MainBuildKeyboardPanel() {
    MainAddKeyRow(16, 30, [
        ["Esc"], ["", 34], ["F1"], ["F2"], ["F3"], ["F4"], ["", 20], ["F5"], ["F6"], ["F7"], ["F8"], ["", 20], ["F9"], ["F10"], ["F11"], ["F12"]
    ])
    MainAddKeyRow(16, 80, [
        ["Tilde", 36, "``"], ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"], ["Sub", 36, "-"], ["Add", 36, "+"], ["Backspace", 70, "←"]
    ])
    MainAddKeyRow(16, 120, [
        ["Tab", 54], ["Q"], ["W"], ["E"], ["R"], ["T"], ["Y"], ["U"], ["I"], ["O"], ["P"], ["LeftBracket", 36, "["], ["RightBracket", 36, "]"], ["Backslash", 52, "\"]
    ])
    MainAddKeyRow(16, 160, [
        ["Caps", 64], ["A"], ["S"], ["D"], ["F"], ["G"], ["H"], ["J"], ["K"], ["L"], ["Semicolon", 36, ";"], ["QuotationMark", 36, "'"], ["Enter", 82]
    ])
    MainAddKeyRow(16, 200, [
        ["LShift", 86, "Shift"], ["Z"], ["X"], ["C"], ["V"], ["B"], ["N"], ["M"], ["Comma", 36, ","], ["Period", 36, "."], ["Slash", 36, "/"], ["RShift", 100, "Shift"]
    ])
    MainAddKeyRow(16, 240, [
        ["LCtrl", 48, "Ctrl"], ["", 52], ["LAlt", 48, "Alt"], ["Space", 226], ["RAlt", 48, "Alt"], ["", 104], ["RCtrl", 48, "Ctrl"]
    ])

    MainAddKeyRow(630, 30, [["PrtSc"], ["ScrLk"], ["Pause"]])
    MainAddKeyRow(630, 70, [["Ins"], ["Home"], ["PgUp"]])
    MainAddKeyRow(630, 110, [["Del"], ["End"], ["PgDn"]])
    MainAddKeyRow(630, 200, [["", 40], ["Up", 36, "↑"]])
    MainAddKeyRow(630, 240, [["Left", 36, "←"], ["Down", 36, "↓"], ["Right", 36, "→"]])

    MainAddKeyRow(770, 80, [["NumLk"], ["NumSlash", 36, "/"], ["NumStar", 36, "*"], ["NumSub", 36, "-"]])
    MainAddKeyRow(770, 120, [["Num7"], ["Num8"], ["Num9"], ["NumAdd", 36, "+", 76]])
    MainAddKeyRow(770, 160, [["Num4"], ["Num5"], ["Num6"]])
    MainAddKeyRow(770, 200, [["Num1"], ["Num2"], ["Num3"], ["", 0], ["NumEnter", 36, "`n`n`nNum`nEnter", 76]])
    MainAddKeyRow(770, 240, [["Num0", 76], ["NumPeriod", 36, "."]])
}

MainBuildPresetPanel() {
    global gMainGui, gMainCtrls
    panelX := 8, panelY := 300
    rightX := panelX + 142
    buttonW := 58

    UiSection(gMainGui, UiRect(panelX, panelY, 274, 200), "配置设置 - [ 单击切换配置 ]")
    UiListBox(gMainCtrls, gMainGui, "Preset", UiRect(panelX + 8, panelY + 20, 126, 180), MainChangePresetByList)
    UiLabel(gMainGui, UiRect(rightX, panelY + 20, 120, 24), "当前配置")
    MainAdd("Text", "vCurrentPresetLabel " UiRect(rightX, panelY + 44, 120, 22, "+0x200 +0x400000"), "")

    for item in [
        ["MainNewPreset", "新建配置", MainNewPreset, 0, 0],
        ["MainRenamePreset", "重命名", MainRenamePreset, 1, 0],
        ["MainClonePreset", "克隆配置", MainClonePreset, 0, 1],
        ["MainDeletePreset", "删除配置", MainDeletePreset, 1, 1]
    ] {
        x := rightX + item[4] * (buttonW + 4)
        y := panelY + 72 + item[5] * 34
        UiButton(gMainCtrls, gMainGui, item[1], UiRect(x, y, buttonW, 30), item[2], item[3])
    }

    UiLabel(gMainGui, UiRect(rightX, panelY + 150, 72, 24), "快速切换热键")
    UiHotkey(gMainCtrls, gMainGui, "QuickChangeHotKey", UiRect(rightX, panelY + 174, 120, 20), MainSaveQuickChangeHotKey)
}

MainBuildActionButtons() {
    global gMainGui, gMainCtrls
    x := 838, w := 96, h := 60
    for item in [
        ["MainSetting", "软件设置", MainSetting, 305],
        ["MainCheckUpdate", "检查更新", MainCheckUpdate, 372],
        ["MainStart", "启动连发", MainStart, 440]
    ] {
        UiButton(gMainCtrls, gMainGui, item[1], UiRect(x, item[4], w, h), item[2], item[3])
    }
}

MainBuildFeaturePanel() {
    global gMainGui, gMainCtrls, __Version
    panelX := 290, panelY := 300
    checkX := panelX + 8, linkX := panelX + 26
    rowY := panelY + 20

    UiSection(gMainGui, UiRect(panelX, panelY, 538, 200), "其他功能")
    for item in [
        ["LvRen", "MainLvRen", "旅人自动流星", MainLvRen],
        ["GuanYu", "MainGuanYu", "关羽自动猛攻", MainGuanYu],
        ["JianZong", "MainJianZong", "太宗帝剑延迟", MainJianZong],
        ["ZhanFa", "MainZhanFa", "战法自动炫纹", MainZhanFa],
        ["PetSkill", "MainPetSkill", "自动宠物技能", MainPetSkill],
        ["AutoRun", "MainAutoRun", "自动奔跑", MainAutoRun]
    ] {
        UiCheckBox(gMainCtrls, gMainGui, item[1], UiRect(checkX, rowY, 16, 20))
        UiLink(gMainCtrls, gMainGui, item[2], UiRect(linkX, rowY + 3, 160, 20), item[3], item[4])
        rowY += 20
    }
    UiMutedLabel(gMainGui, UiRect(panelX + 74, panelY + 174, 170, 20), "当前版本: v" __Version)
}

UiSection(gMainGui, UiRect(8, 8, 926, 276), "按键设置 - [ 红色为启用连发 蓝色为关闭连发 ]")
MainBuildKeyboardPanel()
UiSetDefaultFont(gMainGui)

UiMutedLabel(gMainGui, UiRect(68, 240, 48, 36, "+0x400000 +Center +Disabled"), "Win")
UiMutedLabel(gMainGui, UiRect(454, 240, 48, 36, "+0x400000 +Center +Disabled"), "Fn")
UiMutedLabel(gMainGui, UiRect(506, 240, 48, 36, "+0x400000 +Center +Disabled"), "App")

UiButton(gMainCtrls, gMainGui, "MainClear", UiRect(848, 30, 78, 36, "+0x200 +Center"), "清空键位", MainClear)
UiSetDefaultFont(gMainGui)

MainBuildPresetPanel()
MainBuildActionButtons()
MainBuildFeaturePanel()

ShowGuiMain(*) {
    global gMainGui
    StopAutoFire()
    gMainGui.Title := "DAF连发工具 - DNF AutoFire"
    gMainGui.Show("w940 h510")
    MainLoadAllPreset()
    LoadMainPresetState(ResolvePresetName(LoadLastPreset()))
    MainLoatQuickChangeHotKey()
}

HideGuiMain(*) {
    global gMainGui
    gMainGui.Hide()
}

MainGuiEscape(*) {
    SaveCurrentPresetState()
    ExitApp()
}

MainGuiClose(*) {
    SaveCurrentPresetState()
    ExitApp()
}

DisableGuiMain() {
    global gMainGui
    gMainGui.Opt("+Disabled")
}

EnableGuiMain() {
    global gMainGui
    gMainGui.Opt("-Disabled")
    gMainGui.Title := "DAF连发工具 - DNF AutoFire - v" __Version
    gMainGui.Show("w940 h510")
}

MainSetKeyState(key, state) {
    global UiTheme
    ctrl := MainGetCtrl(key)
    if !IsObject(ctrl) {
        return
    }
    color := state ? UiTheme["KeyOnColor"] : UiTheme["KeyOffColor"]
    weight := state ? "Bold" : "Norm"
    size := MainKeyFontSize(key)
    ctrl.SetFont(size " " color " " weight)
}

MainKeyClick(ctrl, *) {
    ChangeKeyAutoFireState(ctrl.Name)
}

MainStart(*) {
    EnterRunningMode()
}

MainClear(*) {
    SetAllKeysDisable()
}

MainPromptPresetName(title, prompt, defaultValue := "") {
    ret := InputBox(prompt, title, "w280 h130", defaultValue)
    if (ret.Result != "OK") {
        return ""
    }
    rawValue := Trim(ret.Value)
    if InStr(rawValue, "|") {
        MsgBox("配置名称不能包含 | 字符",, "Icon!")
        return ""
    }
    presetName := NormalizePresetName(rawValue)
    if (presetName = "") {
        MsgBox("请输入配置名称",, "Icon!")
        return ""
    }
    return presetName
}

MainPromptUniquePresetName(title, prompt, defaultValue := "") {
    presetName := MainPromptPresetName(title, prompt, defaultValue)
    if (presetName = "") {
        return ""
    }
    if (PresetExists(presetName)) {
        MsgBox("配置名称已存在，请换一个名称",, "Icon!")
        return ""
    }
    return presetName
}

MainClonePreset(*) {
    sourceName := ResolvePresetName()
    presetName := MainPromptUniquePresetName("克隆配置", "请输入新配置名称", sourceName "-克隆")
    if (presetName = "") {
        return
    }
    SaveCurrentPresetState()
    ClonePreset(sourceName, presetName)
    MainLoadAllPreset()
    LoadMainPresetState(presetName)
}

MainNewPreset(*) {
    presetName := MainPromptUniquePresetName("新建配置", "请输入新配置名称", "新配置")
    if (presetName = "") {
        return
    }
    SaveCurrentPresetState()
    CreateBlankPreset(presetName)
    MainLoadAllPreset()
    LoadMainPresetState(presetName)
}

MainRenamePreset(*) {
    presetName := MainGetCtrl("Preset").Text
    newPresetName := MainPromptPresetName("重命名配置", "请输入新的配置名称", presetName)
    if (newPresetName = "") {
        return
    }
    if (newPresetName = presetName) {
        return
    }
    if (PresetExists(newPresetName)) {
        MsgBox("配置名称已存在，请换一个名称",, "Icon!")
        return
    }
    SaveCurrentPresetState()
    RenamePreset(presetName, newPresetName)
    if (GetNowSelectPreset() = presetName) {
        SetNowSelectPreset(newPresetName)
        SaveLastPreset(newPresetName)
    }
    MainLoadAllPreset()
    LoadMainPresetState(newPresetName)
}

MainDeletePreset(*) {
    presetName := ResolvePresetName()
    if (presetName = "") {
        MsgBox("请选择有效的配置",, "Icon!")
        return
    }
    if (LoadAllPreset().Length <= 1) {
        MsgBox("至少保留一个配置",, "Icon!")
        return
    }
    ret := MsgBox("确定删除配置：" presetName "？", "删除配置", "YesNo Icon!")
    if (ret != "Yes") {
        return
    }
    DeletePreset(presetName)
    MainLoadAllPreset()
    LoadMainPresetState(ResolvePresetName())
}

MainSetListBox(ctrl, listPipe) {
    ctrl.Delete()
    for item in StrSplit(listPipe, "|") {
        if (item != "") {
            ctrl.Add([item])
        }
    }
}

; 与 pipe 字符串一致计数；部分环境下 ListBox.GetCount() 不可靠，勿单独依赖
MainPresetCountFromPipe(pipe) {
    n := 0
    for x in StrSplit(pipe, "|") {
        if (x != "") {
            n++
        }
    }
    return n
}

MainPresetListSafeChoose(ctrl, index, presetListPipe) {
    n := MainPresetCountFromPipe(presetListPipe)
    if (n < 1 || index < 1 || index > n) {
        return false
    }
    try {
        ctrl.Choose(index)
        return true
    } catch {
        return false
    }
}

MainLoadAllPreset() {
    global _IsPresetUiSyncing
    presetCtrl := MainGetCtrl("Preset")
    presetList := LoadAllPresetString()
    nowSelectPreset := ResolvePresetName()
    _IsPresetUiSyncing := true
    MainSetListBox(presetCtrl, presetList)

    idx := 0
    for i, txt in StrSplit(presetList, "|") {
        if (txt = nowSelectPreset) {
            idx := i
            break
        }
    }

    if (idx > 0) {
        MainPresetListSafeChoose(presetCtrl, idx, presetList)
    } else if MainPresetListSafeChoose(presetCtrl, 1, presetList) {
        nowSelectPreset := presetCtrl.Text
    }
    _IsPresetUiSyncing := false
    MainSetCurrentPresetLabel(nowSelectPreset)
}

MainSetting(*) {
    ShowGuiSetting()
}

MainCheckUpdate(*) {
    postUrl := "https://bbs.colg.cn/thread-8894989-1-1.html"
    try Run(postUrl)
    catch {
        MsgBox("打开原帖地址失败，请手动访问：`n" postUrl,, "Icon!")
    }
}

MainLoadEx() {
    MainGetCtrl("LvRen").Value := LoadPreset(GetNowSelectPreset(), "LvRenState", false)
    MainGetCtrl("GuanYu").Value := LoadPreset(GetNowSelectPreset(), "GuanYuState", false)
    MainGetCtrl("PetSkill").Value := LoadPreset(GetNowSelectPreset(), "PetSkillState", false)
    MainGetCtrl("ZhanFa").Value := LoadPreset(GetNowSelectPreset(), "ZhanFaState", false)
    MainGetCtrl("JianZong").Value := LoadPreset(GetNowSelectPreset(), "JianZongState", false)
    MainGetCtrl("AutoRun").Value := LoadPreset(GetNowSelectPreset(), "AutoRunState", false)
}

MainSetCurrentPresetLabel(presetName) {
    MainGetCtrl("CurrentPresetLabel").Text := presetName
}

MainRefreshPresetUi() {
    MainLoadAllPreset()
}

MainLvRen(*) {
    ShowGuiLvRen()
}

MainGuanYu(*) {
    ShowGuiGuanYu()
}

MainPetSkill(*) {
    ShowGuiPetSkill()
}

MainZhanFa(*) {
    ShowGuiZhanFa()
}

MainJianZong(*) {
    ShowGuiJianZong()
}

MainAutoRun(*) {
    ShowGuiAutoRun()
}

MainChangePresetByList(*) {
    global _IsPresetUiSyncing
    if (_IsPresetUiSyncing) {
        return
    }
    presetName := MainGetCtrl("Preset").Text
    if (presetName = "") {
        return
    }
    ChangePreset(presetName)
}

MainSaveQuickChangeHotKey(*) {
    global __QuickSwitchHotkey
    quickChangeHotKey := MainGetCtrl("QuickChangeHotKey").Value
    quickChangeHotKeyConfig := LoadConfig("QuickChangeHotKey")
    if (quickChangeHotKeyConfig = "") {
        quickChangeHotKeyConfig := "!``"
    }
    try Hotkey("~$" quickChangeHotKeyConfig, "Off")
    SaveConfig("QuickChangeHotKey", quickChangeHotKey)
    __QuickSwitchHotkey := "~$" quickChangeHotKey
    Hotkey(__QuickSwitchHotkey, ShowGuiQuickSwitch, "On")
}

MainLoatQuickChangeHotKey() {
    global __QuickSwitchHotkey
    quickChangeHotKey := LoadConfig("QuickChangeHotKey")
    if (quickChangeHotKey = "") {
        quickChangeHotKey := "!``"
    }
    __QuickSwitchHotkey := "~$" quickChangeHotKey
    Hotkey(__QuickSwitchHotkey, ShowGuiQuickSwitch, "On")
    MainGetCtrl("QuickChangeHotKey").Value := quickChangeHotKey
}
