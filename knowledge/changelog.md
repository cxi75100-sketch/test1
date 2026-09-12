# Changelog

## 2026-09-12 - Agent（TASK-044 满课一屏显示）

Changed:
- 移除每个上午、下午/晚间半区内部的纵向 `ListView`；上午固定按 1-2 / 3-4 节分两格，下半固定按 5-6 / 7-8 / 9-10 节分三格，课程按开始节次落位，满课无需上下翻动。
- 窄列课程卡改为紧凑三层信息：课程名、节次与统一作息时间、教室与教师；极矮视口使用缩放兜底，避免布局溢出。
- 将“新增课程”从右下悬浮按钮移至顶部操作区，末节课程不再被按钮遮挡；同时收回周视图底部的冗余留白。

Validation:
- `CONFIRMED` 先用上午 2 门、下午/晚间 3 门的 Widget 测试复现旧实现无法找到晚课；实现后确认五门课均渲染、两半等高且内部无 `Scrollable`。
- `CONFIRMED` `flutter analyze` 无问题，`flutter test` 132/132，Debug APK 构建成功并在 `ncpu_api36` 覆盖安装、启动；真实 Android 画面确认满课五张卡一屏可见，节次落位正确且无按钮遮挡，logcat 无 App 致命异常或布局溢出。
- 未修改课程数据；模拟器保留在整周页面供用户直接查看。

## 2026-09-12 - Agent（TASK-043 横向列式周课表）

Changed:
- 整周课表从纵向星期日程重做为横向七列周视图：一天一列，手机首屏约展示两列半，左右滑动查看完整一周。
- 每列上、下两半严格等高：上午承载 1-4 节，“下午 / 晚间”承载 5-10 节，保证第 9-10 节晚课不会丢失。
- 移除与列头重复的七天日期条，新增横滑提示、当天边框强调、每日课程计数和无课状态；窄列课程卡仍显示课程名、节次、统一作息时间、教室、教师，并可进入详情。

Validation:
- `CONFIRMED` 先将 Widget 回归改为目标结构并复现旧实现失败；完成后 `flutter analyze` 无问题、`flutter test` 132/132。
- `CONFIRMED` Debug APK 构建成功，在 `ncpu_api36` 覆盖安装和冷启动成功（2474 ms）；真实 Android 画面确认首屏列宽、上下等分、横向滑动及卡片密度正常，logcat 无 App 致命异常或布局溢出。
- 未修改课程数据；Computer Use 临时截图已清理。

## 2026-09-12 - Agent（TASK-042 整周上下午时段层级）

Changed:
- 整周课表在原有星期分组内部新增上午、下午、晚上三段，分别对应官方作息的 1-4 节、5-8 节、9 节以后；跨时段课程按开始节次唯一归类，不重复课程。
- 每个时段使用不同的图标、强调色、节次范围、分隔线与段间留白，让星期、时段、课程卡形成三级视觉层级；今日专栏和课程数据逻辑不变。

Validation:
- `CONFIRMED` 先新增 Widget 测试并复现缺少时段层级，完成实现后 `flutter analyze` 无问题、`flutter test` 132/132。
- `CONFIRMED` Debug APK 构建成功，在 `ncpu_api36` 覆盖安装和冷启动成功（2793 ms）；语义树确认上午/下午时段标题与对应内容已渲染，logcat 无 App 致命异常。
- 临时 UI dump 已清理，未修改模拟器或真机课程数据。

## 2026-09-12 - Agent（TASK-041 今日 / 整周双栏目）

Changed:
- 课表首页从单一整周纵向日程拆为“今日 / 整周”两个明确栏目，默认进入今日；今日仅显示设备当天课程并按节次排序，整周继续提供周切换、七天日期条与按日分组。
- 切回今日时复用 `SelectedWeek.goToCurrent()` 回到当前教学周；课程卡、详情、新增课程、学期过期提示和数据库查询接口保持不变。
- 今日专栏新增日期主卡、当日课程计数和独立空状态；栏目按钮包含选中语义，方便可访问性工具区分当前视图。

Validation:
- `CONFIRMED` `flutter analyze` 无问题；`flutter test` 131/131。
- `CONFIRMED` 412×915 匿名虚构课程渲染预览中，栏目切换、日期主卡、三张课程卡与浮动按钮无互相遮挡；临时预览与测试文件已清理。
- `CONFIRMED` Debug APK 构建成功，在 `ncpu_api36` 覆盖安装与冷启动成功（2739 ms）；真实 Android 字体画面确认今日空状态无遮挡，语义树确认双栏目选中态和整周内容，logcat 无 App 致命异常；临时截图/UI dump 已清理。
- `UNVERIFIED` 厂商真机手势体验留待下次设备验收。

## 2026-09-12 - Agent（TASK-040 Android 模拟器验证环境）

Added:
- 新增 Android 模拟器验证环境：安装 `emulator` 37.1.11.0 与 `system-images;android-36;google_apis;x86_64`，创建 AVD `ncpu_api36`（pixel_7 / API 36 / x86_64 / 2 GB RAM），并把时区校正为 `Asia/Shanghai`。
- 目的：让「必须造数据、改时钟、重启」的验收（TASK-019 小组件溢出/跨天重算、TASK-039 通知实际到点/重排/重启恢复）在模拟器上完成，避免再次向真机生产数据库注入数据。

Validation:
- `CONFIRMED` 硬件加速可用：`emulator -accel-check` → `WHPX(10.0.26200) is installed and usable`（退出码 0）；启动日志 `Windows Hypervisor Platform accelerator is operational`；GPU 为 NVIDIA RTX 5060 Laptop GPU（Vulkan）。**无需管理员启用 Windows 功能、无需重启。**
- `CONFIRMED` 设备与开机：`emulator-5554` / `sdk_gphone64_x86_64` / API 36 / x86_64，`sys.boot_completed=1`。
- `CONFIRMED` 项目链路：Debug APK 流式安装成功；冷启动 `Status: ok` / COLD / 3696 ms；logcat 无 `FATAL` / `AndroidRuntime` / `MissingPluginException` / `E/flutter`。
- `CONFIRMED` x86_64 原生依赖可用：`app_flutter/ncpu_timetable.sqlite` 建库成功；小组件载荷 `schemaVersion=1 / firstWeekMonday=2026-08-31 / totalWeeks=20` 写入成功且 `TimetableWidgetProvider` 已注册；语义树显示「第 2 周 / 共 20 周 · 本周 0 条安排 / 9-7–9/13」。
- `CONFIRMED` 启动器为 `com.google.android.apps.nexuslauncher`（Launcher3，支持小组件）。
- `CORRECTED` 上一轮依据 `Win32_OptionalFeature` 的 `HypervisorPlatform InstallState=2` 推断 WHPX 被禁用，并据此判断需要管理员启用 Windows 功能 + 重启；该推断**错误**。可靠依据只有模拟器自带的 `-accel-check`，此经验已记入 `knowledge/testing.md` 的 Tooling Note。
- 限制：模拟器**不替代**厂商启动器（OriginOS / ColorOS）下的 RemoteViews 排版、厂商省电策略下的后台与通知行为、arm64 原生库路径。
- 未操作真机、未修改业务源码、未改动 Git 提交。

