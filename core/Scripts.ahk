; 切换按键连发状态
ChangeKeyAutoFireState(key){
    global _AutoFireEnableKeys
    ov := LoadPresetKeyIntervalOverrides(GetNowSelectPreset())
    if(IsKeyAutoFire(key)){
        needDeleteIndex := 0
        try keyCount := _AutoFireEnableKeys.Length
        catch {
            keyCount := 0
        }
        loop keyCount
        {
            if !_AutoFireEnableKeys.Has(A_Index) {
                continue
            }
            if(_AutoFireEnableKeys[A_Index] == key){
                needDeleteIndex := A_Index
            }
        }
        if (needDeleteIndex > 0) {
            _AutoFireEnableKeys.Delete(needDeleteIndex)
        }
        MainSetKeyState(key, false, ov)
        SetOriginalDirect(key)
    } else {
        _AutoFireEnableKeys.Push(key)
        MainSetKeyState(key, true, ov)
        SetOriginalBlocking(key)
    }
}

; 判断按键是否启用了连发
IsKeyAutoFire(key){
    global _AutoFireEnableKeys
    try keyCount := _AutoFireEnableKeys.Length
    catch {
        keyCount := 0
    }
    loop keyCount
    {
        if !_AutoFireEnableKeys.Has(A_Index) {
            continue
        }
        if(_AutoFireEnableKeys[A_Index] == key){
            return true
        }
    }
    return false
}

; 把Gui上的key名转换为真实的键值
GetOriginKeyName(key){
    switch key {
    Case "Sub":
        keyName := "-"
    Case "Add":
        keyName := "="
    Case "Tilde":
        keyName := "``"
    Case "LeftBracket":
        keyName := "["
    Case "RightBracket":
        keyName := "]"
    Case "Backslash":
        keyName := "\"
    Case "Semicolon":
        keyName := ";"
    Case "Caps":
        keyName := "CapsLock"
    Case "QuotationMark":
        keyName := "'"
    Case "Comma":
        keyName := ","
    Case "Period":
        keyName := "."
    Case "Slash":
        keyName := "/"
    Case "Num1":
        keyName := "Numpad1"
    Case "Num2":
        keyName := "Numpad2"
    Case "Num3":
        keyName := "Numpad3"
    Case "Num4":
        keyName := "Numpad4"
    Case "Num5":
        keyName := "Numpad5"
    Case "Num6":
        keyName := "Numpad6"
    Case "Num7":
        keyName := "Numpad7"
    Case "Num8":
        keyName := "Numpad8"
    Case "Num9":
        keyName := "Numpad9"
    Case "Num0":
        keyName := "Numpad0"
    Case "NumPeriod":
        keyName := "NumpadDot"
    Case "NumLk":
        keyName := "NumLock"
    Case "NumEnter":
        keyName := "NumpadEnter"
    Case "NumAdd":
        keyName := "NumpadAdd"
    Case "NumSub":
        keyName := "NumpadSub"
    Case "NumStar":
        keyName := "NumpadMult"
    Case "NumSlash":
        keyName := "NumpadDiv"
    Default:
        keyName := key
    }
    return keyName
}

; 按用户要求：不屏蔽原键。保留函数是为了兼容现有调用点。
SetOriginalBlocking(key){
    return
}

; 不屏蔽原键时，无需恢复操作
SetOriginalDirect(key){
    return
}

; 设置托盘图标状态
SetTrayRunningIcon(state){
    ; v2 兼容：编译后从当前 exe 资源切换托盘图标索引
    try TraySetIcon(A_ScriptFullPath, state ? 3 : 4)
}

