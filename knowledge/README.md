# 项目知识库

南昌工学院课表 App：在校方页面登录后本地导入、保存、展示课程并提供提醒。

## 项目边界

- Codex 独立项目：`课程表`，根目录 `D:\桌面\课程表`。
- Obsidian 独立仓库：`课表知识库`，根目录 `D:\桌面\课程表\课表知识库`。
- Obsidian 仓库中的 `项目知识` 是指向本目录的 NTFS Junction，因此两处展示的是同一份文件，不维护重复副本。
- `数模` 的根目录是 `D:\桌面\数模`，两者不是同一项目。
- 本目录是课程表项目的唯一知识库；后续 Agent 不得把状态写入数模知识库或数模项目页。

推荐顺序：`current_state.md` → `tasks.md` → 当前任务专题文档。

- `architecture.md`：系统结构和数据流
- `decisions.md`：重要技术决策
- `issues.md`：问题与技术债
- `ncpu_import.md`：南昌工学院导入事实
- `home_widget.md`：Android 桌面小组件协议、刷新时机与真机验收步骤
- `testing.md`：测试范围与结果
- `changelog.md`：实质变更记录
- `android_setup.md`：Android 工具链配置与验收交接
- `android_agent_prompt.md`：可直接交给环境配置 Agent 的提示词

所有文件均由执行任务的 Agent 在任务结束前同步维护。
