#Requires AutoHotkey v2.0

global gPresetSkillGui := Gui("-MinimizeBox -MaximizeBox -Theme +Owner", "自动识别配置")
global gPresetSkillCtrls := Map()
global gPresetSkillPvW := 224
global gPresetSkillPvH := 126

GuiTheme_Apply(gPresetSkillGui)

gPresetSkillGui.OnEvent("Escape", PresetSkillGuiEscape)
gPresetSkillGui.OnEvent("Close", PresetSkillGuiClose)

; Picture 赋值 Value 后常会按位图重算控件尺寸，须在 PresetSkillLockPreviewFrame 里 Move 固定
gPresetSkillCtrls["Preview"] := gPresetSkillGui.Add("Picture", "x8 y8 w224 h126")
; 预览底 y8+h126=134；说明与自动识别设置同为 w224 h44、无 +0x200，便于按宽度换行
gPresetSkillGui.Add("Text", "x8 y138 w224 h44", "框选后按 Enter 确认，Esc 取消。不要截取到技能图标外。")
GuiTheme_FlatBtn(gPresetSkillGui, "x8 y188 w108 h28", "截取图像", PresetSkillDoUpdate, false)
GuiTheme_FlatBtn(gPresetSkillGui, "x124 y188 w108 h28", "清除图像", PresetSkillDoDelete, false)
GuiTheme_FlatBtn(gPresetSkillGui, "x8 y222 w224 h32", "保存", PresetSkillSaveClose, true)

PresetSkillGetCtrl(name) {
    global gPresetSkillCtrls
    return gPresetSkillCtrls.Has(name) ? gPresetSkillCtrls[name] : ""
}

PresetSkillLockPreviewFrame(pic) {
    global gPresetSkillPvW, gPresetSkillPvH
    if IsObject(pic) {
        pic.Move(8, 8, gPresetSkillPvW, gPresetSkillPvH)
    }
}

ShowGuiPresetSkillIcon(*) {
    global gMainGui, gPresetSkillGui
    if IsObject(gMainGui) {
        gPresetSkillGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gPresetSkillGui.Title := "自动识别配置 - " GetNowSelectPreset()
    PresetSkillRefreshPreview()
    DisableGuiMain()
    gPresetSkillGui.Show("w240 h266")
}

HideGuiPresetSkillIcon() {
    global gPresetSkillGui
    PresetRegionPickCancelIfOpen()
    gPresetSkillGui.Hide()
    EnableGuiMain()
}

PresetSkillGuiEscape(*) {
    HideGuiPresetSkillIcon()
}

PresetSkillGuiClose(*) {
    HideGuiPresetSkillIcon()
}

PresetSkillRefreshPreview() {
    global gPresetSkillPvW, gPresetSkillPvH
    pic := PresetSkillGetCtrl("Preview")
    path := PresetSkillIconPath(GetNowSelectPreset())
    pic.Value := ""
    PresetSkillLockPreviewFrame(pic)
    if FileExist(path) {
        tmp := PresetSkillIcon_FitPreviewTempPath()
        if PresetSkillIcon_RenderFitPreviewToFile(path, gPresetSkillPvW, gPresetSkillPvH, tmp) && FileExist(tmp) {
            pic.Value := tmp
            PresetSkillLockPreviewFrame(pic)
        }
    }
}

PresetSkillDoUpdate(*) {
    global gPresetSkillPvW, gPresetSkillPvH
    PresetRegionPickCommitSkillRegionIfOpen()
    try {
        path := PresetSkillIcon_UpdateCurrent()
        pic := PresetSkillGetCtrl("Preview")
        pic.Value := ""
        PresetSkillLockPreviewFrame(pic)
        tmp := PresetSkillIcon_FitPreviewTempPath()
        if PresetSkillIcon_RenderFitPreviewToFile(path, gPresetSkillPvW, gPresetSkillPvH, tmp) && FileExist(tmp) {
            pic.Value := tmp
            PresetSkillLockPreviewFrame(pic)
        }
    } catch Error as e {
        MsgBox(e.Message,, "Icon!")
    }
}

PresetSkillDoDelete(*) {
    name := GetNowSelectPreset()
    if (name = "") {
        return
    }
    if !FileExist(PresetSkillIconPath(name)) {
        return
    }
    PresetSkillIcon_DeleteForPreset(name)
    PresetSkillRefreshPreview()
}

; 更新/删除均已立即写盘；框选未按 Enter 时点「保存」也会提交当前框选
PresetSkillSaveClose(*) {
    PresetRegionPickCommitIfOpen()
    HideGuiPresetSkillIcon()
}

MainPresetSkill(*) {
    ShowGuiPresetSkillIcon()
}
