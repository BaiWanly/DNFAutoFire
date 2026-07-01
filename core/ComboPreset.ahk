#Requires AutoHotkey v2.0

; 一键连招：多方案序列的读写与解析（主进程与子进程共用，勿依赖仅主进程才有的 GUI）

ComboPreset_LoadField(presetName, key, default := "") {
    presetName := NormalizePresetName(presetName)
    if (presetName = "") {
        return ""
    }
    return Trim(StrReplace(String(LoadPreset(presetName, key, default)), "`r", ""))
}

ComboCanonMainKey(raw) {
    s := Trim(String(raw))
    if (s = "") {
        return ""
    }
    return s
}

; 空技能占位符：UI 中清空技能键时使用，序列化/解析/克隆层不需特殊处理
ComboEmptySkillKey() {
    return "<NONE>"
}

ComboIsEmptySkillKey(key) {
    return Trim(String(key)) = ComboEmptySkillKey()
}

ComboNormalizeDelay(raw) {
    delay := Round((Trim(String(raw)) = "" ? 20 : raw) + 0)
    return delay
}

ComboSkillHoldDefault() {
    return 12
}

ComboNormalizeHold(raw) {
    s := Trim(String(raw))
    if (s = "") {
        return ComboSkillHoldDefault()
    }
    hold := Round(s + 0)
    if (hold < 0) {
        hold := 0
    }
    return hold
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

ComboExportFileSection() {
    return "DNFAutoFireComboExport"
}

ComboBlankProfileMarker() {
    return "blank"
}

ComboBlankProfile() {
    return { trigger: "", loop: false, blockOriginal: false, skills: [] }
}

ComboNormalizeStoredKey(raw) {
    if (Type(raw) != "String" && Trim(String(raw)) = "0") {
        return ""
    }
    return ComboCanonMainKey(raw)
}

ComboIsBlankProfile(p) {
    if !IsObject(p) {
        return false
    }
    trigger := HasProp(p, "trigger") ? ComboNormalizeStoredKey(p.trigger) : ""
    loopOn := HasProp(p, "loop") && p.loop
    blockOriginal := HasProp(p, "blockOriginal") && p.blockOriginal
    skills := (HasProp(p, "skills") && IsObject(p.skills)) ? p.skills : []
    return trigger = "" && !loopOn && !blockOriginal && ComboSerializeSkills(skills) = ""
}

ComboWriteExportFile(filePath, profiles) {
    filePath := Trim(String(filePath))
    if (filePath = "") {
        throw Error("EMPTY_PATH")
    }
    section := ComboExportFileSection()
    IniWrite(ComboSerializeProfiles(profiles), filePath, section, "Profiles")
}

ComboReadExportFile(filePath) {
    filePath := Trim(String(filePath))
    if (filePath = "" || !FileExist(filePath)) {
        throw Error("MISSING_FILE")
    }
    section := ComboExportFileSection()
    raw := IniRead(filePath, section, "Profiles", "")
    if (Trim(String(raw)) = "") {
        throw Error("MISSING_SECTION")
    }
    profiles := ComboParseProfiles(raw)
    if (profiles.Length = 0) {
        throw Error("EMPTY_PROFILES")
    }
    return profiles
}

ComboSerializeSkills(items) {
    data := ""
    if !IsObject(items) {
        return data
    }
    rs := ComboSkillRecordSeparator()
    us := ComboSkillUnitSeparator()
    defaultHold := ComboSkillHoldDefault()
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        item := items[A_Index]
        if !IsObject(item) {
            continue
        }
        key := HasProp(item, "key") ? ComboNormalizeStoredKey(item.key) : ""
        if (key = "") {
            continue
        }
        delay := HasProp(item, "delay") ? ComboNormalizeDelay(item.delay) : 20
        hold := HasProp(item, "hold") ? ComboNormalizeHold(item.hold) : defaultHold
        if (data != "") {
            data .= rs
        }
        ; hold 等于默认值时省略第三段，旧版本仍能正常读取 key 与 delay
        if (hold = defaultHold) {
            data .= key us delay
        } else {
            data .= key us delay us hold
        }
    }
    return data
}

ComboParseSkills(raw) {
    items := []
    rs := ComboSkillRecordSeparator()
    us := ComboSkillUnitSeparator()
    defaultHold := ComboSkillHoldDefault()
    for unit in StrSplit(raw, rs) {
        unit := Trim(unit)
        if (unit = "") {
            continue
        }
        parts := StrSplit(unit, us,, 3)
        if (parts.Length < 1) {
            continue
        }
        key := ComboCanonMainKey(Trim(parts[1]))
        if (key = "") {
            continue
        }
        delayRaw := parts.Length >= 2 ? parts[2] : 20
        holdRaw := parts.Length >= 3 ? parts[3] : ""
        items.Push({ key: key, delay: ComboNormalizeDelay(delayRaw), hold: ComboNormalizeHold(holdRaw) })
    }
    return items
}

ComboSerializeProfiles(profiles) {
    out := ""
    if !IsObject(profiles) {
        return out
    }
    rs := ComboProfileRecordSeparator()
    us := ComboProfileUnitSeparator()
    loop profiles.Length {
        if !profiles.Has(A_Index) {
            continue
        }
        p := profiles[A_Index]
        if !IsObject(p) {
            continue
        }
        if ComboIsBlankProfile(p) {
            rec := ComboBlankProfileMarker()
            if (out != "") {
                out .= rs
            }
            out .= rec
            continue
        }
        trig := HasProp(p, "trigger") ? ComboNormalizeStoredKey(p.trigger) : ""
        loopOn := (HasProp(p, "loop") && p.loop) ? "1" : "0"
        blockOriginal := (HasProp(p, "blockOriginal") && p.blockOriginal) ? "1" : "0"
        skills := (HasProp(p, "skills") && IsObject(p.skills)) ? p.skills : []
        skillsStr := ComboSerializeSkills(skills)
        rec := trig us loopOn us blockOriginal us skillsStr
        if (out != "") {
            out .= rs
        }
        out .= rec
    }
    return out
}

ComboParseProfiles(raw) {
    out := []
    raw := Trim(String(raw))
    if (raw = "") {
        return out
    }
    rs := ComboProfileRecordSeparator()
    us := ComboProfileUnitSeparator()
    for rec in StrSplit(raw, rs) {
        rec := Trim(rec)
        if (rec = "") {
            continue
        }
        if (StrLower(rec) = ComboBlankProfileMarker()) {
            out.Push(ComboBlankProfile())
            continue
        }
        parts := StrSplit(rec, us)
        if (parts.Length != 4) {
            continue
        }
        trigger := ComboCanonMainKey(Trim(parts[1]))
        loopOn := Trim(parts[2]) = "1"
        blockOriginal := Trim(parts[3]) = "1"
        skillsRaw := parts[4]
        out.Push({ trigger: trigger, loop: loopOn, blockOriginal: blockOriginal, skills: ComboParseSkills(skillsRaw) })
    }
    return out
}

ComboLoadProfilesFromPreset(presetName) {
    raw := ComboPreset_LoadField(presetName, "ComboProfiles")
    return ComboParseProfiles(raw)
}
