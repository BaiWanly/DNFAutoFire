#Requires AutoHotkey v2.0

class MultipleThread {
    static _threads := Map()

    __New(runLabelOrFunc, extraArgs := unset) {
        args := ['/Run=' runLabelOrFunc]
        if IsSet(extraArgs) && IsObject(extraArgs) {
            for item in extraArgs {
                args.Push(item "")
            }
        }
        cmd := ""
        for item in args {
            escaped := StrReplace(item, '"', '\"')
            cmd .= ' "' escaped '"'
        }
        if (A_IsCompiled) {
            Run('"' A_ScriptFullPath '"' cmd, , , &pid)
        } else {
            Run('"' A_AhkPath '" "' A_ScriptFullPath '"' cmd, , , &pid)
        }
        this.pid := pid
    }

    Stop() {
        if this.pid {
            try ProcessClose(this.pid)
            this.pid := 0
        }
    }

    __Delete() {
        this.Stop()
    }

    static IsChildProcess() {
        return A_Args.Length >= 1 && InStr(A_Args[1], "/Run=") = 1
    }

    static ScriptStart() {
        if !this.IsChildProcess() {
            return false
        }
        A_IconHidden := true
        Suspend(true)
        this._EnsureDnfWindowGroup()
        timerRaised := false
        try {
            UnlockSystemTimeLimit()
            timerRaised := true
        } catch {
        }
        try {
            runName := SubStr(A_Args[1], 6)
            if RegExMatch(runName, "^\d$") {
                runName := "Key" runName
            }
            this._Dispatch(runName)
        } finally {
            if timerRaised {
                try RestoreSystemTimeLimit()
            }
        }
        ExitApp()
        return true
    }

    static StartMainKeyThread(keyName, intervalMs, pressDurationMs) {
        keyName := GetKeycode.CanonMainKey(keyName)
        if (keyName = "") {
            return false
        }
        intervalMs := PresetManager.NormalizeInterval(intervalMs)
        pressDurationMs := PresetManager.NormalizePressDuration(pressDurationMs)
        thread := MultipleThread("MainKey", [keyName, intervalMs, pressDurationMs])
        this._threads[this._ThreadId("MainKey", keyName)] := thread
        return true
    }

    static StartFeatureThread(featureName) {
        featureName := Trim(featureName "")
        if (featureName = "") {
            return false
        }
        thread := MultipleThread(featureName)
        this._threads[this._ThreadId("Feature", featureName)] := thread
        return true
    }

    static StopAllThreads() {
        oldThreads := this._threads
        this._threads := Map()
        for _, thread in oldThreads {
            try thread.Stop()
        }
    }

    static AnyThreadRunning() {
        for _ in this._threads {
            return true
        }
        return false
    }

    static _ThreadId(kind, name) {
        return kind ":" name
    }

    static _EnsureDnfWindowGroup() {
        try GameContext._AddDnfGroup()
    }

    static _Dispatch(runName) {
        switch runName {
            case "MainKey":
                keyName := this._Arg(2)
                intervalMs := Round(this._Arg(3, 20) + 0)
                pressDurationMs := Round(this._Arg(4, 8) + 0)
                AutoFire_Run(keyName, intervalMs, pressDurationMs)
            case "LvRen", "ExLvRen":
                ExLvRen_Run()
            case "GuanYu", "ExGuanYu":
                ExGuanYu_Run()
            case "PetSkill", "ExPetSkill":
                ExPetSkill_Run()
            case "ZhanFa", "ExZhanFa":
                ExZhanFa_Run()
            case "JianZong", "ExJianZong":
                ExJianZong_Run()
            case "AutoRun", "ExAutoRun":
                ExAutoRun.Run()
            case "Combo", "ExCombo":
                ExCombo_Run()
            default:
                throw Error("Unsupported Ex run target: " runName)
        }
    }

    static _Arg(index, default := "") {
        if (index >= 1 && index <= A_Args.Length) {
            return A_Args[index]
        }
        return default
    }
}