## 2026-09-12 - Agent（TASK-014 Android 本地上课提醒）

Added:
- 新增 Android 本地课程提醒：默认关闭；首次由用户主动开启并申请通知权限；默认提前 15 分钟，可选 5/10/15/30 分钟。
- 新增纯 Dart 提醒计划器、系统通知适配器、协调器和 Riverpod 同步层；复用学期、课程、节次与 `CourseTimeService`，课程/学期/作息/偏好变化及 App 回前台时重建未来提醒。
- 新增 Android 通知权限、精确闹钟与开机恢复 receiver、单色状态栏图标；新增 `knowledge/notifications.md` 真机验收说明。

Safety and behavior:
- 精确闹钟未授权时明确降级为非精确提醒；通知权限拒绝或系统排程失败不保留错误的开启状态。
- 同时发生的监听刷新会合并为串行重排；只取消待触发通知，不清除已送达通知；未来提醒上限为 480 条。
- 设置沿用既有 `settings` 表，无数据库迁移；未记录账号、课程原始响应或会话信息。

Validation:
- `CONFIRMED` `flutter analyze` 无问题；`flutter test` 130/130；Android JVM 单测 13/13；Debug APK 构建成功。
- `CONFIRMED` APK 静态读回通知权限、两个调度 receiver 与通知图标。
- `CONFIRMED` 功能提交 `0342855` 已推送到 Gitee `master`，author/committer 均使用仓库级专用 QQ 邮箱。
- `UNVERIFIED` 当前没有 Android 设备连接，尚未验证系统权限弹窗、实际到点通知、精确闹钟降级效果与重启恢复；转 TASK-039。

## 2026-09-11 - Agent（TASK-038 切换仓库提交邮箱并推送修复）

- 按用户确认将 Git 作者邮箱仅配置在本仓库，保留全局配置与前 9 个提交历史不变。
- 提交前确认 17 个文件无邮箱明文、会话凭据赋值或构建产物；`git diff --cached --check` 通过。
- `flutter analyze` 无问题，`flutter test` 112/112，Android 原生单测在 `R:\android` 强制重跑成功。
- TASK-035–037 修复以 `40c75cd` 提交并推送到 Gitee `master`；本地 `HEAD`、`origin/master` 与远端 `refs/heads/master` 读回一致。

## 2026-09-11 - Agent（TASK-037 修复批量修改弹窗溢出）

- `ImportPreviewDialog` 改为有界单滚动区：最大高度为当前视口的 65%，差异明细、课程列表与底部提示统一滚动，确认/取消按钮固定在外部。
- 先新增 27 条修改、360×800 视口回归测试并复现失败，再实现修复；测试确认无布局异常、能滚到最后一条修改和列表底部、确认按钮始终可点。
- 修正 `home_widget.md` 中已删除的 `firstSemester` 为 `currentSemester`；修正 Zcode 交付报告“8 文件同步”为实际 9 个既有知识库文件。
- 验证：格式检查通过、`flutter analyze` 无问题、`flutter test` 112/112、Android 原生单测强制重跑 BUILD SUCCESSFUL。未操作真机、Git 历史或远端。

## 2026-09-11 - Agent（TASK-036 独立复核 TASK-035）

- 独立重跑通过：`flutter analyze`、`flutter test` 111/111、Android 原生单测强制重跑。
- 临时审查测试模拟 27 条课程同时修改；360×800 视口稳定出现 `RenderFlex overflowed by 698 pixels`，证明交付报告所称“理论上可能超高”是可复现 UI 缺陷。取证后已删除临时测试文件。
- TASK-035 判定为部分通过，暂不建议提交；需为差异明细增加有界滚动并补批量修改回归测试。
- 文档小问题：`home_widget.md` 仍引用旧接口 `firstSemester`；交付报告的知识库同步文件计数不一致。完整复核：`knowledge/review_2026-09-11_task035.md`。

## 2026-09-11 - Agent（TASK-035 执行 Zcode 修改任务书：导入差异 changed / manual 过滤 / 知识库同步）

Fixed:
- **导入差异漏报课程详情变化（TASK-033 P2-1）**：`ImportDiff` 只按 `Course.id` 判断，同 id 下课程名、教师、教室、周次等变化时预览仍显示「与上次导入一致」，而确认导入后数据库确实写入了新值。现在新增 `changed` 语义，并对同 id 课程逐字段按内容比较。
- **`diffImportedCourses` 只过滤 `previous` 侧手动课程（TASK-033 P3-1）**：`next` 中混入 `manual` 会被误计为新增，与函数注释和「手动课程不参与差异」的约定不一致。现在两侧都只取 `CourseSource.ncpu`。

Added:
- `ImportDiff.changed`（`List<CourseChange>`）；`CourseChange{previous, current, fields}` 同时保留旧课程与新课程；`CourseFieldChange{label, oldValue, newValue}` 描述单个字段的「旧值 → 新值」。`ImportDiff.isEmpty` 现在同时考虑 `added`、`removed`、`changed`。
- 逐字段比较覆盖：课程名、教师、教室、星期、节次（startSection/endSection）、周次、起止时间、备注；`weeks` 按列表内容逐项比较，不依赖对象或数组同一性。
- `test/import_diff_test.dart` 新增/重写 12 个用例（含 `next` 混入手动课程、内容相同但对象不同、同 id 单字段变化）。
- `test/import_preview_dialog_test.dart` 扩到 5 个用例（三类计数、修改项「旧值 → 新值」、空值占位符、只有修改时也不显示「一致」）。

Changed:
- 预览摘要改为「新增 N 条 · 移除 N 条 · 修改 N 条」；只有三类均为空时显示「与上次导入一致，没有新增、移除或修改。」；修改项按课程列出变化字段，空教师/空教室显示「（未填）」。
- `weekdayLabels` 从 `ImportPreviewDialog` 的私有常量提为 `import_diff.dart` 的公开常量，供课程行与差异明细共用。
- 未改动 `replaceImportedCourses` 的事务与来源隔离逻辑，未改 `import_login_page.dart`。