; 启动连发功能
StartAutoFire(){
    global _AutoFireEnableKeys
    presetName := GetNowSelectPreset()
    intervalMs := Round(LoadPreset(presetName, "MainAutoFireInterval", 20) + 0)
    if (intervalMs < 1) {
        intervalMs := 1
    } else if (intervalMs > 200) {
        intervalMs := 200
    }
    keyIvOv := LoadPresetKeyIntervalOverrides(presetName)
    AutoFireMainUnregisterHotkeys()
    ZhanFaUnregisterHotkeys()
    LvRenUnregisterHotkeys()
    GuanYuUnregisterHotkeys()
    PetSkillUnregisterHotkeys()
    JianZongUnregisterHotkeys()
    ComboUnregisterHotkeys()
    ExAutoRun.UnregisterHotkeys()
    KeyRouter.ClearAll()
    try enableKeyCount := _AutoFireEnableKeys.Length
    catch {
        enableKeyCount := 0
    }
    loop enableKeyCount {
        if !_AutoFireEnableKeys.Has(A_Index) {
            continue
        }
        afKey := _AutoFireEnableKeys[A_Index]
        SetOriginalBlocking(afKey)
    }
    AutoFireMainRegisterHotkeys(intervalMs, keyIvOv)
    Sleep(10)
    StartEx()
    SetTrayRunningIcon(true)
    SetTimer(AppTip.Bind("连发已启动 - " . GetNowSelectPreset()), -100)
    try PresetRecognition_UpdateHotkeys()
}

StartEx(){
    if MainCheckboxOn("LvRen") {
        LvRenRegisterHotkeys()
    }
    if MainCheckboxOn("GuanYu") {
        GuanYuRegisterHotkeys()
    }
    if MainCheckboxOn("PetSkill") {
        PetSkillRegisterHotkeys()
    }
    if MainCheckboxOn("JianZong") {
        skillKey := LoadPreset(GetNowSelectPreset(), "JianZongSkillKey")
        SetOriginalBlocking(skillKey)
        JianZongRegisterHotkeys()
    }
    if MainCheckboxOn("AutoRun") {
        ExAutoRun.RegisterHotkeys()
    }
    if MainCheckboxOn("Combo") {
        ComboRegisterHotkeys()
    }
    if MainCheckboxOn("ZhanFa") {
        ZhanFaRegisterHotkeys()
    }
}

; 停止连发功能
StopAutoFire(){
    allKeys := GetAllKeys()
    try allKeyCount := allKeys.Length
    catch {
        allKeyCount := 0
    }
    loop allKeyCount {
        if !allKeys.Has(A_Index) {
            continue
        }
        SetOriginalDirect(allKeys[A_Index])
    }
    AutoFireMainUnregisterHotkeys()
    ZhanFaUnregisterHotkeys()
    LvRenUnregisterHotkeys()
    GuanYuUnregisterHotkeys()
    PetSkillUnregisterHotkeys()
    JianZongUnregisterHotkeys()
    ComboUnregisterHotkeys()
    ExAutoRun.UnregisterHotkeys()
    KeyRouter.ClearAll()
    SetTrayRunningIcon(false)
    try PresetRecognition_CancelPending()
    try PresetRecognition_UpdateHotkeys()
}

AutoFireMainHotkeyIdFromOrigin(originKey) {
    try {
        sc := GetKeySC(originKey)
        if (sc != "") {
            return Key2SC(originKey)
        }
    } catch {
    }
    return originKey
}

AutoFireMainOnDown(tickFn, intervalMs, *) {
    SetTimer(tickFn, intervalMs)
}

AutoFireMainOnUp(tickFn, *) {
    SetTimer(tickFn, 0)
}

AutoFireMainUnregisterHotkeys() {
    global _AutoFireMainHotkeyRegs
    if !IsSet(_AutoFireMainHotkeyRegs) {
        return
    }
    if !_AutoFireMainHotkeyRegs.Length {
        return
    }
    for reg in _AutoFireMainHotkeyRegs {
        SetTimer(reg.tickFn, 0)
    }
    _AutoFireMainHotkeyRegs := []
}

