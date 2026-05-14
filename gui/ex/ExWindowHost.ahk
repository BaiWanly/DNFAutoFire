#Requires AutoHotkey v2.0

class ExWindowHost {
    static MakeHeaderTitle(title) {
        title := Trim(title)
        return RegExMatch(title, "设置$") ? title : title "设置"
    }

    static AddInlineHeaderRight(guiObj, rightEdge, y, title, helpHandler, titleW := 120, helpW := 22, gap := 6) {
        xTitle := rightEdge - titleW - gap - helpW
        guiObj.Add("Text", "x" xTitle " y" y " w" titleW " h22 +0x200 Right", title)
        GuiTheme_FlatBtnSmall(guiObj, "x" (xTitle + titleW + gap) " y" y " w" helpW " h22", GuiText.HelpButton(), helpHandler)
    }

    static AddInlineHeaderLeft(guiObj, x, y, title, helpHandler, titleW := 120, helpW := 22, gap := 6) {
        guiObj.Add("Text", "x" x " y" y " w" titleW " h22 +0x200", title)
        GuiTheme_FlatBtnSmall(guiObj, "x" (x + titleW + gap) " y" y " w" helpW " h22", GuiText.HelpButton(), helpHandler)
    }

    static AddAutoFooter(guiObj, ruleY, buttonText, handler, leftX := 16, saveGap := 10, saveH := 34, includeHidden := false) {
        rightEdge := GuiTheme_ContentMaxRight(guiObj, includeHidden)
        contentW := Max(0, rightEdge - leftX)
        GuiTheme_HRule(guiObj, leftX, ruleY, contentW)
        return GuiTheme_FlatBtn(guiObj, "x" leftX " y" (ruleY + saveGap) " w" contentW " h" saveH, buttonText, handler, true)
    }

    static ShowOwned(guiObj, title, sizeSpec, loadCallback := "") {
        global gMainGui
        if IsObject(gMainGui) {
            guiObj.Opt("+Owner" gMainGui.Hwnd)
        }
        guiObj.Title := title
        guiObj.Show(sizeSpec)
        if IsObject(loadCallback) {
            loadCallback.Call()
        }
        DisableGuiMain()
    }

    static ShowOwnedFit(guiObj, title, loadCallback := "", rightPad := 16, bottomPad := 16, minW := 0, minH := 0, extraOpts := "") {
        global gMainGui
        if IsObject(gMainGui) {
            guiObj.Opt("+Owner" gMainGui.Hwnd)
        }
        guiObj.Title := title
        GuiTheme_ShowFit(guiObj, extraOpts, rightPad, bottomPad, minW, minH)
        if IsObject(loadCallback) {
            loadCallback.Call()
        }
        DisableGuiMain()
    }

    static HideOwned(guiObj) {
        guiObj.Hide()
        EnableGuiMain()
    }

    static ShowHelp(message, title := "", ownerGui := "") {
        opts := ""
        if IsObject(ownerGui) {
            opts := "Owner" ownerGui.Hwnd
        }
        MsgBox(message, title, opts)
    }
}
