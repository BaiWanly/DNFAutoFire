#Requires AutoHotkey v2.0
;@Ahk2Exe-SetMainIcon assets\icons\icon_main.ico
;@Ahk2Exe-AddResource assets\icons\icon_alert.ico, 160
;@Ahk2Exe-AddResource assets\icons\icon_green.ico, 206
;@Ahk2Exe-AddResource assets\icons\icon_red.ico, 207

;@Ahk2Exe-SetDescription DAF连发工具
;@Ahk2Exe-SetCopyright 某亚瑟
;@Ahk2Exe-SetLanguage 0x0804
;@Ahk2Exe-SetProductName DAF连发工具
#SingleInstance Off
#WinActivateForce
SetWorkingDir(A_ScriptDir)
InstallKeybdHook()
if (A_Args.Length >= 1 && InStr(A_Args[1], "/Run=") = 1) {
    A_IconHidden := true
}
#Include ./Version.ahk
#Include ./core/SingleInstance.ahk
if !(A_Args.Length >= 1 && InStr(A_Args[1], "/Run=") = 1) {
    SingleInstance_TryHandOffAndExit()
}
A_MaxHotkeysPerInterval := 9999

#Include <MultipleThread>
#Include <RunWithAdministrator>
; UAC 判定完成后，把最终驻留进程提升到高优先级。
try ProcessSetPriority("High")
#Include <Keys>
#Include <JSON>
#Include <Time>
#Include ./core/SendIP.ahk
#Include ./core/GetKeycode.ahk
#Include ./core/Config.ahk
EnsureConfigInitialized()
#Include ./core/PresetManager.ahk
#Include ./core/GameContext.ahk
#Include ./core/AutoFire.ahk
#Include ./ex/ExLvRen.ahk
#Include ./ex/ExGuanYu.ahk
#Include ./ex/ExPetSkill.ahk
#Include ./ex/ExZhanFa.ahk
#Include ./ex/ExJianZong.ahk
#Include ./ex/ExAutoRun.ahk
#Include ./ex/ExCombo.ahk

if MultipleThread.ScriptStart() {
    return
}

#Include <GetPressKey>
#Include <GdiPlusSession>
#Include <GuiTheme>
#Include ./gui/GuiText.ahk
#Include ./gui/GuiRegistry.ahk
global __Version := GuiText.AppVersion()
#Include ./core/SessionState.ahk
SessionState.InitFromLastPreset()
#Include ./core/PresetExFeatures.ahk
#Include ./core/FeatureModuleRegistry.ahk
#Include ./core/AutoFireController.ahk
#Include ./core/PresetRecognition.ahk
#Include ./gui/main/Main.ahk
#Include ./gui/dialogs/QuickSwitch.ahk
#Include ./gui/dialogs/Setting.ahk
#Include ./gui/ex/autoPreset/AutoPresetSettings.ahk
#Include ./gui/ExText.ahk
#Include ./gui/ex/LvRen.ahk
#Include ./gui/ex/GuanYu.ahk
#Include ./gui/ex/PetSkill.ahk
#Include ./gui/ex/ZhanFa.ahk
#Include ./gui/ex/JianZong.ahk
#Include ./gui/ex/AutoRun.ahk
#Include ./gui/ex/Combo.ahk
#Include ./gui/ex/autoPreset/PresetAutoSwitch.ahk
#Include ./core/AppBootstrap.ahk

AppBootstrap.EnableHighTimerResolution()

;@Ahk2Exe-IgnoreBegin
#Include <Log>
; 需要调试时再取消下一行注释。
; Log()
;@Ahk2Exe-IgnoreEnd

AppBootstrap.Run()
