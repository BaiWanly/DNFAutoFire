full_command_line := DllCall("GetCommandLine", "Str")

; 需要管理员时先尝试 UAC 提升；若用户取消或失败，则提示并以普通权限继续（避免进程静默退出）
if !RunWithAdministrator_IsChildProcess() && !(A_IsAdmin || RegExMatch(full_command_line, " /restart(?!\S)")) {
    restartArgs := RunWithAdministrator_BuildRestartArgs()
    try {
        if A_IsCompiled {
            Run('*RunAs "' A_ScriptFullPath '" /restart' restartArgs)
        } else {
            Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"' restartArgs)
        }
    } catch Error as err {
        MsgBox(
            "未能自动获取管理员权限（例如已取消 UAC 提示）。`n"
            "将尝试以当前用户权限运行；若连发无效，请右键脚本选择「以管理员身份运行」。`n`n"
            "详情: " err.Message,
            "DAF连发工具",
            "Icon!"
        )
    } else {
        ExitApp()
    }
}

RunWithAdministrator_BuildRestartArgs() {
    if (A_Args.Length = 0) {
        return ""
    }
    out := ""
    for arg in A_Args {
        escaped := StrReplace(arg "", '"', '\"')
        out .= ' "' escaped '"'
    }
    return out
}

RunWithAdministrator_IsChildProcess() {
    return A_Args.Length >= 1 && InStr(A_Args[1], "/Run=") = 1
}
