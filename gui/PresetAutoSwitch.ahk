#Requires AutoHotkey v2.0

global gPresetAutoGui := Gui("-MinimizeBox -MaximizeBox -Theme", "自动识别设置")
global gPresetAutoCtrls := Map()
global gPresetAutoPvW := 224
global gPresetAutoPvH := 126
global gRegionPickGui := false
global gRegionPickKeyHook := false
global gRegionPickNCHook := false
global gRegionPickNCCalcHook := false
global gRegionPickKind := "skill"

GuiTheme_Apply(gPresetAutoGui)

gPresetAutoGui.OnEvent("Escape", PresetAutoGuiEscape)
gPresetAutoGui.OnEvent("Close", PresetAutoGuiClose)

PresetSkillOpenSkillRegionPick(*) {
    PresetRegionPickOpen("skill")
}

; 与自动识别配置界面相同：宽 240、预览 224×126；识别热键在预览图上方
gPresetAutoGui.Add("Text", "x8 y8 w224 h14 +0x200", "识别热键 (冒险团玩法信息)")
gPresetAutoCtrls["AutoPresetHotkey"] := gPresetAutoGui.Add("Edit", "vAutoPresetHotkey x8 y24 w224 h22 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gPresetAutoCtrls["AutoPresetHotkey"], PresetAutoHotkeyAfterCapture)
gPresetAutoCtrls["CalPreview"] := gPresetAutoGui.Add("Picture", "x8 y52 w224 h126", "")
gPresetAutoCtrls["CalHint"] := gPresetAutoGui.Add("Text", "x8 y182 w224 h44", "")
GuiTheme_FlatBtn(gPresetAutoGui, "x8 y230 w224 h28", "设置技能识别区域", PresetSkillOpenSkillRegionPick, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x8 y262 w224 h28", "设置血条识别区域", (*) => PresetRegionPickOpen("calibrate"), false)
GuiTheme_FlatBtn(gPresetAutoGui, "x8 y294 w108 h28", "截取图像", PresetAutoUpdateCalibrateIcon, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x124 y294 w108 h28", "清除图像", PresetAutoDoDeleteCalibrateIcon, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x8 y326 w224 h32", "保存", PresetAutoSaveClose, true)

PresetAutoGetCtrl(name) {
    global gPresetAutoCtrls
    return gPresetAutoCtrls.Has(name) ? gPresetAutoCtrls[name] : ""
}

PresetAutoLockCalPreviewFrame(pic) {
    global gPresetAutoPvW, gPresetAutoPvH
    if IsObject(pic) {
        pic.Move(8, 52, gPresetAutoPvW, gPresetAutoPvH)
    }
}

ShowGuiPresetAutoSwitch(*) {
    global gMainGui, gSettingGui, gPresetAutoGui
    owner := 0
    if IsObject(gSettingGui) && WinExist("ahk_id " gSettingGui.Hwnd) {
        gPresetAutoGui.Opt("+Owner" gSettingGui.Hwnd)
    } else if IsObject(gMainGui) {
        gPresetAutoGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gPresetAutoGui.Title := "自动识别设置"
    PresetAutoGetCtrl("AutoPresetHotkey").Text := Trim(LoadConfig("AutoPresetHotkey", ""))
    PresetAutoRefreshCalibratePreview()
    gPresetAutoGui.Show("w240 h368")
}

HideGuiPresetAutoSwitch() {
    global gPresetAutoGui
    PresetRegionPickCancelIfOpen()
    gPresetAutoGui.Hide()
}

PresetAutoGuiEscape(*) {
    HideGuiPresetAutoSwitch()
}

PresetAutoGuiClose(*) {
    HideGuiPresetAutoSwitch()
}

; 框选窗口打开时点「保存」等同按 Enter：写入当前技能区域或校准区域
PresetAutoSaveClose(*) {
    PresetRegionPickCommitIfOpen()
    HideGuiPresetAutoSwitch()
}

PresetAutoHotkeyAfterCapture(key) {
    hk := Trim(key)
    SaveConfig("AutoPresetHotkey", hk)
    PresetRecognition_UpdateHotkeys()
}

PresetAutoDoDeleteCalibrateIcon(*) {
    path := PresetCalibrateIconGlobalPath()
    if !FileExist(path) {
        return
    }
    try FileDelete(path)
    PresetAutoRefreshCalibratePreview()
}

PresetAutoRefreshCalibratePreview() {
    global gPresetAutoPvW, gPresetAutoPvH
    pic := PresetAutoGetCtrl("CalPreview")
    if !IsObject(pic) {
        return
    }
    hint := PresetAutoGetCtrl("CalHint")
    cpath := PresetCalibrateIconGlobalPath()
    pic.Value := ""
    PresetAutoLockCalPreviewFrame(pic)
    tip := "框选后按 Enter 确认，Esc 取消。圆形血条不要截取到血条外的背景。"
    if IsObject(hint) {
        hint.Text := tip
    }
    if FileExist(cpath) {
        tmp := A_Temp "\DAF_cal_fit_preview.png"
        if PresetSkillIcon_RenderFitPreviewToFile(cpath, gPresetAutoPvW, gPresetAutoPvH, tmp) && FileExist(tmp) {
            pic.Value := tmp
        } else {
            pic.Value := cpath
        }
        PresetAutoLockCalPreviewFrame(pic)
    }
}

PresetAutoRefreshCalibratePreviewIfVisible() {
    global gPresetAutoGui
    if IsObject(gPresetAutoGui) && WinExist("ahk_id " gPresetAutoGui.Hwnd) {
        PresetAutoRefreshCalibratePreview()
    }
}

PresetAutoUpdateCalibrateIcon(*) {
    PresetRegionPickCommitCalibrateRegionIfOpen()
    try {
        PresetCalibrateIcon_UpdateCurrent()
        PresetAutoRefreshCalibratePreview()
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

; ---------- 识别区域框选（无边框：客户区即截取区域，避免比可视框多出一圈）----------
; 拖拽：WM_NCHITTEST 中心为 HTCAPTION；边缘为缩放热点
; 使用 WS_EX_LAYERED + 整窗 alpha：半透明深色叠层，便于透过框对准游戏
; 注意：Gui.Show 的 x,y 是「窗口外框」左上角，WinGetClientPos 是「客户区」屏幕坐标；+Resize 带细边框时
; 二者不一致会导致每次 Enter 后选区漂移、变小。恢复位置必须用 AdjustWindowRectEx + SetWindowPos。

; 读取 hwnd 客户区在屏幕上的矩形（与 BitBlt 截取用的坐标一致）
PresetRegionPickReadClientScreen(hwnd) {
    rc := Buffer(16, 0)
    if !DllCall("user32\GetClientRect", "ptr", hwnd, "ptr", rc) {
        return ""
    }
    cw := NumGet(rc, 8, "int") - NumGet(rc, 0, "int")
    ch := NumGet(rc, 12, "int") - NumGet(rc, 4, "int")
    pt := Buffer(8, 0)
    if !DllCall("user32\ClientToScreen", "ptr", hwnd, "ptr", pt) {
        return ""
    }
    return Map("x", NumGet(pt, 0, "int"), "y", NumGet(pt, 4, "int"), "w", cw, "h", ch)
}

; 直角 + 去掉 Win11 顶部云母/非客户区灰条，边框色与选区叠层一致（属性不支持时静默失败）
PresetRegionPickApplyDwmStyle(hwnd) {
    val := Buffer(4, 0)
    ; DWMWA_SYSTEMBACKDROP_TYPE = 38，DWMSBT_NONE = 1：不套用主窗口云母，避免顶上一道灰
    try {
        NumPut("uint", 1, val, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 38, "ptr", val, "uint", 4, "uint")
    }
    ; DWMWA_WINDOW_CORNER_PREFERENCE = 33，DWMWCP_DONOTROUND = 1
    try {
        NumPut("uint", 1, val, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 33, "ptr", val, "uint", 4, "uint")
    }
    ; DWMWA_NCRENDERING_POLICY = 2，DWMNCRP_DISABLED = 1：不单独画 DWM 非客户区（细灰边）
    try {
        NumPut("uint", 1, val, 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 2, "ptr", val, "uint", 4, "uint")
    }
    ; DWMWA_BORDER_COLOR = 34，与 BackColor 一致（COLORREF：R|(G<<8)|(B<<16)）
    try {
        NumPut("uint", 0x00140a05, val, 0) ; 050a14
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 34, "ptr", val, "uint", 4, "uint")
    }
}

; WM_NCCALCSIZE：把「新外框矩形」同步为「客户区矩形」，去掉 +Resize/ThickFrame 画的那圈灰边（仍靠 WM_NCHITTEST 拉边）
PresetRegionPickNCCalcSize(wParam, lParam, msg, hwnd) {
    global gRegionPickGui
    if !IsObject(gRegionPickGui) || (hwnd != gRegionPickGui.Hwnd) {
        return
    }
    if !wParam || !lParam {
        return
    }
    DllCall("kernel32\RtlCopyMemory", "ptr", lParam + 16, "ptr", lParam + 0, "uptr", 16)
    return 0x100 ; WVR_REDRAW
}

; 将窗口外框放到「客户区恰好落在屏幕矩形 (sx,sy,cw,ch)」的位置（sx,sy 为客户区左上角屏幕坐标）
PresetRegionPickSetOuterFromClientScreen(hwnd, sx, sy, cw, ch) {
    style := DllCall("user32\GetWindowLong", "ptr", hwnd, "int", -16, "uint")
    ex := DllCall("user32\GetWindowLong", "ptr", hwnd, "int", -20, "uint")
    rc := Buffer(16, 0)
    NumPut("int", 0, rc, 0)
    NumPut("int", 0, rc, 4)
    NumPut("int", cw, rc, 8)
    NumPut("int", ch, rc, 12)
    adjusted := false
    try {
        dpi := DllCall("user32\GetDpiForWindow", "ptr", hwnd, "uint")
        if (dpi) {
            adjusted := DllCall("user32\AdjustWindowRectExForDpi", "ptr", rc, "uint", style, "int", 0, "uint", ex, "uint", dpi, "int")
        }
    } catch {
        adjusted := false
    }
    if !adjusted {
        NumPut("int", 0, rc, 0)
        NumPut("int", 0, rc, 4)
        NumPut("int", cw, rc, 8)
        NumPut("int", ch, rc, 12)
        DllCall("user32\AdjustWindowRectEx", "ptr", rc, "uint", style, "int", 0, "uint", ex)
    }
    l := NumGet(rc, 0, "int")
    t := NumGet(rc, 4, "int")
    rr := NumGet(rc, 8, "int")
    b := NumGet(rc, 12, "int")
    ow := rr - l
    oh := b - t
    ox := sx + l
    oy := sy + t
    ; SWP_SHOWWINDOW | SWP_NOZORDER
    DllCall("user32\SetWindowPos", "ptr", hwnd, "ptr", 0, "int", ox, "int", oy, "int", ow, "int", oh, "uint", 0x0044)
}

; 框选仍在且为技能区域时：把当前选区写入全局技能区域并关闭（等同按 Enter），供「截取图像」等调用
PresetRegionPickCommitSkillRegionIfOpen() {
    global gRegionPickGui, gRegionPickKind
    if !IsObject(gRegionPickGui) || !WinExist("ahk_id " gRegionPickGui.Hwnd) {
        return
    }
    if (gRegionPickKind != "skill") {
        return
    }
    PresetRegionPickOk()
}

; 任意类型的框选窗口打开时提交（技能 / 校准），关闭框选窗口
PresetRegionPickCommitIfOpen() {
    global gRegionPickGui
    if !IsObject(gRegionPickGui) || !WinExist("ahk_id " gRegionPickGui.Hwnd) {
        return
    }
    PresetRegionPickOk()
}

; 框选仍为校准时提交（等同 Enter），供「截取图像」与保存前提交共用
PresetRegionPickCommitCalibrateRegionIfOpen() {
    global gRegionPickGui, gRegionPickKind
    if !IsObject(gRegionPickGui) || !WinExist("ahk_id " gRegionPickGui.Hwnd) {
        return
    }
    if (gRegionPickKind != "calibrate") {
        return
    }
    PresetRegionPickOk()
}

; 关闭配置子窗口时若框选未确认，丢弃未确认的选区（等同 Esc）
PresetRegionPickCancelIfOpen() {
    global gRegionPickGui
    if IsObject(gRegionPickGui) && WinExist("ahk_id " gRegionPickGui.Hwnd) {
        PresetRegionPickCancel()
    }
}

PresetRegionPickOpen(kind := "skill") {
    global gRegionPickGui, gRegionPickKeyHook, gRegionPickNCHook, gRegionPickNCCalcHook, gRegionPickKind
    gRegionPickKind := kind
    if IsObject(gRegionPickGui) {
        try gRegionPickGui.Destroy()
        gRegionPickGui := false
    }
    gRegionPickGui := Gui("+AlwaysOnTop +Resize +ToolWindow +MinSize8x8 -Caption -Border -DPIScale +E0x80000", "RegionPick")
    gRegionPickGui.MarginX := 0
    gRegionPickGui.MarginY := 0
    ; 深色叠层（略加深）；灰边靠 WM_NCCALCSIZE 吃掉 ThickFrame 非客户区
    gRegionPickGui.BackColor := "050a14"
    gRegionPickGui.OnEvent("Close", PresetRegionPickCancel)
    gRegionPickGui.Show("Hide w200 h90")
    hwnd := gRegionPickGui.Hwnd
    r := (kind = "calibrate") ? ParseAutoPresetCalibrateRegion() : ParseAutoPresetRegion()
    if r.Has("w") {
        PresetRegionPickSetOuterFromClientScreen(hwnd, r["x"], r["y"], r["w"], r["h"])
    } else {
        cw := 200
        ch := 90
        sx := (A_ScreenWidth - cw) // 2
        sy := (A_ScreenHeight - ch) // 2
        PresetRegionPickSetOuterFromClientScreen(hwnd, sx, sy, cw, ch)
    }
    ; 先 DWM 再分层：避免云母/圆角与半透明叠出顶栏灰线（须在外框落定后再设）
    PresetRegionPickApplyDwmStyle(hwnd)
    WinSetTransparent(125, "ahk_id " hwnd)
    if !gRegionPickKeyHook {
        OnMessage(0x0100, PresetRegionPickKey)
        gRegionPickKeyHook := true
    }
    if !gRegionPickNCHook {
        OnMessage(0x0084, PresetRegionPickNCHitTest)
        gRegionPickNCHook := true
    }
    if !gRegionPickNCCalcHook {
        OnMessage(0x0083, PresetRegionPickNCCalcSize)
        gRegionPickNCCalcHook := true
    }
    ; 触发一次非客户区重算，让 NCCALCSIZE 立刻吃掉灰边
    DllCall("user32\SetWindowPos", "ptr", hwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0
        , "uint", 0x0027) ; SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_FRAMECHANGED
}

PresetRegionPickNCHitTest(wParam, lParam, msg, hwnd) {
    global gRegionPickGui
    if !IsObject(gRegionPickGui) || (hwnd != gRegionPickGui.Hwnd) {
        return
    }
    x := lParam & 0xFFFF
    if (x >= 0x8000) {
        x := x - 0x10000
    }
    y := (lParam >> 16) & 0xFFFF
    if (y >= 0x8000) {
        y := y - 0x10000
    }
    DllCall("user32\GetWindowRect", "ptr", hwnd, "ptr", rc := Buffer(16))
    wl := NumGet(rc, 0, "int")
    wt := NumGet(rc, 4, "int")
    wr := NumGet(rc, 8, "int")
    wb := NumGet(rc, 12, "int")
    b := 12
    onLeft := (x < wl + b)
    onRight := (x >= wr - b)
    onTop := (y < wt + b)
    onBottom := (y >= wb - b)
    if (onTop && onLeft) {
        return 13
    }
    if (onTop && onRight) {
        return 14
    }
    if (onBottom && onLeft) {
        return 16
    }
    if (onBottom && onRight) {
        return 17
    }
    if (onTop) {
        return 12
    }
    if (onBottom) {
        return 15
    }
    if (onLeft) {
        return 10
    }
    if (onRight) {
        return 11
    }
    return 2
}

PresetRegionPickKey(wParam, lParam, msg, hwnd) {
    global gRegionPickGui
    if !IsObject(gRegionPickGui) {
        return
    }
    ; WM_KEYDOWN 的 hwnd 常为获得焦点的子控件，不是 Gui 本身
    rootHwnd := DllCall("user32\GetAncestor", "ptr", hwnd, "uint", 2, "ptr") ; GA_ROOT = 2
    if (rootHwnd != gRegionPickGui.Hwnd) {
        return
    }
    if !WinActive("ahk_id " rootHwnd) {
        return
    }
    vk := wParam & 0xFF
    if (vk = 0x0D) { ; Enter
        PresetRegionPickOk()
    } else if (vk = 0x1B) { ; Esc
        PresetRegionPickCancel()
    }
}

PresetRegionPickOk(*) {
    global gRegionPickGui, gRegionPickKind
    if !IsObject(gRegionPickGui) {
        return
    }
    cr := PresetRegionPickReadClientScreen(gRegionPickGui.Hwnd)
    if (cr = "") {
        return
    }
    x := cr["x"]
    y := cr["y"]
    w := cr["w"]
    h := cr["h"]
    kind := gRegionPickKind
    if (kind = "calibrate") {
        SaveAutoPresetCalibrateRegion(x, y, w, h)
        PresetAutoRefreshCalibratePreviewIfVisible()
    } else {
        SaveAutoPresetRegion(x, y, w, h)
    }
    PresetRegionPickClose()
}

PresetRegionPickCancel(*) {
    PresetRegionPickClose()
}

PresetRegionPickClose() {
    global gRegionPickGui
    if IsObject(gRegionPickGui) {
        try gRegionPickGui.Destroy()
    }
    gRegionPickGui := false
}
