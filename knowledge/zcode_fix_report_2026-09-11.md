# TASK-035 整改交付报告（Zcode 修改任务书执行结果）

- 报告日期：2026-09-11 20:12 +08:00
- 任务书：`knowledge/zcode_fix_request_2026-09-11.md`
- 审查报告：`knowledge/review_2026-09-11_zcode_gitee.md`
- 审查基线：`6b321a4e64efd64d79b7c5f7168fc46bbf99002c`
- 结论：任务书第一、二、三节完成；第四节（Git 邮箱）只报告不改动，等待用户给出目标邮箱；第五节验证全部执行；第六节禁止事项全部遵守。
- 提交状态：**未提交、未推送**。工作区改动全部保留为待审查状态。

---

## 1. 摘要

| 项目 | 结果 |
| --- | --- |
| P2-1 导入差异漏报详情变化 | 已修复（新增 `changed` + 逐字段内容比较） |
| P2-2 知识库状态互相矛盾 | 已修复（8 个知识库文件同步，历史快照加注） |
| P2-3 公开提交暴露个人 Gmail | **未改动**，仅报告；等待用户决定目标邮箱 |
| P3-1 `next` 未过滤手动课程 | 已修复（双侧只取 `CourseSource.ncpu`） |
| `flutter analyze`（`R:\`） | No issues found |
| `flutter test` | 111/111 passed（上轮 103，净增 8） |
| `gradlew :app:testDebugUnitTest --rerun` | 13 / 0 / 0 / 0 |
| 真机验证 | **本轮未做**（`adb devices -l` 为空） |
| 真机生产数据库 | **未触碰** |
| Git 历史 / 配置 | **未改动** |

---

## 2. 修改的文件及理由（14 个）

### 2.1 业务源码（2）

| 文件 | 改动 | 理由 |
| --- | --- | --- |
| `lib/features/import/services/import_diff.dart` | 新增 `CourseChange`、`CourseFieldChange`；`ImportDiff` 增加 `changed`；新增并导出 `courseFieldChanges()`；导出 `weekdayLabels`；`diffImportedCourses` 双侧过滤 `ncpu` | 修复 P2-1 与 P3-1。差异不能只看 `id`，否则教务调整教师/教室/课程名后 UI 仍报「与上次导入一致」，而确认导入后数据库确实写入新值 |
| `lib/features/import/widgets/import_preview_dialog.dart` | 摘要改为三类计数；新增「本次修改」区块渲染「旧值 → 新值」；空值显示「（未填）」；改用共享 `weekdayLabels` | 让用户在按下「确认导入」前看见详情变化；删除私有 `_weekdayNames` 以避免与差异模型各存一份星期名 |

### 2.2 测试（2）

| 文件 | 改动 | 理由 |
| --- | --- | --- |
| `test/import_diff_test.dart` | 6 → 12 例 | 覆盖任务书要求的全部差异矩阵，并锁定 `next` 混入 `manual` 的行为 |
| `test/import_preview_dialog_test.dart` | 3 → 5 例 | 锁定三类计数、真实「旧值 → 新值」、空值占位符、「只有修改时也不显示一致」 |

### 2.3 知识库（10）

| 文件 | 改动要点 |
| --- | --- |
| `knowledge/current_state.md` | 里程碑、Current Blockers、Recommended Next Action、Handoff/What remains unverified 四处同步改写；Git 提交数 4 → 9；Working Features 补充「修改」语义；新增本轮 Validation Snapshot |
| `knowledge/tasks.md` | TASK-035 登记后移入 Done（含证据）；TASK-019「剩余」补齐即时刷新/缩放/溢出/跨天并写入禁止再改生产库；TASK-017/018 的历史 BLOCKED 标注为当时快照 |
| `knowledge/home_widget.md` | 进度由「待完成 5、6、7、8」改为「已完成 3、4、6，待完成 5、7、8」；验证状态不再把渲染/点击列为 BLOCKED；补充「不得直接改真机生产库」 |
| `knowledge/testing.md` | 删除「完整教务导入未验收」「桌面小组件全部 BLOCKED」两条过期结论；新增 111/111 与 `--rerun` 13/13；ImportDiff/ImportPreviewDialog 测试描述同步；Tooling Note 增加禁止注入生产库规则 |
| `knowledge/issues.md` | ISSUE-007 → Resolved；ISSUE-008 去掉「真机交互仍 BLOCKED」；ISSUE-010 → Partially Resolved（列明剩余范围）；ISSUE-012 → Resolved；ISSUE-001 证据更新 |
| `knowledge/ncpu_import.md` | 两条「完整导入尚未真机验收」的 BLOCKED 结论改为已确认 |
| `knowledge/changelog.md` | 顶部新增本轮条目（Fixed/Added/Changed/Docs/Validation）；旧 TASK-019 条目的 BLOCKED 加注「当时快照」 |
| `knowledge/android_setup.md` | 第 8 条 BLOCKED 加注「2026-09-10 当时快照，后续已解除」 |
| `knowledge/README.md` | 文档索引补入审查报告、任务书与本报告（此前索引未列出审查报告与任务书） |
| `knowledge/zcode_fix_report_2026-09-11.md` | **新增**：本交付报告 |

---

## 3. 差异模型如何识别 added / removed / changed

1. **来源隔离**：`previousImported` / `nextImported` 分别只保留 `CourseSource.ncpu` 的课程。手动课程在两侧都不参与任何计算。
2. **added**：存在于 `nextImported` 且 `previousById` 中没有该 `id`。
3. **removed**：存在于 `previousImported` 且 `nextIds` 中没有该 `id`。
4. **changed**：`nextImported` 中 `id` 已存在于 `previousById` 时，执行 `courseFieldChanges(previous, current)`；字段列表非空才生成 `CourseChange{previous, current, fields}`。
5. 同一 `id` 的详情变化**只**进 `changed`：id 命中即不可能进 added，next 侧命中即不可能进 removed。
6. `ImportDiff.isEmpty` = `added.isEmpty && removed.isEmpty && changed.isEmpty`。

比较的字段（按值，不按引用）：课程名、教师、教室、星期、节次（`startSection`/`endSection`）、周次、起止时间、备注。`weeks` 逐项比较，不使用 `==` 或对象同一性；只有值不同才产生条目。

UI 表现：`新增 N 条 · 移除 N 条 · 修改 N 条`，三类皆空时才显示「与上次导入一致，没有新增、移除或修改。」；修改项逐条显示 `教师：张三 → 李四`，空值显示 `（未填）`。

---

## 4. 测试矩阵与实际结果

| 任务书要求 | 覆盖位置 | 结果 |
| --- | --- | --- |
| 完全相同 `isEmpty == true` | `import_diff_test.dart` | 通过 |
| 同 id 改课程名、教师、教室、备注 → `changed` | 同上（并断言 old/new 值） | 通过 |
| 同 id 改星期、节次、周次、起止时间 → `changed` | 同上 | 通过 |
| 同 id 未变化 → 不进任何列表 | 同上 | 通过 |
| 按内容比较（不同对象/不同数组实例） | 同上 | 通过 |
| `next` 含 `manual` → 不入新增/移除/修改 | 同上（2 个用例） | 通过 |
| UI 同时正确显示三类数量 | `import_preview_dialog_test.dart` | 通过 |
| UI 至少一个真实「旧值 → 新值」 | 同上 | 通过 |
| 空教师/空教室可读占位符 | 同上 | 通过 |
| 无任何变化才显示「与上次导入一致」 | 同上（含「只有修改时」反例） | 通过 |

命令与输出：

- `flutter analyze`（`R:\`）：`No issues found!`
- `flutter test`：`111 tests passed`（原 103；`import_diff` +6、`import_preview_dialog` +2）
- `gradlew :app:testDebugUnitTest --rerun`：`tests="13" failures="0" errors="0" skipped="0"`，BUILD SUCCESSFUL。首次无 `--rerun` 时为 UP-TO-DATE（Kotlin 未改动），故强制重跑取得本轮真实结果。
- `dart format --set-exit-if-changed`：初次报 3 个文件未格式化，格式化后重跑 analyze/test 仍全绿。

---

## 5. 未改动清单及原因

### 5.1 任务书明确要求不要动的

| 对象 | 原因 |
| --- | --- |
| `knowledge/review_2026-09-11_zcode_gitee.md` | 第六节禁止覆盖审查报告，原样保留 |
| `knowledge/zcode_fix_request_2026-09-11.md` | 第六节禁止覆盖任务书，原样保留 |
| `replaceImportedCourses` 的事务与来源隔离逻辑 | 第七节要求保持不动；本轮未触碰数据库层任何代码 |
| Git 配置与历史 | 第四节：未取得目标邮箱与授权前不改配置、不 rebase/filter-repo/filter-branch/强推 |
| 真机生产数据库 | 第六节禁止；本轮 `adb devices -l` 为空，也未安装测试数据 |
| `android/local.properties` | 被 Git 忽略，**未为了 Lint 变绿而提交**（未运行 `lintDebug`） |
| Flutter / AGP / Kotlin / 依赖版本 | 第五节：只做最小修改，不升级、不重构无关模块 |
| 未提交、未推送、未构建 APK | 第六节禁止未经要求提交/推送/发布 |

### 5.2 评估后确认「无需改动」的

| 对象 | 原因 |
| --- | --- |
| `lib/features/import/pages/import_login_page.dart` | 任务书要求「只在接口变化确有需要时改」。`diffImportedCourses` 保持同名同参数，调用点 `diff: diffImportedCourses(previous: previous, next: courses)` 无需调整；`previous` 在替换前读取的既有顺序也未改 |
| `lib/models/course.dart` | 要求的比较字段全部已存在，不需要扩展模型或 `copyWith` |
| 数据库 schema / Drift 代码 | 差异是纯计算，不落库 |
| `lib/features/import/services/import_session_cleaner.dart` | 与差异逻辑无关 |
| 小组件 Kotlin / `widget_*` 资源 | 本轮不涉及；仅文档同步状态 |
| 学期服务、课表页、UI 主题、课程表单 | 本轮不涉及 |
| `.gitignore` / `pubspec.yaml` / `android/app/build.gradle.kts` | 无新增依赖、无新增文件类型 |
| `knowledge/decisions.md` | 其中「接口尚未确认」「候选入口尚未真机验证」是**决策当时**的 Context，属历史决策记录，不是当前结论，保留原文 |
| `knowledge/architecture.md`、`teaching_calendar.md`、`android_agent_prompt.md`、`incident_2026-09-11_db_injection.md` | 本次 grep 复核未发现与小组件/导入验收相关的过期当前结论 |
| `knowledge/README.md` 的正文内容 | 只补了文档索引，未改动其项目边界等正文（正文本身仍准确） |
| `知识库` 内的 Git 提交记录描述（changelog 旧条目） | 历史条目按时间倒序排列，本身即快照；仅对两处会被误读为当前结论的 BLOCKED 加了「当时快照」标注 |

### 5.3 发现但未实施的（留待用户决定）

| 事项 | 说明 |
| --- | --- |
| 差异明细的滚动上限 | 本报告交付时尚未实施；TASK-036 随后用 27 条修改复现布局溢出，TASK-037 已改为有界单滚动区并补回归测试。 |
| 溢出分支真机验证方案 | 正常课量（当天 3 门、启动器最小可容 5 行）无法触发。任务书禁止再改真机生产库；后续应使用独立测试库或等自然课量 |
| 公开邮箱与历史重写 | 见第 6 节 |

---

## 6. 未完成与未验证项

- **未做任何新的真机验证**：`adb devices -l` 输出为空，无可用设备。
- 小组件仍未验证：数据变更后即时刷新、缩放、「还有 N 门课」溢出、跨天重算（TASK-019 剩余项）。
- 导入差异区块在教务数据**真实变化**时的真机显示仍未观察（当日数据未变，只出现「一致」）。三类排版与「旧值 → 新值」仅由自动测试覆盖，**未升级为 `CONFIRMED`**。
- 溢出、跨天、即时刷新三项均未获得证据，知识库中保持「未验证」措辞。

---

## 7. Git 邮箱隐私项状态：等待用户决定

- `git config user.name` = `c jh`
- `git config user.email` = `c***@gmail.com`（报告内脱敏）
- 来源层级：两者均来自 `file:C:/Users/ninan/.gitconfig`，即**全局配置**；项目 `.git/config` 无覆盖。
- 公开历史 9 个提交均含该邮箱。
- 本轮动作：**无**。未猜测 Gitee noreply 格式、未写配置、未改写历史。
- 待办：用户提供目标邮箱后，仅配置**未来提交**；是否重写既有历史作为独立任务另行确认。

---

## 8. 最终工作区状态

```
## master...origin/master
 M knowledge/README.md
 M knowledge/android_setup.md
 M knowledge/changelog.md
 M knowledge/current_state.md
 M knowledge/home_widget.md
 M knowledge/issues.md
 M knowledge/ncpu_import.md
 M knowledge/tasks.md
 M knowledge/testing.md
 M lib/features/import/services/import_diff.dart
 M lib/features/import/widgets/import_preview_dialog.dart
 M test/import_diff_test.dart
 M test/import_preview_dialog_test.dart
