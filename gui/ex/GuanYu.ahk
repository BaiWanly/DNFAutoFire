#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gGuanYuGui := Gui("+ToolWindow -Theme")
global gGuanYuCtrls := Map()
global __GuanYuSkillKeys := []
global gGuanYuColX := 16
global gGuanYuColW := 136
global gGuanYuColGap := 16
global gGuanYuRightX := gGuanYuColX + gGuanYuColW + gGuanYuColGap
global gGuanYuBtnGap := 8
global gGuanYuBtnW := (gGuanYuColW - gGuanYuBtnGap) // 2
global gGuanYuTriggerLabelW := 60
global gGuanYuTriggerEditX := gGuanYuRightX + gGuanYuTriggerLabelW + 6
global gGuanYuTriggerEditW := gGuanYuColW - gGuanYuTriggerLabelW - 6
global gGuanYuDelayLabelW := 78
global gGuanYuDelayEditX := gGuanYuRightX + gGuanYuDelayLabelW + 6
global gGuanYuDelayEditW := gGuanYuColW - gGuanYuDelayLabelW - 6

GuiTheme_Apply(gGuanYuGui)

gGuanYuGui.OnEvent("Escape", GuanYuGuiEscape)
gGuanYuGui.OnEvent("Close", GuanYuGuiClose)

ExWindowHost.AddInlineHeaderLeft(gGuanYuGui, 16, 16, ExWindowHost.MakeHeaderTitle(ExText.GuanYuTitle()), GuanYuHelp, 116, 18, 6)
gGuanYuGui.Add("Text", "x" gGuanYuColX " y52 w" gGuanYuColW " h18 +0x200", ExText.GuanYuListLabel())
gGuanYuCtrls["GuanYuKeysListBox"] := GuiTheme_AddListBox(gGuanYuGui, "GuanYuKeysListBox", gGuanYuColX, 74, gGuanYuColW, 176)
GuiTheme_FlatBtnCompact(gGuanYuGui, "x" gGuanYuColX " y256 w" gGuanYuBtnW " h24", ExText.AddButton(), GuanYuAddKey)
GuiTheme_FlatBtnCompact(gGuanYuGui, "x" (gGuanYuColX + gGuanYuBtnW + gGuanYuBtnGap) " y256 w" gGuanYuBtnW " h24", ExText.DeleteButton(), GuanYuDeleteKey)
gGuanYuGui.Add("Text", "x" gGuanYuRightX " y78 w" gGuanYuTriggerLabelW " h24 +0x200", ExText.GuanYuShotKeyLabel())
gGuanYuCtrls["GuanYuShotKey"] := gGuanYuGui.Add("Edit", "vGuanYuShotKey x" gGuanYuTriggerEditX " y78 w" gGuanYuTriggerEditW " h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gGuanYuCtrls["GuanYuShotKey"], GetKeycode.AfterCaptureEdit.Bind(gGuanYuCtrls["GuanYuShotKey"]))
gGuanYuGui.Add("Text", "x" gGuanYuRightX " y110 w" gGuanYuDelayLabelW " h24 +0x200", ExText.GuanYuDelayLabel())
gGuanYuCtrls["GuanYuDelay"] := gGuanYuGui.Add("Edit", "vGuanYuDelay x" gGuanYuDelayEditX " y110 w" gGuanYuDelayEditW " h24 +Number -E0x200 Border")
ExWindowHost.AddAutoFooter(gGuanYuGui, 290, ExText.SaveButton(), GuanYuSave)

GuanYuGetCtrl(name) {
    global gGuanYuCtrls
    return gGuanYuCtrls.Has(name) ? gGuanYuCtrls[name] : ""
}

ShowGuiGuanYu(*) {
    ExWindowHost.ShowOwnedFit(gGuanYuGui, ExText.GuanYuTitle())
    GuanYuLoadConfig()
}

HideGuiGuanYu() {
    ExWindowHost.HideOwned(gGuanYuGui)
}

GuanYuGuiEscape(*) {
    HideGuiGuanYu()
}

GuanYuGuiClose(*) {
    HideGuiGuanYu()
}

GuanYuHelp(*) {
    ExWindowHost.ShowHelp(ExText.GuanYuHelp(), ExText.GuanYuHelpTitle(), gGuanYuGui)
}

GuanYuAddKey(*) {
    global __GuanYuSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(ExText.InvalidKey(),, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __GuanYuSkillKeys) {
        MsgBox(ExText.DuplicateKey(),, "Icon!")
    } else {
        __GuanYuSkillKeys.Push(key)
    }
    GuanYuChangeListGui(__GuanYuSkillKeys)
    ctrl := GuanYuGetCtrl("GuanYuKeysListBox")
    displayIdx := 0
    loop __GuanYuSkillKeys.Length {
        if !__GuanYuSkillKeys.Has(A_Index) {
            continue
        }
        item := __GuanYuSkillKeys[A_Index]
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

GuanYuDeleteKey(*) {
    global __GuanYuSkillKeys
    DeleteValueInArray(GuanYuGetCtrl("GuanYuKeysListBox").Text, __GuanYuSkillKeys)
    GuanYuChangeListGui(__GuanYuSkillKeys)
}

GuanYuSave(*) {
    GuanYuSaveConfig()
    HideGuiGuanYu()
}

GuanYuChangeListGui(keys) {
    ctrl := GuanYuGetCtrl("GuanYuKeysListBox")
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

GuanYuSaveConfig() {
    global __GuanYuSkillKeys
    keysString := ""
    loop __GuanYuSkillKeys.Length {
        if !__GuanYuSkillKeys.Has(A_Index) {
            continue
        }
        keysString .= __GuanYuSkillKeys[A_Index] "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    delay := Round((Trim(GuanYuGetCtrl("GuanYuDelay").Text) = "" ? 300 : GuanYuGetCtrl("GuanYuDelay").Text) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 500) {
        delay := 500
    }
    GuanYuGetCtrl("GuanYuDelay").Text := delay
    SavePreset(GetNowSelectPreset(), "GuanYuSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "GuanYuShotKey", GuanYuGetCtrl("GuanYuShotKey").Text)
    SavePreset(GetNowSelectPreset(), "GuanYuDelay", delay)
}

GuanYuLoadConfig() {
    global __GuanYuSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "GuanYuShotKey", "Space")
    cShot := GetKeycode.CanonMainKey(Trim(shotKey))
    delay := Round(LoadPreset(GetNowSelectPreset(), "GuanYuDelay", 300) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 500) {
        delay := 500
    }
    __GuanYuSkillKeys := []
    for sk in GuanYuLoadKeys(GetNowSelectPreset()) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            __GuanYuSkillKeys.Push(c)
        }
    }
    GuanYuChangeListGui(__GuanYuSkillKeys)
    GuanYuGetCtrl("GuanYuShotKey").Text := cShot != "" ? cShot : "Space"
    GuanYuGetCtrl("GuanYuDelay").Text := delay
}
