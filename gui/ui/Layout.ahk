#Requires AutoHotkey v2.0

UiRect(x, y, w, h, extra := "") {
    options := "x" x " y" y " w" w " h" h
    return extra = "" ? options : options " " extra
}

UiMoveX(&x, width, gap := 4) {
    x += width + gap
    return x
}

UiSpacer(&x, width) {
    x += width
    return x
}

UiColumnX(index, start := 8, step := 88) {
    return start + (index - 1) * step
}

UiRowY(index, start := 8, step := 24) {
    return start + (index - 1) * step
}
