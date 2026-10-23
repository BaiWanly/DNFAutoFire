#Requires AutoHotkey v2.0

global gPetSkillGui := Gui("-MinimizeBox -MaximizeBox")
global gPetSkillCtrls := Map()
global gPetSkillLayout := ExLayout.Window()

UiApplyWindow(gPetSkillGui)
gPetSkillGui.OnEvent("Escape", PetSkillGuiEscape)
gPetSkillGui.OnEvent("Close", PetSkillGuiClose)

global gPetSkillKeys := UiSkillKeyEditor(gPetSkillGui, gPetSkillCtrls, "PetSkill", exText["PetSkillListTitle"], exText["PetSkillShotTitle"], exText["PetSkillAdd"], exText["PetSkillDelete"], PetSkillSave, PetSkillHelp, exText["CommonSave"], exText["PetSkillPageTitle"], "", "", gPetSkillLayout, PetSkillSaveToAll, exText["CommonSaveToAll"])

PetSkillGetCtrl(name) {
    global gPetSkillCtrls
    return gPetSkillCtrls.Has(name) ? gPetSkillCtrls[name] : ""
}

ShowGuiPetSkill(*) {
    global gMainGui, gPetSkillGui, gPetSkillLayout
    if IsObject(gMainGui) {
        gPetSkillGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gPetSkillGui.Title := exText["PetSkillTitle"]
    gPetSkillGui.Show("w" gPetSkillLayout.Width() " h" gPetSkillLayout.Height())
    PetSkillLoadConfig()
    DisableGuiMain()
}

HideGuiPetSkill() {
    gPetSkillGui.Hide()
    EnableGuiMain()
}

PetSkillGuiEscape(*) {
    PetSkillSave()
}

PetSkillGuiClose(*) {
    PetSkillSave()
}

PetSkillHelp(*) {
    UiHelpMsgBox(exText["PetSkillHelp"], exText["PetSkillHelpTitle"])
}

PetSkillSave(*) {
    PetSkillSaveConfig(GetNowSelectPreset())
    HideGuiPetSkill()
}

PetSkillSaveToAll(*) {
    for presetName in LoadAllPreset() {
        PetSkillSaveConfig(presetName)
    }
    HideGuiPetSkill()
}

PetSkillSaveConfig(presetName) {
    global gPetSkillKeys
    cfg := PresetConfigSection(presetName)
    cfg.Save(Map(
        "PetSkillSkillKeys", KeyListToString(gPetSkillKeys.items),
        "PetSkillShotKey", UiPressKeyEdit_Value(PetSkillGetCtrl("PetSkillShotKey"))
    ))
}

PetSkillLoadConfig() {
    global gPetSkillKeys
    cfg := PresetConfigSection(GetNowSelectPreset())
    gPetSkillKeys.Load(cfg.Get("PetSkillSkillKeys"))
    PetSkillGetCtrl("PetSkillShotKey").Text := cfg.Get("PetSkillShotKey")
}