?? knowledge/review_2026-09-11_zcode_gitee.md
?? knowledge/zcode_fix_report_2026-09-11.md
?? knowledge/zcode_fix_request_2026-09-11.md
```

- **本轮之前就已未提交**：`knowledge/changelog.md`、`knowledge/current_state.md`、`knowledge/tasks.md`（修改），以及 `knowledge/review_2026-09-11_zcode_gitee.md`、`knowledge/zcode_fix_request_2026-09-11.md`（未跟踪）。全部原样保留。
- **本轮新增未提交**：其余 6 个知识库文件（`README.md`、`android_setup.md`、`home_widget.md`、`issues.md`、`ncpu_import.md`、`testing.md`）、4 个 Dart/测试文件、本报告。

---

## 9. 验收标准对照

| 验收标准 | 状态 |
| --- | --- |
| 同 id 的课程详情变化不再显示「与上次导入一致」 | 达成（单测 + widget 测试锁定） |
| `next` 中的手动课程不会进入差异 | 达成（2 个专门用例） |
| 现有写库行为、手动课程保护、安全边界不回退 | 未触碰数据库层；安全边界不变 |
| 自动测试全部通过，新增测试真实覆盖逻辑与 UI | 达成（111/111、13/13） |
| 当前状态文档之间不再互相矛盾 | 达成（9 个既有知识库文件同步，历史快照加注；TASK-037 又修正 `home_widget.md` 的旧接口名） |
| 未经授权不改 Git 历史、不推送、不操作真机生产数据 | 遵守 |

---

## 10. 后续处理（TASK-038）

- 用户后续明确指定了新提交邮箱；Agent 仅修改本仓库 Git 配置，没有改全局配置，也没有改写前 9 个提交。
- 本报告对应的 TASK-035–037 修复已以 `40c75cd` 提交并推送到 Gitee `master`；本地、tracking 与远端分支读回一致。
