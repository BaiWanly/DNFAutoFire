#Requires AutoHotkey v2.0

class PresetRecognition {
    static RetryIntervalMs := 500
    static MaxRetryAttempts := 240
    static SkillImageVariation := 80
    static CalibrateImageVariation := 80
    static TownImageVariation := 20
    static _retryTimer := false
    static _startDelayTimer := false
    static _mainStartTimer := false
    static _registeredEsc := false
    static _registeredCustom := false
    static _lastCustomHotkey := ""
}

PresetRecognitionAssetDir() => A_ScriptDir "\assets\preset-recognition"

PresetSkillIconDir() => PresetRecognitionAssetDir() "\skills"

PresetSkillIcon_SafeName(presetName) {
    return RegExReplace(StrReplace(presetName, "|", "_"), '[\\/:\*\?"<>\|]', "_")
}

PresetSkillIconPath(presetName) {
    return PresetSkillIconDir() "\" PresetSkillIcon_SafeName(presetName) ".png"
}

PresetSkillIcon_EnsureDir() {
    dir := PresetSkillIconDir()
    if !DirExist(dir) {
        DirCreate(dir)
    }
}

PresetSkillIcon_CopyForPreset(oldName, newName) {
    src := PresetSkillIconPath(oldName)
    if !FileExist(src) {
        return
    }
    PresetSkillIcon_EnsureDir()
    dest := PresetSkillIconPath(newName)
    try FileCopy(src, dest, true)
}

PresetSkillIcon_DeleteForPreset(presetName) {
    path := PresetSkillIconPath(presetName)
    if FileExist(path) {
        try FileDelete(path)
    }
}

; ---------- 校准区域与参考图 ----------

PresetCalibrateIconDir() => PresetRecognitionAssetDir() "\calibrate"

PresetCalibrateIconGlobalPath() {
    return PresetCalibrateIconDir() "\calibrate.png"
}

PresetTownIconDir() => PresetRecognitionAssetDir() "\town"

PresetTownIconGlobalPath() {
    return PresetTownIconDir() "\town.png"
}

