#Requires AutoHotkey v2.0

global gUiListBoxDragSort := Map()

OnMessage(0x0201, UiListBoxDragSort_OnLButtonDown)
OnMessage(0x0202, UiListBoxDragSort_OnLButtonUp)
OnMessage(0x0200, UiListBoxDragSort_OnMouseMove)

UiListBoxDragSort_Attach(ctrl, getItemsFn, renderFn, commitFn, clickFn := "") {
    global gUiListBoxDragSort
    if !IsObject(ctrl) {
        return
    }
    gUiListBoxDragSort[ctrl.Hwnd] := {
        ctrl: ctrl,
        getItemsFn: getItemsFn,
        renderFn: renderFn,
        commitFn: commitFn,
        clickFn: clickFn,
        down: false,
        previewing: false,
        startIndex: 0,
        hoverIndex: 0,
        currentIndex: 0,
        startX: 0,
        startY: 0,
        previewList: []
    }
}

UiListBoxDragSort_IsActive(ctrl) {
    global gUiListBoxDragSort
    if !IsObject(ctrl) || !gUiListBoxDragSort.Has(ctrl.Hwnd) {
        return false
    }
    state := gUiListBoxDragSort[ctrl.Hwnd]
    return state.down || state.previewing
}

UiListBoxDragSort_IndexFromClientPoint(ctrl, x, y) {
    if !IsObject(ctrl) || x = "" || y = "" {
        return 0
    }
    lp := (y << 16) | (x & 0xFFFF)
    ret := DllCall("SendMessage", "ptr", ctrl.Hwnd, "uint", 0x01A9, "ptr", 0, "ptr", lp, "ptr")
    outside := (ret >> 16) & 0xFFFF
    idx0 := ret & 0xFFFF
    if (outside != 0 || idx0 = 0xFFFF) {
        return 0
    }
    return idx0 + 1
}

UiListBoxDragSort_MoveArrayItemInPlace(arr, fromIndex, toIndex) {
    if !IsObject(arr) {
        return 0
    }
    if (fromIndex <= 0 || toIndex <= 0 || fromIndex > arr.Length || toIndex > arr.Length) {
        return 0
    }
    if (fromIndex = toIndex) {
        return fromIndex
    }
    moving := arr[fromIndex]
    arr.RemoveAt(fromIndex)
    if (toIndex < 1) {
        toIndex := 1
    } else if (toIndex > arr.Length + 1) {
        toIndex := arr.Length + 1
    }
    arr.InsertAt(toIndex, moving)
    return toIndex
}

UiListBoxDragSort_CopyArray(items) {
    copy := []
    if !IsObject(items) {
        return copy
    }
    loop items.Length {
        if items.Has(A_Index) {
            copy.Push(items[A_Index])
        }
    }
    return copy
}

UiListBoxDragSort_RenderStrings(ctrl, items, selectedIndex) {
    ctrl.Delete()
    if IsObject(items) {
        loop items.Length {
            if !items.Has(A_Index) {
                continue
            }
            item := items[A_Index]
            if (item != "") {
                ctrl.Add([item])
            }
        }
    }
    if (selectedIndex > 0) {
        try ctrl.Choose(selectedIndex)
    }
}

UiListBoxDragSort_ClearState(state) {
    state.down := false
    state.previewing := false
    state.startIndex := 0
    state.hoverIndex := 0
    state.currentIndex := 0
    state.startX := 0
    state.startY := 0
    state.previewList := []
}

UiListBoxDragSort_OnLButtonDown(wParam, lParam, msg, hwnd) {
    global gUiListBoxDragSort
    if !gUiListBoxDragSort.Has(hwnd) {
        return
    }
    state := gUiListBoxDragSort[hwnd]
    ctrl := state.ctrl
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    UiListBoxDragSort_ClearState(state)
    state.startX := x
    state.startY := y
    state.startIndex := UiListBoxDragSort_IndexFromClientPoint(ctrl, x, y)
    state.hoverIndex := state.startIndex
    state.currentIndex := state.startIndex
    state.down := (state.startIndex > 0)
    if state.down {
        state.previewList := state.getItemsFn.Call()
        DllCall("SetCapture", "ptr", ctrl.Hwnd)
    }
}

UiListBoxDragSort_OnMouseMove(wParam, lParam, msg, hwnd) {
    global gUiListBoxDragSort
    if !gUiListBoxDragSort.Has(hwnd) {
        return
    }
    state := gUiListBoxDragSort[hwnd]
    if !state.down {
        return
    }
    if (state.startIndex <= 0 || !IsObject(state.previewList) || state.previewList.Length = 0) {
        return
    }
    ctrl := state.ctrl
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    if (!state.previewing && Abs(x - state.startX) < 4 && Abs(y - state.startY) < 4) {
        return
    }
    hoverIndex := UiListBoxDragSort_IndexFromClientPoint(ctrl, x, y)
    if (hoverIndex <= 0 || hoverIndex > state.previewList.Length) {
        return
    }
    fromIndex := state.currentIndex
    if (fromIndex <= 0 || fromIndex > state.previewList.Length || hoverIndex = fromIndex) {
        return
    }
    state.previewing := true
    state.hoverIndex := hoverIndex
    newIndex := UiListBoxDragSort_MoveArrayItemInPlace(state.previewList, fromIndex, hoverIndex)
    if (newIndex <= 0) {
        return
    }
    state.currentIndex := newIndex
    state.renderFn.Call(ctrl, state.previewList, newIndex)
}

UiListBoxDragSort_OnLButtonUp(wParam, lParam, msg, hwnd) {
    global gUiListBoxDragSort
    if !gUiListBoxDragSort.Has(hwnd) {
        return
    }
    state := gUiListBoxDragSort[hwnd]
    if !state.down {
        return
    }
    ctrl := state.ctrl
    previewing := state.previewing
    previewList := state.previewList
    currentIndex := state.currentIndex
    DllCall("ReleaseCapture")
    UiListBoxDragSort_ClearState(state)
    if previewing {
        state.commitFn.Call(previewList, currentIndex)
    } else if (state.clickFn != "") {
        state.clickFn.Call(ctrl)
    }
}
