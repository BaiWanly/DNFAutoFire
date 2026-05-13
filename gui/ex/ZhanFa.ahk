#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gZhanFaGui := Gui("+ToolWindow -Theme")
global gZhanFaCtrls := Map()
global __ZhanFaSkillKeys := []
global gZhanFaColX := 16
global gZhanFaColW := 136
global gZhanFaColGap := 16
global gZhanFaRightX := gZhanFaColX + gZhanFaColW + gZhanFaColGap
global gZhanFaBtnGap := 8
global gZhanFaBtnW := (gZhanFaColW - gZhanFaBtnGap) // 2
global gZhanFaTriggerLabelW := 60
global gZhanFaTriggerEditX := gZhanFaRightX + gZhanFaTriggerLabelW + 6
global gZhanFaTriggerEditW := gZhanFaColW - gZhanFaTriggerLabelW - 6

GuiTheme_Apply(gZhanFaGui)

gZhanFaGui.OnEvent("Escape", ZhanFaGuiEscape)
gZhanFaGui.OnEvent("Close", ZhanFaGuiClose)

ExWindowHost.AddInlineHeaderLeft(gZhanFaGui, 16, 16, ExWindowHost.MakeHeaderTitle(ExText.ZhanFaTitle()), ZhanFaHelp, 116, 18, 6)
gZhanFaGui.Add("Text", "x" gZhanFaColX " y52 w" gZhanFaColW " h18 +0x200", ExText.ZhanFaListLabel())
gZhanFaCtrls["ZhanFaKeysListBox"] := GuiTheme_AddListBox(gZhanFaGui, "ZhanFaKeysListBox", gZhanFaColX, 74, gZhanFaColW, 176)
GuiTheme_FlatBtnCompact(gZhanFaGui, "x" gZhanFaColX " y256 w" gZhanFaBtnW " h24", ExText.AddButton(), ZhanFaAddKey)
GuiTheme_FlatBtnCompact(gZhanFaGui, "x" (gZhanFaColX + gZhanFaBtnW + gZhanFaBtnGap) " y256 w" gZhanFaBtnW " h24", ExText.DeleteButton(), ZhanFaDeleteKey)
gZhanFaGui.Add("Text", "x" gZhanFaRightX " y78 w" gZhanFaTriggerLabelW " h24 +0x200", ExText.ZhanFaShotKeyLabel())
gZhanFaCtrls["ZhanFaShotKey"] := gZhanFaGui.Add("Edit", "vZhanFaShotKey x" gZhanFaTriggerEditX " y78 w" gZhanFaTriggerEditW " h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gZhanFaCtrls["ZhanFaShotKey"], GetKeycode.AfterCaptureEdit.Bind(gZhanFaCtrls["ZhanFaShotKey"]))
ExWindowHost.AddAutoFooter(gZhanFaGui, 290, ExText.SaveButton(), ZhanFaSave)

ZhanFaGetCtrl(name) {
    global gZhanFaCtrls
    return gZhanFaCtrls.Has(name) ? gZhanFaCtrls[name] : ""
}

ShowGuiZhanFa(*) {
    ExWindowHost.ShowOwnedFit(gZhanFaGui, ExText.ZhanFaTitle())
    ZhanFaLoadConfig()
}

HideGuiZhanFa() {
    ExWindowHost.HideOwned(gZhanFaGui)
}

ZhanFaGuiEscape(*) {
    HideGuiZhanFa()
}

ZhanFaGuiClose(*) {
    HideGuiZhanFa()
}

ZhanFaHelp(*) {
    ExWindowHost.ShowHelp(ExText.ZhanFaHelp(), ExText.ZhanFaHelpTitle(), gZhanFaGui)
}

ZhanFaAddKey(*) {
    global __ZhanFaSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(ExText.InvalidKey(),, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __ZhanFaSkillKeys) {
        MsgBox(ExText.DuplicateKey(),, "Icon!")
    } else {
        __ZhanFaSkillKeys.Push(key)
    }
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
    ctrl := ZhanFaGetCtrl("ZhanFaKeysListBox")
    displayIdx := 0
    loop __ZhanFaSkillKeys.Length {
        if !__ZhanFaSkillKeys.Has(A_Index) {
            continue
        }
        item := __ZhanFaSkillKeys[A_Index]
        if (item = "") {
            continue
        }
        displayIdx++
        if (item = key) {
            ctrl.Choose(displayIdx)
            break
        }
    }
}

ZhanFaDeleteKey(*) {
    global __ZhanFaSkillKeys
    DeleteValueInArray(ZhanFaGetCtrl("ZhanFaKeysListBox").Text, __ZhanFaSkillKeys)
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
}

ZhanFaSave(*) {
    ZhanFaSaveConfig()
    HideGuiZhanFa()
}

ZhanFaChangeListGui(keys) {
    ctrl := ZhanFaGetCtrl("ZhanFaKeysListBox")
    ctrl.Delete()
    cnt := 0
    if !IsObject(keys) {
        keys := []
    }
    loop keys.Length {
        if !keys.Has(A_Index) {
            continue
        }
        key := keys[A_Index]
        if (key != "") {
            ctrl.Add([key])
            cnt++
        }
    }
    if (cnt > 0) {
        ctrl.Choose(1)
    }
}

ZhanFaSaveConfig() {
    global __ZhanFaSkillKeys
    keysString := ""
    loop __ZhanFaSkillKeys.Length {
        if !__ZhanFaSkillKeys.Has(A_Index) {
            continue
        }
        keysString .= __ZhanFaSkillKeys[A_Index] "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    SavePreset(GetNowSelectPreset(), "ZhanFaSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "ZhanFaShotKey", ZhanFaGetCtrl("ZhanFaShotKey").Text)
}

ZhanFaLoadConfig() {
    global __ZhanFaSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "ZhanFaShotKey", "Space")
    cShot := GetKeycode.CanonMainKey(Trim(shotKey))
    ZhanFaGetCtrl("ZhanFaShotKey").Text := cShot != "" ? cShot : "Space"
    __ZhanFaSkillKeys := []
    for sk in ZhanFaLoadKeys(GetNowSelectPreset()) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            __ZhanFaSkillKeys.Push(c)
        }
    }
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
}