Docs:
- 同步知识库过期结论：`current_state.md`（里程碑、Current Blockers、Recommended Next Action、Handoff）、`tasks.md`、`home_widget.md`、`testing.md`、`issues.md`（ISSUE-007/008/010/012）、`ncpu_import.md`。小组件「渲染/添加/点击」不再标 BLOCKED；「即时刷新/缩放/溢出/跨天」保持未验证。
- `current_state.md` 与 `ncpu_import.md` 的 Git 提交数由 4 更正为当前 9。
- 保留历史测试快照，但为 TASK-021 的旧摘要文案加注「当时快照」。

Validation:
- `CONFIRMED` `flutter analyze`（`R:\`）：No issues found。
- `CONFIRMED` `flutter test`：111/111 passed（上轮 103，本轮 +8）。
- `CONFIRMED` `gradlew :app:testDebugUnitTest --rerun`：13 tests / 0 failures / 0 errors / 0 skipped。
- 未连接设备，未做新的真机验证；未直接修改真机生产数据库。
- 安全边界：未提交、未推送、未重写 Git 历史；公开提交邮箱问题仅报告，等待用户给出目标邮箱。
- 交付报告：`knowledge/zcode_fix_report_2026-09-11.md`，包含逐文件改动理由、差异模型说明、测试矩阵、**未改动清单及原因**、未验证项与验收标准对照。

## 2026-09-11 - Agent（TASK-034 Zcode 修改任务书）

- 将 TASK-033 审查问题整理成可执行任务书：导入差异增加 `changed`、双侧过滤手动课程、同步知识库状态、明确公开邮箱需用户决策。
- 写明测试矩阵、验收标准及安全边界：不改真机生产数据库、不泄露教务身份/会话数据、不重写 Git 历史、不覆盖已有未提交审查文件。
- 文件：`knowledge/zcode_fix_request_2026-09-11.md`；本轮未修改业务源码。

## 2026-09-11 - Agent（TASK-033 Zcode / Gitee 仓库审查）

- 审查基线收尾后的 7 个提交（`938c78c..6b321a4`），确认本地、跟踪分支与 Gitee 远端 `master` 均指向 `6b321a4`。
- 验证：`flutter analyze` 通过，`flutter test` 103/103，Android 原生单测构建成功；启发式扫描未发现已提交的密码、Token、Cookie、私钥、数据库或 APK。
- 报告发现：导入差异摘要漏报同 id 的课程详情变化；知识库多处状态互相矛盾；公开提交元数据暴露个人 Gmail；`diffImportedCourses` 的 `next` 未过滤手动课程。
- 未修改业务源码。完整报告：`knowledge/review_2026-09-11_zcode_gitee.md`。

## 2026-09-11 - Agent（小组件溢出验证失败并回退，记录编码陷阱）

Incident（Agent 操作失误，非代码缺陷）：
- 为验证小组件「还有 N 门课」溢出分支，本 Agent 用 Git Bash 的 `sqlite3.exe` 往真机库注入了 6 条含中文的临时课。**Windows 控制台为 GBK，入库字节不是合法 UTF-8**，Drift 读 TEXT 列时抛 `FormatException: Missing extension byte (at offset 5)`，`watchCourses` 整体失败：App 课表页显示「课表加载失败」，小组件因读同一份数据而静默降级、不再推送。
- `integrity_check` 与行数均正常，所以**故障库在 SQL 层面看起来完全健康**，靠 App 的错误文案才定位到编码问题。

Resolution：
- 写回改动前的库备份，故障消失。`CONFIRMED` 25 秒内恢复：App 语义节点由 6（错误态）恢复为 21，显示「第 2 周 · 共 20 周 · 本周 13 条安排」；小组件恢复「第 2 周 · 周五」+ 3 行课程，`mViewMode == VIEW_MODE_ERROR` 归零，载荷 27 条且无临时数据残留。
- 临时文件与注入数据已全部清除；课程未丢失（27 条 ncpu 不变）。

Added:
- `knowledge/testing.md` 的 Tooling Note 新增「真机数据库注入的编码陷阱」：只注入 ASCII 值或改用 Python 写库；`integrity_check` 不能证明 App 可读；改库前必备份；写入前须确认进程已真正退出（否则 SQLite 页缓存会返回旧数据）。

Status: TASK-019 的「还有 N 门课」溢出分支**仍未验证**，本轮尝试已回退；其余小组件验收项（添加、渲染、点击打开 App）保持已确认。

## 2026-09-11 - Agent（TASK-019 小组件真机验收；修复 RemoteViews 布局缺陷）

Fixed:
- **小组件在主屏显示「载入小窗口时出现问题」**（ISSUE-013）。根因：`widget_timetable.xml` 的分隔线与 `widget_row.xml` 的课程色条使用了 `android.view.View`，而 RemoteViews 的 LayoutInflater 只允许带 `@RemoteView` 注解的类（`View` 与 `ViewGroup` 都没有）。两处改为无文字的 `TextView`，Kotlin 侧无需改动。
- 该缺陷此前无法从日志定位：启动器吞掉了 `InflateException`，logcat 里只有 `inflateAsync` 紧接 `mViewMode == VIEW_MODE_ERROR`。

Added:
- `knowledge/home_widget.md` 新增「布局硬约束」：明确列出 RemoteViews 允许的控件类型、禁用 `View`/`ViewGroup`，并给出 `javap` 自检命令与排查手段。

Changed:
- ISSUE-011 关闭：`dumpsys appwidget` 的 `min=(46081x28161)` 是 dp 值与标志位的打包输出（`180<<8|1`、`110<<8|1`），即 180dp × 110dp，并非异常；此前"全为 0"只是 provider 信息尚未被系统加载。

Validation:
- `CONFIRMED` Debug APK 构建并安装成功；修复后 `mViewMode == VIEW_MODE_ERROR` 计数归零。
- `CONFIRMED` 主屏语义树实测：表头「第 2 周 · 周五」与设备日期 2026-09-11 一致；当天 3 门课全部命中；时间 `10:25-11:55` / `14:00-15:30` / `15:55-17:25` 与官方作息一致。
- `CONFIRMED` 小组件可通过启动器的添加小组件流程找到并放置（TASK-019 步骤 3、4 完成）。
- `BLOCKED`（当时快照）缩放行为、跨天重算、点击打开 App、数据变更后即时刷新仍未验证（TASK-019 步骤 5-8）；其中点击打开 App 已在后续真机复验确认。

## 2026-09-11 - Agent（TASK-021 教务导入真机端到端验收通过）

Changed:
- 导入预览的「相对上次导入」区块改为**始终显示**：差异为空时明示「与上次导入一致，没有新增或移除」。此前"差异为空就隐藏"会让常见情况（教务数据未变）下整个功能不可见，既看不出比较跑过，也让验收无从下手。
- 新增 `test/import_preview_dialog_test.dart` 锁定三种状态：无旧数据不显示区块、差异为空明示"一致"、有增删时显示条数并列出被移除课程。

Validation:
- `CONFIRMED` `flutter analyze` 无问题；`flutter test` 103/103 passed。
- `CONFIRMED` 用户在 OnePlus PLC110 上本人登录教务并完成导入；预览显示 27 条，差异区块显示"无变化"。
- `CONFIRMED` 导入后 `source=ncpu` 的 id 集合指纹与导入前完全相同，替换等价、无丢失。
- `CONFIRMED` 手动课程保留：rowid 由 `1..27` 变为 `29..55`，插入起点为 29 说明导入时 rowid 28（用户先加的手动课）仍存在；若被误删，重新插入会从 1 开始。
- `CONFIRMED` 学期记录未被改动，SQLite `integrity_check=ok`。
- 观测方法修正（重要）：**不能用 SQLite `change counter` 判断"是否发生过导入"** —— `ensureDefaults()` 每次冷启动都会幂等写 `section_times`，实测每启动一次 counter +1（19→20→21）。可靠信号是 `courses` 的隐式 rowid 位移。
- 隐私：验收用的数据库副本与小组件载荷副本已全部删除；未记录账号、Cookie、Session 或 Token。

## 2026-09-11 - Agent（TASK-029 导入体验；TASK-030 学期逻辑卫生；TASK-031 学期日期提示）

Added:
- `ImportSessionCleaner`：离开导入页时清理 WebView HTTP 缓存。
- `diffImportedCourses` 纯函数：按课程 id 求上一次与本次导入的新增/移除，只比较教务来源课程。
- `SemesterService.termStatus` 与 `TermStatus{before,within,after}`；`SemesterService.dateFor`；`defaultTotalWeeks` 常量。
- 课表页周概览下方的学期日期失效提示条（点击跳转设置页）。

Changed:
- 导入预览新增「相对上次导入：新增 N 条 · 移除 M 条」，并列出将被移除的课程，避免在按下确认前不知道教务删了课。
- `import_login_page.dispose()` 先清缓存再销毁 controller，并清空内存中的课表原始响应。**按用户决定保留 Cookie 与 WebStorage**（下次导入免登录），取舍记入 DEC-010。
- `timetable_page` 的私有 `_dateFor` 改为调用 `SemesterService.dateFor`，日期算法收敛到一处。
- `totalWeeks: 20` / `?? 20` 两处硬编码改用 `defaultTotalWeeks`。
- `AppDatabase.firstSemester()` 更名 `currentSemester()`：它按 `firstWeekMonday` 倒序取第一条，是"最近开始的学期"而非"最早"，原名已造成过一次误读。

Validation:
- `CONFIRMED` `flutter analyze`（`R:\`）：No issues found；`flutter test`：100/100 passed（较上轮 +16）。
- `CONFIRMED` 新增测试覆盖：`termStatus` 的学期前/最后一天/结束后边界、`dateFor` 不夹取周次、导入差异（首次全为新增、无变化、单侧增删、手动课程不参与、改名不算差异）、清理器平台不可用时抛异常、课表页提示条在学期前后出现/在学期内不出现。
- `CONFIRMED` Debug APK 构建成功（2026-09-11，增量 18.8 s）。
- `CONFIRMED`（TASK-032，设备重新接入后）清缓存真机可归因生效：教务页加载后 `cache/WebView/Default/HTTP Cache` 2649 KB → 离开导入页后 65 KB（另一轮 4437 → 65 KB）；对照实验中 `am force-stop` 强杀进程（不经 `dispose`）后缓存保持 1417 KB 不变，排除“WebView 销毁自身清理”的伪因果；Cookies 24 KB 与 Local Storage 均保留。
- `CONFIRMED` 首页显示「第 2 周 · 共 20 周 · 本周 13 条安排」，学期内在范围故提示条不出现；越界态排版改由真机同宽视口的 widget 测试覆盖，未改写真机学期数据。
- 观察记录（易误判）：WebView 首次初始化时 `app_webview/` 会由 4318 KB 自行降到 234 KB，与本轮改动无关，勿当作清缓存效果。
- `UNVERIFIED` 导入预览「新增/移除」差异行的真机显示，需在 TASK-021 真实导入时确认。

## 2026-09-11 - Agent（TASK-022 建立 Git 基线）

Added:
- 首个基线提交 `5509a85`（`master`，351 文件 / 43324 行），涵盖源码、测试、知识库与 `third_party` 固化插件。
- 远端 `origin` 指向 `https://gitee.com/chenxihh/test_c.git`。

