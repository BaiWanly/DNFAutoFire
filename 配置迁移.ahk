#Requires AutoHotkey v2.0

ConfigPathFromArgs() {
    path := A_ScriptDir "\config.ini"
    for arg in A_Args {
        if (SubStr(arg, 1, 1) != "/") {
            path := arg
            break
        }
    }
    return path
}

IsDryRun() {
    for arg in A_Args {
        if (StrLower(arg) = "/dryrun") {
            return true
        }
    }
    return false
}

ComboProfileRecordSeparator() {
    static rs := Chr(30)
    return rs
}

ComboProfileUnitSeparator() {
    static us := Chr(31)
    return us
}

ComboSkillRecordSeparator() {
    return "|"
}

ComboSkillUnitSeparator() {
    return ":"
}

ComboBlankProfileMarker() {
    return "blank"
}

NormalizeDelay(raw) {
    return Round((Trim(String(raw)) = "" ? 20 : raw) + 0)
}

ConvertLegacySkills(raw) {
    raw := Trim(String(raw))
    if (raw = "") {
        return ""
    }
    if InStr(raw, ComboSkillUnitSeparator()) {
        return raw
    }
    out := ""
    rs := ComboSkillRecordSeparator()
    us := ComboSkillUnitSeparator()
    for unit in StrSplit(raw, "|") {
        unit := Trim(unit)
        if (unit = "") {
            continue
        }
        commaPos := InStr(unit, ",")
        if commaPos {
            key := Trim(SubStr(unit, 1, commaPos - 1))
            delay := NormalizeDelay(SubStr(unit, commaPos + 1))
        } else {
            key := Trim(unit)
            delay := 20
        }
        if (key = "") {
            continue
        }
        if (out != "") {
            out .= rs
        }
        out .= key us delay
    }
    return out
}

MigrateComboProfiles(raw) {
    raw := Trim(String(raw))
    if (raw = "") {
        return raw
    }
    rs := ComboProfileRecordSeparator()
    us := ComboProfileUnitSeparator()
    out := ""
    for rec in StrSplit(raw, rs) {
        rec := Trim(rec)
        if (rec = "") {
            continue
        }
        if (StrLower(rec) = ComboBlankProfileMarker()) {
            newRec := rec
        } else {
            parts := StrSplit(rec, us,, 5)
            if (parts.Length >= 5) {
                newRec := parts[1] us parts[2] us parts[3] us ConvertLegacySkills(parts[5])
            } else if (parts.Length >= 4) {
                newRec := parts[1] us parts[2] us parts[3] us ConvertLegacySkills(parts[4])
            } else if (parts.Length >= 2) {
                newRec := parts[1] us parts[2] us "0" us (parts.Length >= 3 ? ConvertLegacySkills(parts[3]) : "")
            } else {
                newRec := rec
            }
        }
        if (out != "") {
            out .= rs
        }
        out .= newRec
    }
    return out
}

MigrateConfig(path, dryRun) {
    if !FileExist(path) {
        MsgBox("找不到配置文件：" path, "一键连招配置迁移", "Icon!")
        return
    }
    changed := []
    sections := IniRead(path)
    for sec in StrSplit(sections, "`n", "`r") {
        sec := Trim(sec)
        if (SubStr(sec, 1, 3) != "预设:") {
            continue
        }
        raw := IniRead(path, sec, "ComboProfiles", "")
        converted := MigrateComboProfiles(raw)
        if (converted != raw) {
            changed.Push(sec)
            if !dryRun {
                IniWrite(converted, path, sec, "ComboProfiles")
            }
        }
    }
    if (changed.Length = 0) {
        MsgBox("没有需要迁移的一键连招配置。", "一键连招配置迁移", "Iconi")
        return
    }
    msg := dryRun ? "以下配置需要迁移：" : "已迁移以下配置："
    for sec in changed {
        msg .= "`n" sec
    }
    MsgBox(msg, "一键连招配置迁移", "Iconi")
}

MigrateConfig(ConfigPathFromArgs(), IsDryRun())
