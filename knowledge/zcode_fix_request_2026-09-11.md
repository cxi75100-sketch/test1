# 交给 Zcode 的修改任务书（TASK-033 审查整改）

日期：2026-09-11
仓库：`D:\桌面\课程表`
远端：`https://gitee.com/chenxihh/test_c.git`
审查基线：`6b321a4e64efd64d79b7c5f7168fc46bbf99002c`
原始审查报告：`knowledge/review_2026-09-11_zcode_gitee.md`

## 给 Zcode 的完整任务

请在现有架构内完成下面的整改。开工前必须依次阅读 `AGENTS.md`、`knowledge/current_state.md`、`knowledge/tasks.md`、`knowledge/review_2026-09-11_zcode_gitee.md`，并先运行 `git status --short --branch`。当前工作区已有 Agent 生成但尚未提交的审查文档和知识库更新，必须保留，不得用 reset、checkout、clean 或覆盖式写入撤销他人的改动。

### 一、修复导入差异摘要漏报详情变化（最高优先级）

相关文件：

- `lib/features/import/services/import_diff.dart`
- `lib/features/import/widgets/import_preview_dialog.dart`
- `lib/features/import/pages/import_login_page.dart`（只在接口变化确有需要时改）
- `test/import_diff_test.dart`
- `test/import_preview_dialog_test.dart`

当前问题：差异逻辑只比较 `Course.id`。同一 id 下课程名、教师、教室、备注等字段变化时，界面仍显示“与上次导入一致”，但确认导入后数据库会写入新详情。

必须完成：

1. 保留现有 `added`、`removed` 语义，新增 `changed` 语义；每条变化必须同时保留旧课程和新课程，便于 UI 展示。
2. 同一 id 的课程至少比较：`name`、`teacher`、`classroom`、`weekday`、`startSection`、`endSection`、`weeks`、`startTime`、`endTime`、`note`。列表必须按内容比较，不能只比较对象引用。
3. 同一 id 的详情变化只能计入 `changed`，不能同时计入新增或移除。
4. `ImportDiff.isEmpty` 必须同时考虑 `added`、`removed`、`changed`。
5. 预览摘要改为“新增 N 条 · 移除 N 条 · 修改 N 条”。只有三类均为空时才能显示“与上次导入一致”。
6. 摘要中列出被修改的课程，并清楚显示变化字段；至少让用户看出“旧值 → 新值”。空教师、空教室等值要用可读占位符。
7. 保持手动课程不受导入影响，不改变 `replaceImportedCourses` 的事务和来源隔离逻辑。
8. 不把教务原始响应、身份字段、Cookie、Session 或 Token 写入日志、测试快照或知识库。

必须新增或修改测试：

- 完全相同：`isEmpty == true`。
- 同 id 改课程名、教师、教室、备注：进入 `changed`。
- 同 id 改星期、节次、周次或明确起止时间：进入 `changed`。
- 同 id 未变化：不进入任何列表。
- UI 同时正确显示新增、移除、修改数量。
- UI 修改项展示至少一个“旧值 → 新值”的真实字段变化。
- 没有任何变化时才显示“与上次导入一致”。

### 二、修复 `next` 未过滤手动课程的契约错误

相关文件：`lib/features/import/services/import_diff.dart`、`test/import_diff_test.dart`。

必须完成：

1. `previous` 和 `next` 两侧都只比较 `CourseSource.ncpu`。
2. `next` 中混入 `manual` 时，不得计入新增、移除或修改。
3. 新增专门测试锁定这一行为。
4. 不要通过删除函数注释掩盖实现不一致。

### 三、同步知识库中的真实项目状态

事实基准：

- TASK-021 教务导入端到端已经完成。
- TASK-019 已确认：启动器可找到并添加小组件、表头和当天课程可渲染、点击小组件可打开 App。
- TASK-019 尚未确认：课程变化后的即时刷新、溢出“还有 N 门课”、跨天重算；缩放是否完成必须以已有真实记录为准，不得猜测。
- 小组件曾因直接向真机数据库注入中文 SQL 发生编码事故，已经回退；不得为补验证再次直接修改真机生产数据库。

需要同步检查：`knowledge/current_state.md`、`knowledge/tasks.md`、`knowledge/home_widget.md`、`knowledge/testing.md`、`knowledge/issues.md`、`knowledge/changelog.md`。

要求：

1. 删除或明确标注已经过期的“完整导入仍未验收”“小组件添加/渲染/点击均 BLOCKED”等当前结论。
2. `Current Milestone`、`Current Blockers`、`Recommended Next Action`、`Handoff/What remains unverified` 必须一致。
3. 历史测试记录可以保留，但必须标明是当时快照，不能在文件末尾继续作为当前结论。
4. 不得把没有真机证据的溢出、跨天或即时刷新升级为 `CONFIRMED`。
5. 更新任务和变更日志，记录实际修改与验证，不伪造测试数量或真机结论。

### 四、公开提交邮箱的处理边界

当前公开历史的 9 个提交均含个人 Gmail 地址。这一项涉及用户身份与 Git 历史：

1. 先报告 `git config user.name`、`git config user.email` 的来源层级，但在输出中对邮箱脱敏。
2. 未取得用户给出的目标邮箱前，不猜测 Gitee noreply 邮箱格式，不擅自改写配置。
3. 未取得明确授权前，禁止 rebase、filter-repo、filter-branch、强制推送或重写已有提交。
4. 用户若提供目标邮箱，只配置未来提交；是否重写历史作为单独任务确认。

### 五、验证要求

```powershell
if (-not (Test-Path 'R:\')) { subst R: 'D:\桌面\课程表' }
Set-Location R:\
flutter analyze
flutter test

$env:JAVA_HOME='D:\Tools\jdk-17'
$env:ANDROID_HOME='D:\Tools\android-sdk'
Set-Location R:\android
.\gradlew.bat :app:testDebugUnitTest
```

验证规则：

- 任一命令失败都不得报告“全部通过”，应给出准确错误和影响范围。
- `android/local.properties` 被 Git 忽略；不得为让 Lint 变绿而把它提交进仓库。
- 没有连接设备时，不得声称完成新的真机验证。
- 只做最小修改，不升级 Flutter、AGP、Kotlin或依赖版本，不重构无关模块。

### 六、禁止事项

- 禁止直接写真机生产数据库制造测试数据。
- 禁止保存或输出学号、真实姓名、密码、Cookie、Session ID、Token 或原始教务响应。
- 禁止修改或删除手动课程隔离逻辑。
- 禁止覆盖当前未提交的审查报告和本任务书。
- 禁止 `git reset --hard`、`git clean`、强制推送或历史重写。
- 未经明确要求，不提交、不推送、不发布 APK。

### 七、完成时的交付报告

1. 修改文件及每个文件的修改理由。
2. 差异模型如何识别 `added`、`removed`、`changed`。
3. 新增/修改的测试及实际通过数量。
4. 修正了哪些知识库矛盾。
5. 未完成和未验证项，尤其是真机溢出、跨天与即时刷新。
6. Git 邮箱隐私项状态；缺少目标邮箱时标为等待用户决定。
7. 最终 `git status --short --branch`，并说明哪些文件在本轮之前已经未提交。

## 验收标准

- 同 id 的课程详情变化不再显示“与上次导入一致”。
- `next` 中的手动课程不会进入差异。
- 现有写库行为、手动课程保护和安全边界不回退。
- 自动测试全部通过，新增测试真实覆盖逻辑与 UI。
- 当前状态文档之间不再互相矛盾。
- 未经授权不改 Git 历史、不推送、不操作真机生产数据。