PresetRecognition_DefaultRegion() {
    w := 200
    h := 90
    return Map("x", (A_ScreenWidth - w) // 2, "y", (A_ScreenHeight - h) // 2, "w", w, "h", h)
}

PresetRecognition_ResolveRegion(region) {
    return region.Has("w") ? region : PresetRecognition_DefaultRegion()
}

ParseAutoPresetCalibrateRegion() {
    raw := Trim(LoadConfig("AutoPresetCalibrateRegion", ""))
    out := Map()
    if (raw = "") {
        return out
    }
    parts := StrSplit(raw, "|")
    if (parts.Length < 4) {
        return out
    }
    try {
        x := Integer(parts[1])
        y := Integer(parts[2])
        w := Integer(parts[3])
        h := Integer(parts[4])
    } catch {
        return out
    }
    if (w < 1 || h < 1) {
        return out
    }
    out["x"] := x
    out["y"] := y
    out["w"] := w
    out["h"] := h
    return out
}

SaveAutoPresetCalibrateRegion(x, y, w, h) {
    SaveConfig("AutoPresetCalibrateRegion", x "|" y "|" w "|" h)
}

ParseAutoPresetTownRegion() {
    raw := Trim(LoadConfig("AutoPresetTownRegion", ""))
    out := Map()
    if (raw = "") {
        return out
    }
    parts := StrSplit(raw, "|")
    if (parts.Length < 4) {
        return out
    }
    try {
        x := Integer(parts[1])
        y := Integer(parts[2])
        w := Integer(parts[3])
        h := Integer(parts[4])
    } catch {
        return out
    }
    if (w < 1 || h < 1) {
        return out
    }
    out["x"] := x
    out["y"] := y
    out["w"] := w
    out["h"] := h
    return out
}

SaveAutoPresetTownRegion(x, y, w, h) {
    SaveConfig("AutoPresetTownRegion", x "|" y "|" w "|" h)
}

PresetRecognition_HasAnyCalibratePng() {
    return FileExist(PresetCalibrateIconGlobalPath())
}

PresetRecognition_UseCalibratePass() {
    return ParseAutoPresetCalibrateRegion().Has("w") && PresetRecognition_HasAnyCalibratePng()
}

PresetRecognition_HasAnyTownPng() {
    return FileExist(PresetTownIconGlobalPath())
}

PresetRecognition_UseTownPass() {
    return ParseAutoPresetTownRegion().Has("w") && PresetRecognition_HasAnyTownPng()
}

PresetRecognition_FirstPresetName() {
    presetList := LoadAllPreset()
    return presetList.Length >= 1 ? presetList[1] : ""
}

PresetRecognition_GameActive() {
    return GameContext.IsActiveNow()
}

; 返回 Map: x, y, w, h；无效时返回空 Map。
ParseAutoPresetRegion() {
    raw := Trim(LoadConfig("AutoPresetRegion", ""))
    out := Map()
    if (raw = "") {
        return out
    }
    parts := StrSplit(raw, "|")
    if (parts.Length < 4) {
        return out
    }
    try {
        x := Integer(parts[1])
        y := Integer(parts[2])
        w := Integer(parts[3])
        h := Integer(parts[4])
    } catch {
        return out
    }
    if (w < 1 || h < 1) {
        return out
    }
    out["x"] := x
    out["y"] := y
    out["w"] := w
    out["h"] := h
    return out
}

SaveAutoPresetRegion(x, y, w, h) {
    SaveConfig("AutoPresetRegion", x "|" y "|" w "|" h)
}

; 截图指定区域并保存为 PNG。
PresetCaptureRegionToPng(path, x, y, w, h) {
    parentDir := RegExReplace(path, "\\[^\\]+$", "")
    if (parentDir != "" && parentDir != path && !DirExist(parentDir)) {
        DirCreate(parentDir)
    }
    hdc := DllCall("user32\GetDC", "ptr", 0, "ptr")
    if !hdc {
        throw Error("GetDC failed")
    }
    try {
        hdcMem := DllCall("gdi32\CreateCompatibleDC", "ptr", hdc, "ptr")
        hbm := DllCall("gdi32\CreateCompatibleBitmap", "ptr", hdc, "int", w, "int", h, "ptr")
        if !hbm || !hdcMem {
            throw Error("CreateCompatibleBitmap/DC failed")
        }
        try {
            obm := DllCall("gdi32\SelectObject", "ptr", hdcMem, "ptr", hbm, "ptr")
            if !DllCall("gdi32\BitBlt", "ptr", hdcMem, "int", 0, "int", 0, "int", w, "int", h,
                "ptr", hdc, "int", x, "int", y, "uint", 0x00CC0020) {
                throw Error("BitBlt failed")
            }
            DllCall("gdi32\SelectObject", "ptr", hdcMem, "ptr", obm, "ptr")
            _PresetGdipSaveHbitmapPng(hbm, path)
        } finally {
            DllCall("gdi32\DeleteObject", "ptr", hbm)
            DllCall("gdi32\DeleteDC", "ptr", hdcMem)
        }
    } finally {
        DllCall("user32\ReleaseDC", "ptr", 0, "ptr", hdc)
    }
}

_PresetGdipStartup() {
    return GdiPlusSession.EnsureStarted()
}

_PresetGdipSaveHbitmapPng(hbm, path) {
    _PresetGdipStartup()
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "int", 0, "ptr*", &pBitmap := 0) != 0 || !pBitmap {
        throw Error("GdipCreateBitmapFromHBITMAP failed")
    }
    try {
        clsid := Buffer(16, 0)
        if DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid) != 0 {
            throw Error("CLSIDFromString failed")
        }
        wpath := Buffer(2 * StrLen(path) + 2, 0)
        StrPut(path, wpath, "UTF-16")
        if DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "ptr", wpath.Ptr, "ptr", clsid, "ptr", 0) != 0 {
            throw Error("GdipSaveImageToFile failed")
        }
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    }
}