AutoFireMainRegisterHotkeys(defaultIntervalMs, keyIvOv := unset) {
    global _AutoFireEnableKeys, _AutoFireMainHotkeyRegs
    AutoFireMainUnregisterHotkeys()
    _AutoFireMainHotkeyRegs := []
    if !IsSet(keyIvOv) || !IsObject(keyIvOv) {
        keyIvOv := Map()
    }
    try enableKeyCount := _AutoFireEnableKeys.Length
    catch {
        enableKeyCount := 0
    }
    if (enableKeyCount = 0) {
        return
    }
    loop enableKeyCount {
        if !_AutoFireEnableKeys.Has(A_Index) {
            continue
        }
        afKey := _AutoFireEnableKeys[A_Index]
        effectiveMs := defaultIntervalMs
        if keyIvOv.Has(afKey) {
            effectiveMs := Round(keyIvOv[afKey] + 0)
            if (effectiveMs < 1) {
                effectiveMs := 1
            } else if (effectiveMs > 200) {
                effectiveMs := 200
            }
        }
        originKey := GetOriginKeyName(afKey)
        pressKey := Key2PressKey(originKey)
        keyCode := Key2NoVkSC(originKey)
        id := AutoFireMainHotkeyIdFromOrigin(originKey)
        tickFn := AutoFireEventTick.Bind(pressKey, keyCode)
        downFn := AutoFireMainOnDown.Bind(tickFn, effectiveMs)
        upFn := AutoFireMainOnUp.Bind(tickFn)
        KeyRouter.SubscribeDown(id, downFn)
        KeyRouter.SubscribeUp(id, upFn)
        _AutoFireMainHotkeyRegs.Push({ tickFn: tickFn })
    }
}