Changed:
- `.gitignore`：整体排除本地 Obsidian vault `/课表知识库/`（知识库正文仍由 `/knowledge` 入库），新增 `/tmp/`。
- `android/.gitignore` 新增 `/build/`——原 `/build/` 只锚定仓库根目录，导致 `android/build/reports/` 下的 Gradle 产物会被误提交。
- `knowledge/testing.md` 移除两台真机的硬件序列号，仅保留机型。

Validation:
- `CONFIRMED` 提交前扫描 351 个待提交文件：无 keystore / key.properties / .env / google-services.json；无 `sk-` / `AKIA` / `ghp_` / `glpat-` / 私钥块等密钥格式；`lib`、`test`、`knowledge`、`android` 内无硬编码凭据、无 Bearer / Authorization。项目本身不使用任何 API key。
- `CONFIRMED` 提交后工作区干净（`git status` 无输出）。
- `CONFIRMED` 推送成功：`master` → `origin/master`，远端 `HEAD` 与本地 `HEAD` 均为 `938c78c`。首次推送因 GCM 回退到 `git config user.name`（「c jh」→ `cjh`）而认证失败，用户交互式提供 Gitee 私人令牌后成功；已设 `credential.username=chenxihh` 避免再次猜错。
- 注意：仓库为公开仓库，推送到 Gitee 后源码与知识库对外可见。

