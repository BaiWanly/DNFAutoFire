#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gLvRenGui := 0
global gLvRenCtrls := Map()
global __LvRenSkillKeys := []
global gLvRenColX := 16
global gLvRenColW := 136
global gLvRenColGap := 16
global gLvRenRightX := gLvRenColX + gLvRenColW + gLvRenColGap
global gLvRenBtnGap := 8
global gLvRenBtnW := (gLvRenColW - gLvRenBtnGap) // 2
global gLvRenTriggerLabelW := 60
global gLvRenTriggerEditX := gLvRenRightX + gLvRenTriggerLabelW + 6
global gLvRenTriggerEditW := gLvRenColW - gLvRenTriggerLabelW - 6

GuiRegistry.Define("LvRen", LvRenBuildGui)

LvRenBuildGui() {
    global gLvRenGui, gLvRenCtrls
    gLvRenGui := Gui("+ToolWindow -Theme")
    gLvRenCtrls := Map()
    GuiTheme_Apply(gLvRenGui)
    gLvRenGui.OnEvent("Escape", LvRenGuiEscape)
    gLvRenGui.OnEvent("Close", LvRenGuiClose)
    ExWindowHost.AddInlineHeaderLeft(gLvRenGui, 16, 16, ExWindowHost.MakeHeaderTitle(ExText.LvRenTitle()), LvRenHelp, 116, 18, 6)
    gLvRenGui.Add("Text", "x" gLvRenColX " y52 w" gLvRenColW " h18 +0x200", ExText.LvRenListLabel())
    gLvRenCtrls["LvRenKeysListBox"] := GuiTheme_AddListBox(gLvRenGui, "LvRenKeysListBox", gLvRenColX, 74, gLvRenColW, 176)
    GuiTheme_FlatBtnCompact(gLvRenGui, "x" gLvRenColX " y256 w" gLvRenBtnW " h24", ExText.AddButton(), LvRenAddKey)
    GuiTheme_FlatBtnCompact(gLvRenGui, "x" (gLvRenColX + gLvRenBtnW + gLvRenBtnGap) " y256 w" gLvRenBtnW " h24", ExText.DeleteButton(), LvRenDeleteKey)
    gLvRenGui.Add("Text", "x" gLvRenRightX " y78 w" gLvRenTriggerLabelW " h24 +0x200", ExText.LvRenShotKeyLabel())
    gLvRenCtrls["LvRenShotKey"] := gLvRenGui.Add("Edit", "vLvRenShotKey x" gLvRenTriggerEditX " y78 w" gLvRenTriggerEditW " h24 +ReadOnly -WantCtrlA -E0x200 Border")
    RegisterEditPressKeyCapture(gLvRenCtrls["LvRenShotKey"], GetKeycode.AfterCaptureEdit.Bind(gLvRenCtrls["LvRenShotKey"]))
    ExWindowHost.AddAutoFooter(gLvRenGui, 290, ExText.SaveButton(), LvRenSave)
    return gLvRenGui
}

LvRenGetCtrl(name) {
    global gLvRenCtrls
    GuiRegistry.Ensure("LvRen")
    return gLvRenCtrls.Has(name) ? gLvRenCtrls[name] : ""
}

ShowGuiLvRen(*) {
    global gLvRenGui
    gLvRenGui := GuiRegistry.Ensure("LvRen")
    ExWindowHost.ShowOwnedFit(gLvRenGui, ExText.LvRenTitle())
    LvRenLoadConfig()
}

HideGuiLvRen() {
    if !GuiRegistry.IsBuilt("LvRen") {
        return
    }
    ExWindowHost.HideOwned(gLvRenGui)
}

LvRenGuiEscape(*) {
    HideGuiLvRen()
}

LvRenGuiClose(*) {
    HideGuiLvRen()
}

LvRenHelp(*) {
    ExWindowHost.ShowHelp(ExText.LvRenHelp(), ExText.LvRenHelpTitle(), gLvRenGui)
}

LvRenAddKey(*) {
    global __LvRenSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(ExText.InvalidKey(),, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __LvRenSkillKeys) {
        MsgBox(ExText.DuplicateKey(),, "Icon!")
    } else {
        __LvRenSkillKeys.Push(key)
    }
    LvRenChangeListGui(__LvRenSkillKeys)
    ctrl := LvRenGetCtrl("LvRenKeysListBox")
    displayIdx := 0
    loop __LvRenSkillKeys.Length {
        if !__LvRenSkillKeys.Has(A_Index) {
            continue
        }
        item := __LvRenSkillKeys[A_Index]
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

LvRenDeleteKey(*) {
    global __LvRenSkillKeys
    DeleteValueInArray(LvRenGetCtrl("LvRenKeysListBox").Text, __LvRenSkillKeys)
    LvRenChangeListGui(__LvRenSkillKeys)
}

LvRenSave(*) {
    LvRenSaveConfig()
    HideGuiLvRen()
}

LvRenChangeListGui(keys) {
    ctrl := LvRenGetCtrl("LvRenKeysListBox")
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

LvRenSaveConfig() {
    global __LvRenSkillKeys
    keysString := ""
    loop __LvRenSkillKeys.Length {
        if !__LvRenSkillKeys.Has(A_Index) {
            continue
        }
        keysString .= __LvRenSkillKeys[A_Index] "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    SavePreset(GetNowSelectPreset(), "LvRenSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "LvRenShotKey", LvRenGetCtrl("LvRenShotKey").Text)
}

LvRenLoadConfig() {
    global __LvRenSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "LvRenShotKey", "Space")
    cShot := GetKeycode.CanonMainKey(Trim(shotKey))
    LvRenGetCtrl("LvRenShotKey").Text := cShot != "" ? cShot : "Space"
    __LvRenSkillKeys := []
    for sk in LvRenLoadKeys(GetNowSelectPreset()) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            __LvRenSkillKeys.Push(c)
        }
    }
    LvRenChangeListGui(__LvRenSkillKeys)
}