; 按住期间由 Down 注册的定时器调用；HotIf 已限制 DNF，此处再判一次避免切出后仍发键
AutoFireEventTick(pressKey, keyCode) {
    if !WinActive("ahk_group DNF") {
        return
    }
    ; 物理按住 Alt 时不发 Tab，避免 Alt+Tab 连切窗口
    if (pressKey = "Tab" && (GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P"))) {
        return
    }
    static keyBusy := Map()
    if (keyBusy.Has(pressKey) && keyBusy[pressKey]) {
        return
    }
    keyBusy[pressKey] := true
    try {
        SendIP(keyCode)
    } finally {
        keyBusy[pressKey] := false
    }
}

; 设置所有关闭连发
SetAllKeysDisable(){
    global _AutoFireEnableKeys
    allKeys := GetAllKeys()
    try allKeyCount := allKeys.Length
    catch {
        allKeyCount := 0
    }
    loop allKeyCount {
        if !allKeys.Has(A_Index) {
            continue
        }
        MainSetKeyState(allKeys[A_Index], false)
    }
    _AutoFireEnableKeys := []
}

; 设置所有按键开启连发
SetAllKeysAutoFire(keys){
    global _AutoFireEnableKeys
    SetAllKeysDisable()
    if !IsObject(keys) {
        return
    }
    ov := LoadPresetKeyIntervalOverrides(GetNowSelectPreset())
    try keyCount := keys.Length
    catch {
        keyCount := 0
    }
    loop keyCount {
        if !keys.Has(A_Index) {
            continue
        }
        kName := keys[A_Index]
        if !IsValueInArray(kName, GetAllKeys()) {
            continue
        }
        MainSetKeyState(kName, true, ov)
        _AutoFireEnableKeys.Push(kName)
    }
}

; 设置当前选择预设名
SetNowSelectPreset(presetName){
    global _NowSelectPreset
    _NowSelectPreset := presetName
}

; 获取当前选择预设名
GetNowSelectPreset(){
    global _NowSelectPreset
    return _NowSelectPreset
}

; 切换预设
ChangePreset(presetName){
    StopAutoFire()
    presetKeys := LoadPresetKeys(presetName)
    SetAllKeysAutoFire(presetKeys)
    SetNowSelectPreset(presetName)
    SaveLastPreset(presetName)
    MainLoadEx()
}

; 连发是否处于运行中（主连发热键已挂，或自动奔跑等扩展已注册）
AutoFireIsRunning() {
    global _AutoFireMainHotkeyRegs
    try mr := _AutoFireMainHotkeyRegs.Length
    catch {
        mr := 0
    }
    return mr > 0 || ExAutoRun._registered
}

; 切换预设并在此前连发已启动时自动恢复连发（用于识别快捷键等）
ChangePresetAndResumeAutoFire(presetName) {
    presetName := Trim(presetName)
    if (presetName = "") {
        return
    }
    if (presetName = GetNowSelectPreset()) {
        return
    }
    was := AutoFireIsRunning()
    ChangePreset(presetName)
    if was {
        StartAutoFire()
    }
}

; 判断数组中是否存在某值
IsValueInArray(value, array){
    if !IsObject(array) {
        return false
    }
    try itemCount := array.Length
    catch {
        itemCount := 0
    }
    loop itemCount
    {
        if !array.Has(A_Index) {
            continue
        }
        if(array[A_Index] == value){
            return true
        }
    }
    return false
}

; 删除数组中的某值
DeleteValueInArray(value, array){
    if(IsValueInArray(value, array)){
        needDeleteIndex := 0
        try itemCount := array.Length
        catch {
            itemCount := 0
        }
        loop itemCount
        {
            if !array.Has(A_Index) {
                continue
            }
            if(array[A_Index] == value){
                needDeleteIndex := A_Index
            }
        }
        if (needDeleteIndex > 0) {
            array.Delete(needDeleteIndex)
        }
    }
}

; 将 ToolTip 放在 DNF 客户区右下角附近（找不到窗口时退回鼠标旁）
ShowTipPlaceNearDnfBottomRight(text) {
    hwnd := WinExist("ahk_group DNF")
    if !hwnd {
        ToolTip(text)
        return
    }
    try WinGetClientPos(&cx, &cy, &cw, &ch, "ahk_id " hwnd)
    catch {
        ToolTip(text)
        return
    }
    pad := 14
    estW := Min(560, Max(140, Ceil(StrLen(text) * 10)))
    estH := 40
    tipX := cx + cw - estW - pad
    tipY := cy + ch - estH - pad
    if (tipX < cx + 8) {
        tipX := cx + 8
    }
    if (tipY < cy + 8) {
        tipY := cy + 8
    }
    ToolTip(text, tipX, tipY)
}

; 统一短暂提示：优先 DNF 客户区右下角，无窗口或取客户区失败则跟鼠标；固定显示 1s
AppTip(text) {
    ShowTipPlaceNearDnfBottomRight(text)
    SetTimer(CloseTip, -1000)
    try WinActivate("地下城与勇士")
}

CloseTip(){
    ToolTip()
}

SetDNFWindowClass(){
    ; DNF 的窗口“类名”(Class)在不同地区/版本可能不同，但窗口标题与进程名更稳定。
    ; 旧版写法把标题当成 ahk_class，会导致 WinActive("ahk_group DNF") 永远不成立。
    ;
    ; 1) 标题匹配（不加 ahk_class/ahk_exe 前缀时，默认按标题匹配）
    GroupAdd("DNF", "地下城与勇士")
    GroupAdd("DNF", "Dungeon & Fighter")
    GroupAdd("DNF", "Dungeon Fighter Online")
    ; 次元对决（独立客户端）
    GroupAdd("DNF", "次元对决")
    ;
    ; 2) 进程匹配（尽量覆盖常见命名；如果你的进程名不同，后面我再按诊断结果补）
    GroupAdd("DNF", "ahk_exe dnf.exe")
    GroupAdd("DNF", "ahk_exe DNF.exe")
    GroupAdd("DNF", "ahk_exe DungeonFighter.exe")
    GroupAdd("DNF", "ahk_exe DFO.exe")
    GroupAdd("DNF", "ahk_exe DNF_SGM.exe")
}