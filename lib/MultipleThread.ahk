; 勿命名为 Thread：AHK v2 标准库已有内置 Thread 类，会覆盖 ScriptStart 等调用
class SubProcessThread
{
    __New(RunLabelOrFunc, presetName := "")
    {
        args := ["/Run=" RunLabelOrFunc]
        presetName := NormalizePresetName(presetName)
        if (presetName != "") {
            args.Push("/Preset=" presetName)
        }
        ; v2：命令行为 "解释器" "脚本" "参数"，勿插入 v1 式 /f，否则会把 /f 当成脚本路径
        if (A_IsCompiled) {
            Run('"' A_ScriptFullPath '" ' SubProcessThread._JoinArgs(args), , , &pid)
        } else {
            Run('"' A_AhkPath '" "' A_ScriptFullPath '" ' SubProcessThread._JoinArgs(args), , , &pid)
        }
        this.pid := pid
        this.label := RunLabelOrFunc
        this.stopped := false
    }
    __Delete()
    {
        this.Stop()
    }
    IsAlive()
    {
        try return this.pid && ProcessExist(this.pid)
        return false
    }
    Stop(timeoutSec := 1)
    {
        if (this.stopped) {
            return
        }
        this.stopped := true
        if !this.IsAlive() {
            return
        }
        oldDetectHidden := A_DetectHiddenWindows
        DetectHiddenWindows(true)
        try PostMessage(0x0010, 0, 0,, "ahk_pid " this.pid) ; WM_CLOSE
        DetectHiddenWindows(oldDetectHidden)
        try {
            ProcessWaitClose(this.pid, timeoutSec)
        }
        if this.IsAlive() {
            try ProcessClose(this.pid)
        }
    }
    static _JoinArgs(args)
    {
        out := ""
        for arg in args {
            out .= '"' StrReplace(arg, '"', '\"') '" '
        }
        return RTrim(out)
    }
    static _GetArg(name, defaultValue := "")
    {
        prefix := "/" name "="
        for arg in A_Args {
            if (SubStr(arg, 1, StrLen(prefix)) = prefix) {
                return SubStr(arg, StrLen(prefix) + 1)
            }
        }
        return defaultValue
    }
    static _LogError(label, err)
    {
        if !LoadConfig("SettingSubprocessErrorLog", false) {
            return
        }
        try {
            ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            msg := ts " [" label "] " err.Message
            try msg .= " at " err.File ":" err.Line
            FileAppend(msg "`r`n", A_ScriptDir "\subprocess-error.log", "UTF-8")
        }
    }
    static ScriptStart()
    {
        if (A_Args.Length < 1 || !InStr(A_Args[1], "/Run="))
        {
            return
        }
        ; 子进程仅负责连发逻辑，不显示托盘图标，避免任务栏出现大量 H 图标
        A_IconHidden := true
        Suspend(true)
        k := SubStr(A_Args[1], 6)
        presetName := ResolvePresetName(SubProcessThread._GetArg("Preset", LoadLastPreset()))
        try {
            dispatch := Map(
                "MainAutoFire", MainAutoFire,
                "ExActionRuntime", ExActionRuntime_Run
            )
            if (dispatch.Has(k)) {
                dispatch[k].Call(presetName)
            }
        } catch as err {
            ; 线程启动异常不弹窗影响主流程，但写入最近错误日志便于排查。
            SubProcessThread._LogError(k, err)
        }
        ExitApp()
    }
}
