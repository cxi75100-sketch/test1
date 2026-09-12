# 项目知识库

南昌工学院课表 App：在校方页面登录后本地导入、保存、展示课程并提供提醒。

## 项目边界

- 独立项目：`课程表`，根目录 `D:\桌面\课程表`，独立 Git 仓库。
- Obsidian 独立仓库：`课表知识库`，根目录 `D:\桌面\课程表\课表知识库`。
- Obsidian 仓库中的 `项目知识` 是指向本目录的 NTFS Junction，因此两处展示的是同一份文件，不维护重复副本。
- 本目录是本项目的唯一知识库。

推荐顺序：`current_state.md` → `tasks.md` → 当前任务专题文档。

- `architecture.md`：系统结构和数据流
- `decisions.md`：重要技术决策
- `issues.md`：问题与技术债
- `ncpu_import.md`：南昌工学院导入事实
- `home_widget.md`：Android 桌面小组件协议、刷新时机与真机验收步骤
- `notifications.md`：Android 本地上课提醒的行为、权限、调度与真机验收步骤
- `release.md`：release 签名配置、分 ABI 打包、验证结果与分发步骤
- `plan_multischool_2026-09-12.md`：多校接入与校历适配计划书（含单校硬编码清单与待决策项）
- `report_2026-09-12.md`：2026-09-12 当日改动报告（提交清单、release 打包、计划书、性能排查）
- `report_2026-09-13_ui_theme_and_next_plan.md`：UI、明暗主题更新报告（实施问题、证据边界、下一步优化与多校衔接）
- `testing.md`：测试范围与结果
- `changelog.md`：实质变更记录
- `incident_2026-09-11_db_injection.md`：事故报告 —— 真机数据库注入因 GBK 编码导致 App 课表加载失败
- `review_2026-09-11_zcode_gitee.md`：2026-09-11 Zcode 改动与 Gitee 仓库审查报告
- `zcode_fix_request_2026-09-11.md`：审查整改任务书（交 Zcode 执行）
- `zcode_fix_report_2026-09-11.md`：整改交付报告（含未改动清单与验收对照）
- `review_2026-09-11_task035.md`：TASK-035 独立复核（含批量修改弹窗溢出证据）
- `android_setup.md`：Android 工具链配置与验收交接
- `android_agent_prompt.md`：可直接交给环境配置 Agent 的提示词

所有文件均由执行任务的 Agent 在任务结束前同步维护。