_PresetGdipSaveGpBitmapToPng(pBitmap, path) {
    _PresetGdipStartup()
    clsid := Buffer(16, 0)
    if DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid) != 0 {
        throw Error("CLSIDFromString failed")
    }
    wpath := Buffer(2 * StrLen(path) + 2, 0)
    StrPut(path, wpath, "UTF-16")
    if DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "ptr", wpath.Ptr, "ptr", clsid, "ptr", 0) != 0 {
        throw Error("GdipSaveImageToFile failed")
    }
}

; 生成适合预览框显示的技能图标 PNG。
PresetSkillIcon_FitPreviewTempPath() {
    return A_Temp "\DAF_skill_fit_preview.png"
}

PresetSkillIcon_RenderFitPreviewToFile(srcPath, boxW, boxH, destPath) {
    if !FileExist(srcPath) || boxW < 1 || boxH < 1 {
        return false
    }
    _PresetGdipStartup()
    pSrc := 0
    if DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", srcPath, "ptr*", &pSrc := 0) != 0 || !pSrc {
        return false
    }
    sw := 0
    sh := 0
    DllCall("gdiplus\GdipGetImageWidth", "ptr", pSrc, "uint*", &sw := 0)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pSrc, "uint*", &sh := 0)
    if (sw < 1 || sh < 1) {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        return false
    }
    ; 必须使用 0x26200A（32bpp ARGB）。
    fmtArgb := 0x26200A
    stride := boxW * 4
    buf := Buffer(stride * boxH, 0)
    pDst := 0
    if DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", boxW, "int", boxH, "int", stride, "uint", fmtArgb, "ptr", buf.Ptr, "ptr*", &pDst := 0) != 0 || !pDst {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        return false
    }
    gr := 0
    if DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pDst, "ptr*", &gr := 0) != 0 || !gr {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pDst)
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        return false
    }
    drawOk := false
    try {
        stClear := DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", 0xFFFFFFFF)
        stMode := DllCall("gdiplus\GdipSetInterpolationMode", "ptr", gr, "int", 7)
        if (stClear = 0 && stMode = 0) {
            scale := Min(boxW / sw, boxH / sh)
            newW := Max(1, Round(sw * scale))
            newH := Max(1, Round(sh * scale))
            dstX := (boxW - newW) // 2
            dstY := (boxH - newH) // 2
            drawOk := (DllCall("gdiplus\GdipDrawImageRectI", "ptr", gr, "ptr", pSrc, "int", dstX, "int", dstY, "int", newW, "int", newH) = 0)
        }
    } finally {
        DllCall("gdiplus\GdipDeleteGraphics", "ptr", gr)
    }
    if !drawOk {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pDst)
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
        return false
    }
    try {
        _PresetGdipSaveGpBitmapToPng(pDst, destPath)
    } finally {
        DllCall("gdiplus\GdipDisposeImage", "ptr", pDst)
        DllCall("gdiplus\GdipDisposeImage", "ptr", pSrc)
    }
    return true
}

