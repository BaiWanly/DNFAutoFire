## DNF输入
DNF 对模拟输入参数较敏感。普通 VK + 扫描码输入可能同时影响游戏和聊天框。
项目在游戏窗口内使用 `vk=0xFF` 的游戏模式输入，避免聊天框误识别。

## 代码整理
- 替换旧实现时，不要保留无引用的兼容壳、别名类、废弃文件或重复运行时
- 能直接统一为当前方案时，就直接收敛，不要同时保留新旧两套入口
- 提交前检查是否还有旧命名残留；不要继续留旧命名在项目里

## 文档同步
- 流程变动或者修改后，同步修改 `README.md`
- 功能变动或者修复后，同步更新 `CHANGELOG.md` 最近一个版本的更新日志
- 忽略原始更新日志.txt，人工手动维护

## 解释器路径
- `C:\Program Files\AutoHotkey\v2\AutoHotkey.exe`

## 新增 EX 功能指引

当前 EX 功能统一收敛到一个输入运行时：

- 运行时入口：`ex/ExActionRuntime.ahk`
- 主界面开关与入口：`gui/Main.ahk`
- EX 文案：`gui/exText.ahk`、`gui/MainText.ahk`
- EX 设置窗口：`gui/ex/*.ahk`
- 预设保存/读取：`core/Scripts.ahk`、各 `gui/ex/*.ahk`

新增 EX 功能时，优先复用现有模块，不要回到“一个功能一个独立子进程 .ahk”的旧模式。

### 推荐实现顺序

1. 先定义功能模型
   - 先判断新功能属于哪一类：
     - 多触发键按住时重复补发一个键
     - 按下边沿只发一次
     - 点按后延迟发一次
     - 按住超过延迟后持续补发
     - 单触发键执行一段技能序列
     - 方向键/热键型特殊动作
   - 如果能落进现有策略，就复用现有策略；不要先写新循环。

2. 再补设置界面
   - 在 `gui/ex/` 新建对应窗口文件，优先复用：
     - `UiSkillKeyEditor(...)`：适合“触发键列表 + 目标键 + 延迟”的大多数技能类 EX
     - `UiPressKeyEdit(...)`：可点击只读框采集单键（列表添加仍用 `GetPressKey()`）
     - `UiListBoxDragSort_Attach(...)`：可拖动排序的键列表
   - 设置窗口负责把参数写入当前预设，例如：
     - `XXXState`
     - `XXXSkillKeys`
     - `XXXShotKey`
     - `XXXDelay`

3. 接到主界面
   - 在 `gui/Main.ahk` 里给新 EX 加开关、入口按钮和加载逻辑。
   - 在 `gui/MainText.ahk` / `gui/exText.ahk` 里补名称、按钮、帮助文案。
   - 在 `core/Scripts.ahk` 的 `SaveMainPresetState()` / `LoadMainPresetState()` 相关流程里确认 `XXXState` 会随预设保存和恢复。

4. 最后接运行时
   - 在 `ex/ExActionRuntime.ahk` 中补：
     - `XXXLoadKeys(presetName)` 之类的配置读取函数
     - `ExAction_BuildRules(presetName)` 中的规则注册
   - 优先复用现有规则构建器：
     - `ExAction_AddRepeatRule(...)`
     - `ExAction_AddEdgeRule(...)`
     - `ExAction_AddDelayOnceRule(...)`
     - `ExAction_AddDelayRepeatRule(...)`

### 什么时候只加规则，什么时候新增策略

- 只加规则：
  - 新功能只是现有触发模型的一个变体
  - 只是触发键、目标键、延迟、间隔不同
  - 可以表达成“已有 policy + 新配置”

- 新增策略：
  - 现有 `policy` 不能表达行为语义
  - 需要额外状态机，例如：
    - 双击后切换状态
    - 点按后排程，但期间可被另一事件取消
    - 有节奏窗口、次数上限、冷却期
  - 此时在 `ExActionRuntime._RuleTickCore()` 中新增 `case`，并给规则对象补最小必要状态字段

### 运行时约束

- 一律复用 `SendIP(...)` 发送游戏输入，不要自行换成普通 `Send`
- 触发键物理态判断复用 `Key2PressKey(...)` + `GetKeyState(..., "P")`
- EX 运行时已统一处理：
  - `InstallKeybdHook()`
  - `UnlockSystemTimeLimit()`
  - `WinActive("ahk_group DNF")`
  - 焦点丢失后的状态清理
- 不要在新 EX 里再手写常驻 `loop { Sleep(1) }` 轮询，优先用规则 tick、`SetTimer`、或现有热键回调模型

### 代码风格约束

- 能在 `ExActionRuntime.ahk` 中以“新规则 + 少量辅助函数”落地，就不要新建新的运行时文件
- 能复用 `UiSkillKeyEditor(...)`，就不要再重复搭一套相似 GUI
- 新增 EX 后，检查是否还残留旧命名、旧入口、无引用文件
- 功能行为变了，同步更新 `README.md`
- 修复或新增功能后，同步更新 `CHANGELOG.md`

### 一个最常见的新增路径

如果用户要一个“按这些技能键时，自动补一个键”的职业 EX，通常按下面做：

1. 新建 `gui/ex/XXX.ahk`
2. 保存 `XXXSkillKeys`、`XXXShotKey`，必要时保存 `XXXDelay`
3. 在 `gui/Main.ahk` / 文案文件中加开关和入口
4. 在 `ex/ExActionRuntime.ahk` 中新增：
   - `XXXLoadKeys(presetName)`
   - 在 `ExAction_BuildRules()` 里调用对应的 `ExAction_Add*Rule(...)`

如果用户要的是完全不同的时序行为，再考虑新增 `policy`，不要先拆出新子进程。
