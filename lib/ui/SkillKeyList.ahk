#Requires AutoHotkey v2.0

; EX 技能键列表的公共行为，页面只负责自己的配置字段。
class UiSkillKeyList {
    __New(ctrl) {
        this.ctrl := ctrl
        this.items := []
        UiListBoxDragSort_Attach(ctrl, ObjBindMethod(this, "DragGetItems"), UiListBoxDragSort_RenderStrings, ObjBindMethod(this, "DragCommit"))
    }

    Load(raw) {
        this.items := ParseKeyList(raw)
        this.Render()
    }

    Render(selectedIndex := 1) {
        this.ctrl.Delete()
        this.ctrl.Add(this.items)
        if this.items.Length {
            this.ctrl.Choose(selectedIndex)
        }
    }

    Add(*) {
        key := GetPressKey()
        for idx, item in this.items {
            if (item == key) {
                MsgBox(exText["DuplicateKey"],, "Icon!")
                this.Render(idx)
                return
            }
        }
        this.items.Push(key)
        this.Render(this.items.Length)
    }

    Delete(*) {
        idx := this.ctrl.Value
        if idx {
            this.items.RemoveAt(idx)
            this.Render()
        }
    }

    DragGetItems(*) {
        return this.items.Clone()
    }

    DragCommit(items, selectedIndex) {
        this.items := items
        this.Render(selectedIndex)
    }
}