; 更新全局校准参考图。
PresetCalibrateIcon_UpdateCurrent() {
    r := PresetRecognition_ResolveRegion(ParseAutoPresetCalibrateRegion())
    path := PresetCalibrateIconGlobalPath()
    PresetCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

PresetTownIcon_UpdateCurrent() {
    r := PresetRecognition_ResolveRegion(ParseAutoPresetTownRegion())
    path := PresetTownIconGlobalPath()
    PresetCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

; 在校准区域内匹配全局参考图，成功后才继续识别技能图标。
CalibrateIconMatches() {
    r := PresetRecognition_ResolveRegion(ParseAutoPresetCalibrateRegion())
    path := PresetCalibrateIconGlobalPath()
    if !FileExist(path) {
        return false
    }
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    variation := PresetRecognition.CalibrateImageVariation
    optPrefix := "*" variation " "
    needle := optPrefix . path
    prevPixel := CoordMode("Pixel", "Screen")
    try {
        try {
            if ImageSearch(&_icx, &_icy, x1, y1, x2, y2, needle) {
                return true
            }
        } catch TargetError {
        }
        return false
    } finally {
        CoordMode "Pixel", prevPixel
    }
}

TownIconMatches() {
    r := PresetRecognition_ResolveRegion(ParseAutoPresetTownRegion())
    path := PresetTownIconGlobalPath()
    if !FileExist(path) {
        return false
    }
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    variation := PresetRecognition.TownImageVariation
    optPrefix := "*" variation " "
    needle := optPrefix . path
    prevPixel := CoordMode("Pixel", "Screen")
    try {
        try {
            if ImageSearch(&_icx, &_icy, x1, y1, x2, y2, needle) {
                return true
            }
        } catch TargetError {
        }
        return false
    } finally {
        CoordMode "Pixel", prevPixel
    }
}

; 更新当前预设的技能图标参考图。
PresetSkillIcon_UpdateCurrent() {
    return PresetSkillIcon_UpdateForPreset(GetNowSelectPreset())
}

PresetSkillIcon_UpdateForPreset(presetName) {
    r := PresetRecognition_ResolveRegion(ParseAutoPresetRegion())
    name := Trim(presetName)
    if (name = "") {
        throw Error("当前没有选中的配置。")
    }
    path := PresetSkillIconPath(name)
    PresetCaptureRegionToPng(path, r["x"], r["y"], r["w"], r["h"])
    return path
}

FindPresetBySkillIcon() {
    r := PresetRecognition_ResolveRegion(ParseAutoPresetRegion())
    x1 := r["x"]
    y1 := r["y"]
    x2 := x1 + r["w"] - 1
    y2 := y1 + r["h"] - 1
    variation := PresetRecognition.SkillImageVariation
    ; 选项与路径必须放在同一字符串里，且使用屏幕坐标搜索。
    optPrefix := "*" variation " "
    prevPixel := CoordMode("Pixel", "Screen")
    try {
        for presetName in LoadAllPreset() {
            path := PresetSkillIconPath(presetName)
            if !FileExist(path) {
                continue
            }
            needle := optPrefix . path
            try {
                if ImageSearch(&_isx, &_isy, x1, y1, x2, y2, needle) {
                    return presetName
                }
            } catch TargetError {
                ; 当前配置未匹配，继续尝试下一个。
            }
        }
        return ""
    } finally {
        CoordMode "Pixel", prevPixel
    }
}

; ---------- 热键触发与重试流程 ----------

PresetRecognition_ClearRetryTimer() {
    if PresetRecognition._retryTimer {
        try SetTimer(PresetRecognition._retryTimer, 0)
        PresetRecognition._retryTimer := false
    }
}

PresetRecognition_ClearStartDelayTimer() {
    if PresetRecognition._startDelayTimer {
        try SetTimer(PresetRecognition._startDelayTimer, 0)
        PresetRecognition._startDelayTimer := false
    }
}

PresetRecognition_ClearMainStartTimer() {
    if PresetRecognition._mainStartTimer {
        try SetTimer(PresetRecognition._mainStartTimer, 0)
        PresetRecognition._mainStartTimer := false
    }
}

PresetRecognition_CancelPending() {
    PresetRecognition_ClearRetryTimer()
    PresetRecognition_ClearStartDelayTimer()
    PresetRecognition_ClearMainStartTimer()
}

PresetRecognition_Trigger(*) {
    PresetRecognition_StartSequence()
}

; 热键触发后等待 1 秒再搜图，避免和游戏界面切换同帧。
PresetRecognition_StartSequence() {
    if !PresetRecognition_IsEnabled() {
        return
    }
    if !AutoFireController.IsRunning() {
        return
    }
    if !PresetRecognition_GameActive() {
        return
    }
    PresetRecognition_CancelPending()
    fn := PresetRecognition_AfterStartDelay
    PresetRecognition._startDelayTimer := fn
    SetTimer(fn, -1000)
}

; 主界面点击“启动连发”时使用：
; 不要求触发瞬间 DNF 已经在前台，而是等用户切回游戏后再执行一次自动识别。
PresetRecognition_StartSequenceFromMainStart() {
    if !PresetRecognition_IsEnabled() {
        return
    }
    if !AutoFireController.IsRunning() {
        return
    }
    PresetRecognition_CancelPending()
    fn := PresetRecognition_AfterMainStartDelay.Bind(1)
    PresetRecognition._mainStartTimer := fn
    SetTimer(fn, -500)
}

PresetRecognition_AfterMainStartDelay(attemptIdx, *) {
    PresetRecognition._mainStartTimer := false
    if !PresetRecognition_IsEnabled() {
        return
    }
    if !AutoFireController.IsRunning() {
        return
    }
    if PresetRecognition_GameActive() {
        PresetRecognition_RunAttempt(1)
        return
    }
    if (attemptIdx >= PresetRecognition.MaxRetryAttempts) {
        return
    }
    fn := PresetRecognition_AfterMainStartDelay.Bind(attemptIdx + 1)
    PresetRecognition._mainStartTimer := fn
    SetTimer(fn, -PresetRecognition.RetryIntervalMs)
}

PresetRecognition_AfterStartDelay(*) {
    PresetRecognition._startDelayTimer := false
    if !PresetRecognition_IsEnabled() {
        return
    }
    if !AutoFireController.IsRunning() {
        return
    }
    if !PresetRecognition_GameActive() {
        return
    }
    PresetRecognition_RunAttempt(1)
}

PresetRecognition_IsEnabled() {
    return Trim(LoadConfig("SettingAutoPresetSwitch", "0")) = "1"
}

; 单一识别流程：没有设置区域时使用默认框；先匹配血条，再匹配城镇，缺少识别图时也按失败处理。
PresetRecognition_RunAttempt(attemptIdx) {
    if !PresetRecognition_IsEnabled() {
        PresetRecognition_ClearRetryTimer()
        return
    }
    if !AutoFireController.IsRunning() {
        PresetRecognition_ClearRetryTimer()
        return
    }
    if !PresetRecognition_GameActive() {
        PresetRecognition_ClearRetryTimer()
        return
    }
    if !PresetRecognition_HasAnyCalibratePng() || !CalibrateIconMatches() {
        if (attemptIdx >= PresetRecognition.MaxRetryAttempts) {
            PresetRecognition_ClearRetryTimer()
            return
        }
        fn := PresetRecognition_RunAttempt.Bind(attemptIdx + 1)
        PresetRecognition._retryTimer := fn
        SetTimer(fn, -PresetRecognition.RetryIntervalMs)
        return
    }

    if !PresetRecognition_HasAnyTownPng() || !TownIconMatches() {
        PresetRecognition_ClearRetryTimer()
        return
    }

    found := FindPresetBySkillIcon()
    current := GetNowSelectPreset()
    PresetRecognition_ClearRetryTimer()
    if (found != "" && found != current) {
        AutoFireController.ChangePreset(found, true)
        AppTip("已切换到配置: " found)
        return
    }
    if (found != "" && found = current) {
        return
    }
    firstN := PresetRecognition_FirstPresetName()
    if (firstN != "" && firstN != current) {
        AutoFireController.ChangePreset(firstN, true)
        AppTip("已切换到配置: " firstN)
    }
}

PresetRecognition_IsEscHotkeyStr(hk) {
    t := StrLower(Trim(hk))
    return (t = "esc" || t = "escape")
}

PresetRecognition_DisableAllHotkeys() {
    PresetRecognition_CancelPending()
    if PresetRecognition._registeredEsc {
        try Hotkey("~Esc", "Off")
        PresetRecognition._registeredEsc := false
    }
    if PresetRecognition._registeredCustom && PresetRecognition._lastCustomHotkey != "" {
        try Hotkey("~$" PresetRecognition._lastCustomHotkey, "Off")
        PresetRecognition._registeredCustom := false
        PresetRecognition._lastCustomHotkey := ""
    }
}

PresetRecognition_UpdateHotkeys() {
    PresetRecognition_DisableAllHotkeys()
    if !PresetRecognition_IsEnabled() {
        return
    }
    if !AutoFireController.IsRunning() {
        return
    }
    hk := Trim(LoadConfig("AutoPresetHotkey", ""))
    PresetRecognition._registeredEsc := true
    Hotkey("~Esc", PresetRecognition_Trigger, "On")
    if (hk != "" && !PresetRecognition_IsEscHotkeyStr(hk)) {
        PresetRecognition._lastCustomHotkey := hk
        PresetRecognition._registeredCustom := true
        Hotkey("~$" hk, PresetRecognition_Trigger, "On")
    }
}
