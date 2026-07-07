#Requires AutoHotkey v2.0

class AutoPresetsLayout {
    ; 窗口与内容边界
    static Window() => UiContentLayout(16, 24)
    static MarginX() => 16
    static WindowWidth() => this.ContentRight() + 16

    ; 下部配置列表、技能图列表与右侧技能预览列
    static ListWidth() => 80
    static SkillIconListGap() => 4
    static SkillIconListX() => this.MarginX() + this.ListWidth() + this.SkillIconListGap()
    static SkillIconListWidth() => this.ListWidth()
    static RightGap() => 8
    static RightX() => this.SkillIconListX() + this.SkillIconListWidth() + this.RightGap()
    static RightWidth() => 120
    static ContentRight() => this.RightX() + this.RightWidth()
    static PreviewWidth() => 120
    static PreviewHeight() => 120
    static PreviewY() => this.ListY()

    ; 中部列表与预览
    static DungeonListWidth() => 120
    static DungeonPreviewGap() => 52
    static DungeonX() => this.MarginX() + this.DungeonListWidth() + this.DungeonPreviewGap()
    static DungeonPreviewWidth() => 120
    static DungeonPreviewHeight() => 120
    static DungeonListX() => this.MarginX()
    static DungeonListY() => this.DungeonY()
    static DungeonListHeight() => 160
    static RowActionY() => this.PreviewY() + this.PreviewHeight() + 12

    ; 顶部启用开关、热键输入与框选按钮
    static EnableY() => 44
    static HotkeyY() => 78
    static PickBtnY() => this.HotkeyY() + ExLayout.ControlHeight() + 8

    ; 中部、下部和保存区的纵向位置
    static MiddleY() => this.PickBtnY() + ExLayout.ControlHeight() + 16
    static MiddlePreviewY() => this.MiddleY() + 16
    static DungeonY() => this.MiddlePreviewY()
    static DungeonBtnY() => this.DungeonY() + this.DungeonPreviewHeight() + 12
    static LowerY() => this.DungeonBtnY() + ExLayout.ControlHeight() + 4
    static ListY() => this.LowerY() + 24
    static ListHeight() => 160
    static SaveY() => this.ListY() + this.ListHeight() + 8
}
