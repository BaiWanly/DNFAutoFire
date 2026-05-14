#Requires AutoHotkey v2.0

class SettingController {
    static BlockWin(*) {
        return 0
    }

    static ToggleSwitch(name) {
        ctrl := SettingGetCtrl(name)
        if !IsObject(ctrl) {
            return
        }
        ctrl.Value := !ctrl.Value
        this.PaintSwitch(name)
    }

    static PaintSwitch(name) {
        global gSettingSwitchUi
        if !gSettingSwitchUi.Has(name) {
            return
        }
        ctrl := SettingGetCtrl(name)
        ui := gSettingSwitchUi[name]
        if !IsObject(ctrl) || !IsObject(ui) {
            return
        }
        ui.Draw(Integer(ctrl.Value) = 1)
    }

    static PaintAllSwitches() {
        global gSettingSwitchUi
        for name, ui in gSettingSwitchUi {
            this.PaintSwitch(name)
        }
    }

    static ShowPage(page) {
        global __SettingGeneralCtrls, __SettingAboutCtrls
        if (page != 1 && page != 2) {
            page := 1
        }
        for ctrl in __SettingGeneralCtrls {
            ctrl.Visible := (page = 1)
        }
        for ctrl in __SettingAboutCtrls {
            ctrl.Visible := (page = 2)
        }
    }

    static Show(*) {
        this.ShowPageWindow(1)
    }

    static ShowAbout(*) {
        this.ShowPageWindow(2)
    }

    static ShowPageWindow(page) {
        global gMainGui, gSettingGui
        gSettingGui := GuiRegistry.Ensure("Setting")
        try PresetRecognition_CancelPending()
        DisableGuiMain()
        if IsObject(gMainGui) {
            gSettingGui.Opt("+Owner" gMainGui.Hwnd)
        }
        gSettingGui.Title := GuiText.SettingTitle()
        GuiTheme_ShowFit(gSettingGui)
        this.Load()
        this.ShowPage(page)
    }

    static Hide() {
        if !GuiRegistry.IsBuilt("Setting") {
            return
        }
        gSettingGui.Hide()
        EnableGuiMain()
    }

    static Save(*) {
        global _OnSystemStart, _BlockWin
        settingAutoStart := SettingGetCtrl("SettingAutoStart").Value
        settingOnSystemStart := SettingGetCtrl("SettingOnSystemStart").Value
        settingBlockWin := SettingGetCtrl("SettingBlockWin").Value

        SaveConfig("SettingAutoStart", settingAutoStart)
        SaveConfig("SettingOnSystemStart", settingOnSystemStart)
        SaveConfig("SettingBlockWin", settingBlockWin)

        _OnSystemStart := settingOnSystemStart
        _BlockWin := settingBlockWin

        QuickChangeHotKey_PersistAndRegister(SettingGetCtrl("SettingQuickChangeHotKey").Value)
        this.ApplyNow()
        this.Hide()
    }

    static Load() {
        global gSettingSuppressQuickKeyChange
        GuiRegistry.Ensure("Setting")
        SettingGetCtrl("SettingAutoStart").Value := LoadConfig("SettingAutoStart", false)
        SettingGetCtrl("SettingOnSystemStart").Value := LoadConfig("SettingOnSystemStart", false)
        SettingGetCtrl("SettingBlockWin").Value := LoadConfig("SettingBlockWin", false)
        qhk := LoadConfig("QuickChangeHotKey")
        if (qhk = "") {
            qhk := "!``"
        }
        gSettingSuppressQuickKeyChange := true
        SettingGetCtrl("SettingQuickChangeHotKey").Value := qhk
        gSettingSuppressQuickKeyChange := false
        this.PaintAllSwitches()
    }

    static OnQuickChangeHotKeyChanged(*) {
        global gSettingSuppressQuickKeyChange
        if (gSettingSuppressQuickKeyChange) {
            return
        }
        ctrl := SettingGetCtrl("SettingQuickChangeHotKey")
        if !IsObject(ctrl) {
            return
        }
        QuickChangeHotKey_PersistAndRegister(ctrl.Value)
    }

    static ApplyNow() {
        global _OnSystemStart, _BlockWin
        startupLink := A_Startup "\DAF AutoFire.lnk"
        if (_OnSystemStart) {
            FileCreateShortcut(A_ScriptFullPath, startupLink)
        } else {
            try FileDelete(startupLink)
        }
        if (_BlockWin) {
            Hotkey("$*LWin", SettingBlockWin, "On")
            Hotkey("$*RWin", SettingBlockWin, "On")
        } else {
            try Hotkey("$*LWin", "Off")
            try Hotkey("$*RWin", "Off")
        }
        PresetRecognition_UpdateHotkeys()
    }
}