## 2026-09-11 - Agent（TASK-028 默认学期起点改用校历；TASK-027 第二台真机安装）

Added:
- `lib/services/semester_service.dart` 新增 `officialFirstWeekMonday`（2026-08-31），作为全新安装的默认学期起点。

Changed:
- `AppDatabase.ensureDefaults()` 不再把“安装当天所在周的周一”当作第一周周一。旧逻辑会让第 2 周及以后安装的设备全部少算一周，并使单双周、限定周次课程错位。
- 已存在的学期记录不受影响：`ensureDefaults()` 仅在无学期记录时插入，用户设置在“设置 → 学期设置”中仍可覆盖。
- `test/app_flow_test.dart` 的周六课程用例改为按同一规则取当前周，不再依赖运行日期。

Validation:
- `CONFIRMED` `flutter analyze`（`R:\`）：No issues found；`flutter test`：84/84 passed（新增 1 个默认学期起点测试）。
- `CONFIRMED` 新增测试断言默认 `firstWeekMonday == 2026-08-31`，且 2026-09-10 的 `currentWeek` 为 2。
- `CONFIRMED` Debug APK 构建成功（2026-09-11 00:05，206,352,868 B，SHA1 `b24127bb6edb69a50a1c59b90ffea42651030725`）。
- `CONFIRMED` OnePlus PLC110 / Android 16 / API 36 全新安装成功，冷启动无 Flutter/Android 致命异常。
- `CONFIRMED` 该机数据库 `first_week_monday` 已定向修正为 2026-08-31（`integrity_check=ok`，27 条课程记录未变），覆盖安装后小组件载荷同步为 `firstWeekMonday=2026-08-31`、`totalWeeks=20`。
- `UNVERIFIED` 该机首页“第 2 周”文案未截屏确认：截屏时手机正处于前台使用中，画面被其他 App 浮窗覆盖，相关截图已立即删除。

## 2026-09-10 - Agent（TASK-026 教学周历官方作息）

Added:
- 新增 `CourseTimeService` 和 2026-2027 教学周历专题页，集中维护 10 节官方作息与教学楼分流规则。
- 课程卡在节次下显示实际起止时间；课程详情和 Android 小组件复用同一解析结果。

Changed:
- 默认节次从旧占位时间更新为教学周历官方时间；App 启动时幂等同步，已有课程数据不变。
- 第 3/4 节按教室文本区分：明志楼、明德楼、至善楼为 10:15-11:45，其他教学场所为 10:25-11:55。

Validation:
- `CONFIRMED` `flutter analyze`：No issues found；`flutter test`：83/83 passed；Debug APK 构建成功。
- `CONFIRMED` vivo V1981A 覆盖安装与冷启动成功，真机卡片时间排版无溢出，logcat 无致命异常。
- `CONFIRMED` 小组件载荷脱敏核对：指定教学楼与其他场所的第 3-4 节课程分别全部命中正确时间范围。

## 2026-09-10 - Agent（TASK-025 真机验收与教学周纠正）

Changed:
- 根据用户确认，将真机当前学期的开学第一周周一定向修正为 `2026-08-31`；未修改课程记录，也未把该日期硬编码为所有未来学期的默认值。
- 小组件快照随 App 冷启动同步更新，Android 与 Flutter 共用正确学期基准。

Validation:
- `CONFIRMED` vivo V1981A / Android 12 覆盖安装最新版 Debug APK 成功，两次 force-stop 后冷启动成功。
- `CONFIRMED` 首页显示“第 2 周”及 9/7–9/13，1080×2408 真机视觉和 UIAutomator 边界未见溢出、遮挡或中文字体异常。
- `CONFIRMED` 课程跨冷启动保留；SQLite `quick_check=ok`；logcat 无 Flutter/Android 致命异常。
- `CONFIRMED` `TimetableWidgetProvider` 已注册，小组件载荷包含 `firstWeekMonday=2026-08-31`。
- 验收完成后删除本地数据库副本、截图和 UI dump，避免留存课程与教师信息。

## 2026-09-10 - Agent（TASK-024 独立 Obsidian 仓库）

Added:
- 新建 Obsidian 仓库“课表知识库”：`D:\桌面\课程表\课表知识库`。
- 仓库入口 `README.md`，集中链接当前状态、任务、架构、教务导入、测试和变更日志。
- `项目知识` NTFS Junction 指向 `D:\桌面\课程表\knowledge`，确保 Obsidian 与项目 Agent 阅读同一份知识文件。

Changed:
- 将原数模知识库的 `项目/南工课表.md` 移入新仓库 `历史/数模知识库旧索引.md`，并从数模知识库项目索引移除。
- `.gitignore` 排除 Obsidian 本机工作区状态与 `项目知识` Junction，避免 Git 重复遍历同一批知识文件。

Validation:
- `CONFIRMED` Obsidian 配置注册表中同时存在两个独立 vault：`课表知识库` 与 `数模知识库`，路径互不包含。
- `CONFIRMED` 新仓库 `.obsidian`、README、历史页和 `项目知识` Junction 均存在；Junction 目标为项目 `knowledge` 目录。
- `CONFIRMED` 数模知识库内已无“南工课表/课程表/课表知识库”引用。

## 2026-09-10 - Agent（TASK-023 UI 重做）

Changed:
- `AppTheme` 统一为轻量 Material 3 视觉：低对比背景、圆角白色表面、聚焦输入框、统一按钮与悬浮按钮。
- 课表首页从五列压缩表格改为移动端纵向周日程：渐变周概览、七天日期条、按天分组课程列表，并补齐周六/周日展示。
- `CourseCard` 改为全宽信息卡，课程色仅作为识别条与节次徽标，补充教室、教师和节次信息。
- 设置页改为学校状态卡 + “课表 / 偏好与隐私 / 数据管理”分组；课程详情页改为课程主卡与结构化信息卡。

Validation:
- `CONFIRMED` `flutter analyze`：No issues found。
- `CONFIRMED` `flutter test`：78/78 passed；新增周日课程及课程元数据展示测试。
- `CONFIRMED` 生成并人工检查 412×915 Flutter 渲染预览；布局、间距、卡片层级和横向日期条正常。
- `BLOCKED` 当前无 ADB 设备，中文系统字体、不同屏幕密度与真实触控手感仍待真机确认。

## 2026-09-10 - Agent（TASK-012 + TASK-013 + TASK-020 收口）

Confirmed:
- 用户真机脱敏采集确认南昌工学院使用正方教务；核心课表接口为 `POST /jwglxt/kbcx/xskbcx_cxXsgrkb.html?gnmkdm=N253508`，`kbList` 的星期/节次/周次/课程/场地等关键字段已确认。
- Codex 中“课程表”是独立项目 `D:\桌面\课程表`；“数模”是另一项目 `D:\桌面\数模`。课程表状态不再同步到数模知识库。

Added:
- Debug 同源 XHR/fetch 脱敏采集链路、采集页与自动保存；原始课表响应使用独立桥接并只留内存。
- `NcpuTimetableParser`、`SchoolAdapter.parseTimetable` / `NcpuAdapter` 正式解析实现。
- `ImportPreviewDialog` 与“预览确认后仅替换 `ncpu` 来源课程”的写入流程。
- TASK-021 真机教务导入端到端验收工单。
- ISSUE-012 / TASK-022：记录仓库尚无首个 commit、所有文件均为 untracked，待确认提交边界后建立基线。

Changed:
- 按实际源码统一更新 README、当前状态、任务、架构、教务导入、测试和问题文档，移除“接口未知”“导入尚未开始”“adapter 只返回未发现”等过期描述。

Validation:
- `CONFIRMED` `flutter analyze`（`R:\`）：No issues found。
- `CONFIRMED` `flutter test`：77/77 passed。
- `CONFIRMED` `gradlew :app:testDebugUnitTest`：BUILD SUCCESSFUL；13 tests / 0 failures / 0 errors / 0 skipped。
- `BLOCKED` 2026-09-10 22:33 +08:00 `adb devices -l` 为空；当前版本的导入端到端与小组件主屏表现仍待真机验收。

## 2026-09-10 - Agent (TASK-018)

Added:
- `lib/features/widget/services/widget_payload_builder.dart`：整周课表快照 JSON（协议 `schemaVersion = 1`），含学期起点、总周数、全部课程与节次时间。
- `lib/features/widget/services/widget_bridge.dart`：MethodChannel 封装（channel 可注入），平台异常统一降级为 `false`。
- `lib/features/widget/providers/widget_sync_providers.dart`：`allCoursesProvider` / `sectionTimesProvider` / `WidgetSync`，监听课表变化并合并重复推送。
- `lib/core/theme/course_colors.dart`：课程配色表从 `course_card.dart` 抽出，小组件复用同一取色规则（`courseColorFor`）。
- `android/.../widget/`：`WidgetPayload`（纯数据类 + `CivilDate` EpochDay 算法）、`WidgetPayloadParser`（org.json，无第三方依赖）、`WidgetScheduleCalculator`（纯 Kotlin 周次/星期计算）、`WidgetRenderer`（RemoteViews）、`TimetableWidgetProvider`、`WidgetPreferences`、`WidgetChannel`。
- `android/app/src/main/res/`：`layout/widget_timetable.xml`、`layout/widget_row.xml`、`xml/timetable_widget_info.xml`、`drawable/widget_background.xml`、`values/strings.xml`、`values/colors.xml`、`values-night/colors.xml`。
- `android/app/src/test/.../WidgetScheduleCalculatorTest.kt`：13 个 JVM 单元测试（周次边界、星期映射、过滤排序、时间来源）。
- `test/widget_payload_builder_test.dart`（5 个）、`test/widget_sync_test.dart`（4 个）。
- `knowledge/home_widget.md` 专题文档。

Changed:
- `lib/app.dart`：`TimetableApp` 改为 `ConsumerStatefulWidget`，保持 `widgetSyncProvider` 存活并在 App 回到前台时补推快照。
- `lib/core/database/app_database.dart`：新增 `watchSectionTimes()` 与 `allSectionTimes()`，补齐节次时间读接口（此前只写不读）。
- `android/.../MainActivity.kt`：覆写 `configureFlutterEngine` 注册 MethodChannel，保存载荷后刷新所有小组件实例。
- `android/app/src/main/AndroidManifest.xml`：新增 `exported="false"` 的 `TimetableWidgetProvider` receiver，**未新增任何权限**。
- `android/app/build.gradle.kts`：新增 `testImplementation("junit:junit:4.13.2")`。

Validation:
- `CONFIRMED` `flutter analyze`（`R:\`）：No issues found。
- `CONFIRMED` `flutter test`：53/53 passed（原 44 + 新增 9）。
- `CONFIRMED` `gradlew :app:testDebugUnitTest`：13 tests / 0 failures / 0 errors / 0 skipped。
- `CONFIRMED` `flutter build apk --debug` 成功；APK 206,292,551 B，SHA256 `8f1847a6904f72aace89cea379c737c8319641828b60b57d5627f9b3de99ba2a`；aapt2 校验合并后清单含 `TimetableWidgetProvider`（exported=false、APPWIDGET_UPDATE、`android.appwidget.provider` 元数据），权限仍只有 INTERNET + DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION，`widget_*` 资源已打包。
- `BLOCKED` 小组件真机渲染、添加到主屏、缩放、跨天重算、点击打开 App 均无设备可验证。

## 2026-09-10 - Agent (TASK-017)

Changed:
- `ImportLoginPage` 增加阻断式风险确认门：默认不创建 WebView，明确候选 host 尚未真机核验且 HTTP 未加密；用户主动确认后才加载。
- 移除绿色 verified 状态和“学校官方页面”断言，加载前后持续使用候选页面/HTTP 警告措辞。
- `SchoolAdapter.importCourses()` 与 `NcpuAdapter` 移除尚无真实协议依据的裸 Cookie 参数。
- `NcpuSchoolConfig.accepts(Uri)` 改为 scheme + host 联合校验，统一 adapter 与 NavigationPolicy 的判断。
- `pubspec.yaml` 用 path override 固定项目内 `third_party/flutter_inappwebview_android` 1.1.3；全局 Pub Cache 已恢复原状。

Added:
- `third_party/flutter_inappwebview_android/`：保留稳定版包源码、LICENSE 与元数据，仅修正 AGP 9 不支持的两个 ProGuard 默认文件引用。
- `third_party/README.md`：记录来源、许可证、本地差异和升级规则。
- `test/import_login_page_test.dart`：确认风险门默认状态可在无平台通道环境测试。
- NcpuAdapter 危险 scheme + 白名单 host 拒绝用例。

Validation:
- `CONFIRMED` `flutter analyze`：No issues found。
- `CONFIRMED` `flutter test`：44/44 passed。
- `CONFIRMED` 恢复全局 Pub Cache 原始配置后执行 `flutter clean` → `flutter pub get` → `flutter build apk --debug` 成功；解析日志明确使用项目内 Android 插件。
- `CONFIRMED` APK 174,296,188 B，SHA256 `da582782b6b10f4e165e61d9b35fb6c66a4b8d19e1920fdcf53911b501d4a7eb`；v2 签名、SDK/包名/最小权限清单静态校验通过。
- `BLOCKED` WebView 真机渲染、风险确认后页面加载和真实登录仍无设备可验证。

## 2026-09-10 - Agent (TASK-010 + TASK-011)

Added:
- `lib/features/import/adapters/school_adapter.dart`：SchoolAdapter 抽象类 + sealed ImportResult 层级（ImportSuccess / ImportInterfaceNotYetDiscovered / ImportError）。
- `lib/features/import/adapters/ncpu_adapter.dart`：NcpuAdapter 骨架，`importCourses()` 返回 `ImportInterfaceNotYetDiscovered`，不猜测真实接口。
- `lib/features/import/services/navigation_policy.dart`：纯 Dart 域名白名单导航策略，11 个单元测试。
- `lib/features/import/pages/import_login_page.dart`：flutter_inappwebview InAppWebView 安全登录页，shouldOverrideUrlLoading 拦截非白名单域名，安全提示横幅 + 加载进度条 + 返回/刷新按钮 + "尝试导入课表"按钮。
- `lib/features/import/providers/import_providers.dart`：Riverpod adapter/schoolConfig provider。
- `android/app/src/main/res/xml/network_security_config.xml`：仅对 `jwxt.ncpu.edu.cn` 放行 HTTP cleartext。
- `test/navigation_policy_test.dart`：11 个测试（合法/非法 URL、host/scheme 校验、null 处理）。
- `test/ncpu_adapter_test.dart`：5 个测试（loginUrl、importCourses 返回值、sealed 类型）。
- `test/import_entry_test.dart`：2 个 widget 测试（设置页入口存在 + 导航到 WebView 页）。

Changed:
- `pubspec.yaml`：新增 `flutter_inappwebview: ^6.1.5` 依赖。
- `lib/models/school.dart`：新增 `NcpuSchoolConfig`（allowedHosts + allowedSchemes）。
- `lib/core/router/app_router.dart`：新增 `/settings/import-login` 路由。
- `lib/features/settings/pages/settings_page.dart`：新增"教务导入"入口 ListTile。
- `android/app/src/main/AndroidManifest.xml`：添加 `android:networkSecurityConfig` 属性。
- `ios/Runner/Info.plist`：NSAppTransportSecurity 域名级例外（`NSExceptionAllowsInsecureHTTPLoads` for `jwxt.ncpu.edu.cn`）。
- `C:\Users\ninan\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_inappwebview_android-1.1.3\android\build.gradle`：手动 patch `proguard-android.txt` → `proguard-android-optimize.txt`（AGP 9.1.0 兼容，详见 ISSUE-006）。

Validation:
- `CONFIRMED` `flutter analyze`：No issues found（在 `R:\` 下）。
- `CONFIRMED` `flutter test`：42/42 passed（17 原始 + 25 新增）。
- `CONFIRMED` `flutter build apk --debug`：产物 202,953,844 B（≈193.55 MiB），SHA256 `381e5d810f8074fea8ba4ef9410a42f2abd55b23cd231ffa369858494a4b67be`。
- `BLOCKED` WebView 渲染：无设备可验证 InAppWebView 实际表现。

Notes:
- 未修改任何已有业务逻辑（课程 CRUD、持久化、周课表、学期设置）。
- 未猜测真实教务接口，NcpuAdapter 仅返回"接口尚未确认"。
- flutter_inappwebview 插件 proguard 与 AGP 9.1.0 不兼容，需手动 patch（详见 ISSUE-006 / DEC-006）。
- HTTP cleartext 最小化策略：仅对学校已知域名放行，不做全局例外（详见 DEC-007）。
- 下一步：TASK-012（脱敏 Debug 接口发现工具）→ TASK-013（parser + 导入预览）→ TASK-014（本地通知）。

## 2026-09-10 - Agent

Changed:
- 接收并独立复核 Android 工具链交接报告。
- 将 `knowledge/android_setup.md` 从安装前快照更新为 TASK-015 已完成状态。

Validation:
- 本轮 `flutter doctor -v` 再次确认 Android toolchain 全绿、licenses 全部接受。
- 本轮确认 APK 大小与 SHA256 与交接报告一致。
- 本轮重新运行 `apksigner` 与 `aapt2`，v2 签名及 manifest/SDK/权限信息一致。
- 本轮 `adb devices -l` 仍为空；TASK-016 保持 BLOCKED。

Notes:
- 当前 Codex 宿主进程继承的是更新前环境变量；用户级变量已持久化，新启动终端后生效。

## 2026-09-10 - Android 工具链 Agent

Added:
- Windows 本机 Android 开发工具链（全部装在 D 盘，未占用系统盘）：
  - Eclipse Temurin JDK 17.0.20.1+1 → `D:\Tools\jdk-17`（zip 版，SHA256 已校验）。
  - Android commandline-tools 19.0 → `D:\Tools\android-sdk\cmdline-tools\latest`。
  - platform-tools 37.0.1、platforms;android-36 rev2、build-tools;36.0.0、ndk;28.2.13676358。
  - 构建期间 Gradle/AGP 自动补装 platforms;android-35 rev2 与 cmake;3.22.1。
- 用户级环境变量（PowerShell `[Environment]::SetEnvironmentVariable`）：`JAVA_HOME=D:\Tools\jdk-17`、`ANDROID_HOME=D:\Tools\android-sdk`、`ANDROID_SDK_ROOT=D:\Tools\android-sdk`；PATH 追加 `%JAVA_HOME%\bin`、`%ANDROID_HOME%\platform-tools`、`%ANDROID_HOME%\cmdline-tools\latest\bin`、`D:\Tools\flutter\bin`。
- `flutter config --android-sdk D:\Tools\android-sdk --jdk-dir D:\Tools\jdk-17`；`flutter doctor --android-licenses` 全部接受。
- `subst R: "D:\桌面\课程表"` 通过 `powershell -EncodedCommand` (Base64 UTF-16LE) 建立，规避 Git Bash → cmd 的 UTF-8/GBK 编码问题。
- 首份 Debug APK：`D:\桌面\课程表\build\app\outputs\flutter-apk\app-debug.apk`，170,936,973 B（≈163.02 MiB），SHA256 `1daf867fc31a15f053c1ef17f69f109110bcd061f1e85a6e1ccd632c1222aa06`，三 ABI（arm64-v8a / armeabi-v7a / x86_64）。
- 知识库新增 `ISSUE-004`（Android 真机 BLOCKED）与 `ISSUE-005`（sdkmanager 反斜杠转义问题已固化规避）。

Changed:
- `knowledge/current_state.md`：Android 工具链从 BLOCKED 改为 CONFIRMED；里程碑描述更新；Important Context 补充所有路径、版本与规避手段；Handoff 全面重写。
- `knowledge/tasks.md`：TASK-015 从 Now 移到 Done（含验收证据）；TASK-016 拆到新的 Blocked 节，明确等待条件；Now 变为空。
- `knowledge/issues.md`：ISSUE-002 从 Open 改为 Partially Resolved（Android 已解决、iOS 保持 Open）并附完整 Resolution Evidence；ISSUE-003 补充 EncodedCommand 规避证据；新增 ISSUE-004 与 ISSUE-005。
- `knowledge/testing.md`：Passed 段追加 `flutter doctor -v` Android toolchain 全绿 + APK 静态校验（apksigner v2 + aapt2 badging + 权限 + ABI + APK 结构）；Manual Testing 明确 BLOCKED 事实与复现命令；Tooling Note 补充 EncodedCommand、单引号 Windows 路径、setx 引号陷阱、磁盘占用等 5 条本轮经验。
- Obsidian 项目页 `D:\桌面\数模\mcm2026\docs\数模知识库\项目\南工课表.md`：Android 工具链状态从 BLOCKED 改为 CONFIRMED；下一步从"完成 Android SDK 配置"改为"接入真机做 TASK-016 + 启动里程碑 2 业务开发"。

Fixed:
- 首次 sdkmanager 调用因 bash 双反斜杠转义把组件写到 `D:\Toolsandroid-sdk\`；已合并回 `D:\Tools\android-sdk\` 并固化"单引号 Windows 路径"调用方式（详见 ISSUE-005）。
- setx 传值把双引号也保存进环境变量（`JAVA_HOME="D:\Tools\jdk-17"`）；改用 PowerShell API 修正为不带引号的字面量。

Validation:
- `CONFIRMED` `flutter doctor -v`：Flutter 3.47.2 ✓ / Windows 11 25H2 ✓ / **Android toolchain ✓ (SDK 36.0.0, Platform android-36, build-tools 36.0.0, Temurin 17.0.20.1+1, All Android licenses accepted)** / Chrome ✓ / Connected device (Windows/Chrome/Edge) ✓ / Network ✓；Visual Studio `[X]` 属预期（V1 不做 Windows 桌面）。
- `CONFIRMED` `flutter pub get`：Got dependencies in `R:\`；10 个包有约束内更新可用（未升级）。
- `CONFIRMED` `flutter analyze`：No issues found（10.6 s，在 `R:\` 下）。
- `CONFIRMED` `flutter test`：17/17 passed。
- `CONFIRMED` `flutter build apk --debug`：300 s（Gradle `assembleDebug` 295.5 s），产物路径 + 大小 + SHA256 已记录。
- `CONFIRMED` `apksigner verify --verbose --print-certs`：Verifies；v2 scheme=true；Signer CN=Android Debug；RSA 2048；证书 SHA-256 `9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3`。
- `CONFIRMED` `aapt2 dump badging`：package=`cn.edu.ncpu.timetable.ncpu_timetable`，versionCode=1，versionName=1.0.0，compileSdk=36，minSdk=24，targetSdk=36，label=`南工课表`，权限仅 INTERNET + DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION（无 CAMERA / LOCATION / CONTACTS / STORAGE 等敏感权限）。
- `BLOCKED` `flutter run`：`adb devices` 空，`flutter devices` 无 Android 条目，未安装 emulator，未启动 `flutter run`。

Notes:
- 未修改任何业务代码、教务逻辑或安全边界；未安装 Android Studio；未安装 Visual Studio C++；未安装 emulator + system-image。
- 本轮工具链磁盘占用：SDK ≈ 2.6 GB + JDK ≈ 304 MB + 下载缓存 ≈ 333 MB（保留在 `D:\Tools\downloads\` 供后续复用/校验，可手动清理）。
- TASK-015 验收通过；TASK-016 保持 BLOCKED，等待用户接入 Android 真机或授权安装 emulator。
- 下一步建议：业务 Agent 可并行进入 TASK-010（NcpuSchoolConfig + SchoolAdapter 骨架）与 TASK-011（安全受限 WebView 登录页），严格遵守 `AGENTS.md` 安全边界。

## 2026-09-09 - Agent

Added:
- 项目级 `AGENTS.md`。
- 完整知识库目录和首版计划。

Changed:
- 无。

Fixed:
- 无。

Validation:
- `CONFIRMED` Flutter 3.47.2 / Dart 3.13.2 工具链可启动。

Notes:
- 下一步初始化 Flutter 工程并实现里程碑 1。

## 2026-09-09 - Agent

Added:
- Flutter Android/iOS 工程和当前依赖。
- Course、Semester、SectionTime、NcpuSchoolConfig。
- Drift 四表数据库、默认数据和课程 CRUD/导入替换事务。
- Riverpod 数据层、GoRouter 路由、周课表、课程表单、详情和学期设置页。
- 学期名称、开学周一、总周数设置和清空当前学期课程入口。
- 周次解析器、当前教学周服务和 17 个自动化测试。

Changed:
- 将默认 Flutter 示例替换为南工课表首个里程碑实现。

Fixed:
- 使用 ASCII 临时盘符规避 Flutter 中文路径分析异常。
- build_runner 使用 JIT 模式规避 AOT 输出失败。

Validation:
- `flutter analyze`：No issues found。
- `flutter test`：17 tests passed。

Notes:
- Android SDK 未安装，APK 与真机持久化仍未验证。
- 下一步实现安全受限的教务 WebView 与接口发现骨架，不猜测真实接口。

## 2026-09-09 - Agent

Added:
- `knowledge/android_setup.md`，用于向其他 Agent 交接 Android SDK 配置与 APK 验收。
- Obsidian 项目索引和“南工课表”项目页。

Changed:
- TASK-015 标记为已委派进行中，真机验收拆分为 TASK-016。

Validation:
- 已核对 Flutter SDK 版本、项目 Android Gradle 配置和最新 `flutter doctor -v` 事实。

Notes:
- 本轮按用户要求不安装 Android，由其他 Agent 继续。
