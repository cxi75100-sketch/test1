# Tasks

## Now

- 无。
## Next

- [ ] TASK-039 Android 真机验收本地上课提醒：通知权限、精确闹钟权限/降级、实际到点通知、课程变化重排与重启恢复；步骤见 `knowledge/notifications.md`。

## Blocked

- [ ] TASK-019 桌面小组件真机验收 —— 进行中（2026-09-11，OnePlus PLC110 / Android 16）。已完成：启动器可选择并添加「南工课表」（ISSUE-011 关闭）、表头与当天课程时间渲染正确（ISSUE-013 修复后复验）、点击小组件可打开 App（`START u0 flg=0x14000000 mRealCallingUid=10218` 即启动器用我们 PendingIntent 的标志位启动）。
  **剩余**：数据变更后即时刷新、缩放、「还有 N 门课」溢出、「跨天重算」。其中溢出分支 —— 今天仅 3 门课而启动器最小高度 179dp 可容 5 行，正常使用下**无法触发**；本轮尝试注入 6 条临时课来制造溢出，因编码失误导致 App 加载失败并已回退（见 changelog）。**不得再为补验证直接修改真机生产数据库**；如确需，必须使用独立测试库或用 ASCII 值/Python 写库，并先备份。
  跨天重算未验（建议改学期开学周一而非改系统日期）。缩放无独立真机记录，按未验证处理。验收步骤见 `knowledge/home_widget.md`。

## Done

- [x] TASK-044 移除整周课表日列内部的上下滚动（2026-09-12 完成）：上午固定为 1-2 / 3-4 节两格，下午/晚间固定为 5-6 / 7-8 / 9-10 节三格，满课五张卡一屏完整可见；课程卡压缩为课程名、节次/时间、教室/教师三层，新增入口移至顶部避免遮挡末节课程。新增满课 Widget 回归确认两半等高、五门课均渲染且半区内无 `Scrollable`；`flutter analyze` 无问题，`flutter test` 132/132，Debug APK 构建、API 36 模拟器覆盖安装与真实画面验收通过，logcat 无致命异常或布局溢出。未修改课程数据。
- [x] TASK-043 将整周课表重做为横向周视图（2026-09-12 完成）：一天一列，每列上半为上午 1-4 节、下半为“下午 / 晚间”5-10 节且严格等高，横向滑动查看七天；移除重复日期条，新增滑动提示、当天强调、每日课程计数与窄列课程卡，保留课程名、节次、时间、教室、教师和详情入口。`flutter analyze` 无问题，`flutter test` 132/132；Debug APK 构建、API 36 模拟器覆盖安装、冷启动和横滑视觉验收通过，logcat 无致命异常或布局溢出。未修改课程数据。
- [x] TASK-042 强化整周课表的时段层级（2026-09-12 完成）：每天继续按星期分组，并依据官方节次再分为上午（1-4）、下午（5-8）、晚上（9+）；各时段增加差异化图标、颜色、节次范围、分隔线和留白，跨时段课程按开始节次唯一归类。`flutter analyze` 无问题，`flutter test` 132/132；Debug APK 构建、API 36 模拟器覆盖安装与冷启动成功，语义树确认时段标题与内容层级存在，logcat 无 App 致命异常。未修改课程数据。
- [x] TASK-041 将课表首页拆分为「今日」与「整周」两个独立栏目（2026-09-12 完成）：首页默认进入独立“今日”专栏，只显示设备当天课程并按节次排序；“整周”栏目保留周切换、七天日期条和按日分组，切回“今日”会回到当前教学周。新增 412×915 匿名数据视觉检查与窄屏 Widget 回归，确认栏目隔离、当天过滤及旧增课/周末课程流程；`flutter analyze` 无问题，`flutter test` 131/131，Debug APK 构建、模拟器覆盖安装、冷启动及双栏目语义验收通过。未操作真机数据，厂商真机手势体验待下次安装验收。
- [x] TASK-040 搭建 Android 模拟器环境（2026-09-12 完成）：安装 `emulator` 37.1.11.0 与 `system-images;android-36;google_apis;x86_64`，创建 AVD `ncpu_api36`（pixel_7 / API 36 / google_apis / x86_64 / 2 GB RAM / `hw.keyboard=yes`）。
  - `CONFIRMED` **无需管理员启用 Windows 功能、无需重启**：`emulator -accel-check` 返回 `WHPX(10.0.26200) is installed and usable`（退出码 0），模拟器日志确认 `Windows Hypervisor Platform accelerator is operational`；GPU 走 NVIDIA RTX 5060 Laptop GPU（Vulkan）。此前据 `Win32_OptionalFeature` InstallState 推断 WHPX 被禁用是**错误**的，该属性不可作为加速可用性依据。
  - `CONFIRMED` 项目链路在该模拟器可用：Debug APK 流式安装成功；冷启动 `Status: ok` / `LAUNCH_STATE_COLD` / 3.7 s，pid 存活；logcat 无 `FATAL`、`AndroidRuntime`、`MissingPluginException`、`E/flutter`；`app_flutter/ncpu_timetable.sqlite` 建库成功（**x86_64 原生 SQLite 可用**）；小组件载荷 `schemaVersion=1 / firstWeekMonday=2026-08-31 / totalWeeks=20` 已写入且 `TimetableWidgetProvider` 已在 `dumpsys appwidget` 注册；语义树显示「第 2 周 / 共 20 周 · 本周 0 条安排 / 9-7–9/13」。
  - 启动器为 `com.google.android.apps.nexuslauncher`（Launcher3，支持小组件）；时区已校正为 `Asia/Shanghai`；磁盘占用 `emulator` 1034 MB + `system-images` 4374 MB。
  - **不替代**：厂商启动器（OriginOS / ColorOS）下的 RemoteViews 排版、厂商省电策略下的后台与通知行为、arm64 原生库路径。
  - 内存前置：搭建前 `gradlew --stop` 释放闲置 daemon，可用内存 3.1 GB → 5.5 GB。

- [x] TASK-014 实现 Android V1 本地上课提醒（2026-09-12 完成）：默认关闭，用户主动开启时申请通知权限；默认提前 15 分钟，可选 5/10/15/30 分钟。按当前学期、课程周次/星期和统一作息生成未来提醒，课程、学期、作息、偏好变化及 App 回前台时重建；精确闹钟未授权时降级为非精确提醒；调度失败会回滚开启状态。`flutter analyze` 无问题、`flutter test` 130/130、Android JVM 单测 13/13、Debug APK 构建与通知权限/receiver/图标静态校验通过。真机行为转 TASK-039。

- [x] TASK-038 切换本仓库 Git 提交邮箱并推送已验证修复（2026-09-11 完成）：仅设置仓库级 `user.name` / `user.email`，不影响全局 Git 配置，不改写前 9 个提交。提交前扫描确认 17 个文件无邮箱明文、会话凭据赋值或构建产物；`flutter analyze` 无问题、`flutter test` 112/112、Android 原生单测成功。修复提交 `40c75cd` 已推送到 Gitee `master`，本地、tracking 与远端读回一致。

- [x] TASK-037 修复导入预览批量修改溢出（2026-09-11 完成）：将差异明细、课程列表和提示合并进最大为视口高度 65% 的单一滚动区，按钮保持在滚动区外；新增 27 条修改、360×800 视口回归测试，验证无异常、可滚到最后一条修改和课程列表底部、确认按钮始终可点。修正 `home_widget.md` 的旧接口名和 Zcode 报告的知识库文件计数。`dart format --set-exit-if-changed` 通过、`flutter analyze` 无问题、`flutter test` 112/112、Android 原生单测强制重跑成功。未操作真机、Git 历史或远端。

- [x] TASK-036 独立复核 TASK-035 Zcode 整改（2026-09-11 完成）：核心差异逻辑、`flutter analyze`、`flutter test` 111/111 与 Android 原生单测强制重跑均通过；但构造 27 条 `changed` 的 360×800 widget 场景稳定复现 `RenderFlex overflowed by 698 pixels`，TASK-035 仅部分验收、暂不建议提交。另发现 `home_widget.md` 仍引用已删除的 `firstSemester`，交付报告的知识库文件计数不一致。完整复核见 `knowledge/review_2026-09-11_task035.md`。

- [x] TASK-035 执行 Zcode 修改任务书（2026-09-11 完成）：对应 `knowledge/zcode_fix_request_2026-09-11.md` 全部要求。
  - `CONFIRMED` 导入差异新增 `changed`：`ImportDiff{added, removed, changed}`，`changed` 为 `CourseChange{previous, current, fields}`，逐字段按内容比较课程名、教师、教室、星期、节次、周次、起止时间、备注；`isEmpty` 同时考虑三类。
  - `CONFIRMED` 差异双侧只取 `CourseSource.ncpu`：`next` 中混入的手动课程不再被计为新增或修改（修复 P3-1）。
  - `CONFIRMED` 预览摘要改为「新增 N 条 · 移除 N 条 · 修改 N 条」，仅三类皆空时显示「与上次导入一致」；修改项以「旧值 → 新值」展示，空值显示「（未填）」。
  - `CONFIRMED` `flutter analyze` 无问题、`flutter test` 111/111、`gradlew :app:testDebugUnitTest --rerun` 13/13。
  - `CONFIRMED` 同步知识库过期结论（`current_state.md`、`home_widget.md`、`testing.md`、`issues.md`、`ncpu_import.md`、`changelog.md`）；未改 `replaceImportedCourses` 事务与手动课程隔离。
  - 未做：不改写 Git 历史、不改真机生产数据（等待用户决定公开邮箱）。
  - 交付报告：`knowledge/zcode_fix_report_2026-09-11.md`（含未改动清单与原因、验收标准对照）。

- [x] TASK-034 生成 Zcode 修改任务书（2026-09-11 完成）：把 TASK-033 的 3 个 P2 与 1 个 P3 转为明确的实现要求、测试矩阵、知识库同步范围、Git 邮箱决策边界和禁止事项；文件为 `knowledge/zcode_fix_request_2026-09-11.md`。本任务只编写任务书，未修改业务源码。

- [x] TASK-033 审查 Zcode 最近改动与 Gitee 仓库状态（2026-09-11 完成）：审查 `938c78c..6b321a4` 的 7 个提交；确认本地/远端 `master` 同为 `6b321a4`，`flutter analyze` 通过、`flutter test` 103/103、Android 原生单测构建成功；未发现已提交凭据或构建产物。发现 3 个 P2（导入摘要漏报详情变化、知识库状态矛盾、公开提交邮箱）和 1 个 P3（diff 的 next 未过滤 manual）。完整报告见 `knowledge/review_2026-09-11_zcode_gitee.md`。

- [x] TASK-021 教务课表导入真机端到端验收（2026-09-11 完成）：用户在 OnePlus PLC110 上本人登录教务并完成导入，全部验收项通过。
  - `CONFIRMED` 预览：27 条安排，与库内行数一致；新增的「相对上次导入」区块显示「与上次导入一致，没有新增或移除」（当时文案，TASK-035 起为「没有新增、移除或修改」并带「修改」计数）。
  - `CONFIRMED` 确认写入与替换等价：`source=ncpu` 的 27 条 id 集合指纹导入前后完全相同（`8b02dddd…`），未丢课也未多课。
  - `CONFIRMED` **手动课程保留**（本次最重要的新增证据）：用户先手动加一门课，再执行导入。`courses` 的隐式 rowid 由 `1..27` 变为 `29..55`。推理：导入只删 `source='ncpu'` 的 1..27 行，插入时 SQLite 取 `max(rowid)+1`，起点为 29 说明**插入那一刻 rowid 28（手动课）仍然存在**；若导入误删手动课，表会变空、重新插入将从 1 开始。用户验收后自行删除该手动课，留下 28 号空档。
  - `CONFIRMED` 学期记录未被导入改动（仍为 2026-08-31 / 20 周），SQLite `integrity_check=ok`。
  - 说明：教务数据当日未变，故差异区块显示"无变化"而非"新增/移除"；「移除」分支仍只由 `test/import_diff_test.dart` 覆盖。

- [x] TASK-032 TASK-029/030/031 的真机验收（2026-09-11 完成）：设备重新接入后在 OnePlus PLC110 / Android 16 上验收。
  - `CONFIRMED` 清缓存可归因生效：教务页加载后 `cache/WebView/Default/HTTP Cache` 为 2649 KB，返回键离开导入页后降到 65 KB；另一轮为 4437 KB → 65 KB。
  - `CONFIRMED` 对照实验排除伪因果：`am force-stop` 强杀进程（不经过 Dart `dispose`）后 HTTP Cache 保持 1417 KB 不变，说明下降来自 `clearHttpCache()`，而非 WebView 销毁时的自身清理。
  - `CONFIRMED` 登录态按设计保留：`app_webview/Default/Cookies` 仍为 24 KB，`Local Storage/leveldb` 保留。
  - `CONFIRMED` 首页显示「第 2 周 · 共 20 周 · 本周 13 条安排」，学期日期在范围内因此提示条不出现（此前因截屏被浮窗遮挡而挂起的画面确认，本轮改用 uiautomator 语义树完成，无需截屏）。
  - 越界态的提示条排版由 `test/timetable_page_test.dart` 在真机同宽视口（1272x2800 @ 560dpi ≈ 363x800 逻辑像素）下渲染验证；未为验证而改写真机学期日期。
  - 未覆盖：导入预览「新增/移除」差异行的真机显示，需在 TASK-021 的真实导入中一并确认。

- [x] TASK-031 学期日期失效提示（2026-09-11 完成）：`currentWeek()` 会把超出学期的周次封顶到 `totalWeeks`，"学期已结束"与"第 20 周"不可区分。新增 `TermStatus{before,within,after}` 与 `SemesterService.termStatus`，把 `timetable_page` 私有的日期算法抽成 `SemesterService.dateFor`，并在周概览与日期条之间加提示条（点击跳设置）。`flutter analyze` 无问题、`flutter test` 100/100（新增 9 个本学期相关测试）。

- [x] TASK-030 学期逻辑卫生（2026-09-11 完成）：`totalWeeks: 20` 与 `?? 20` 两处硬编码提为 `defaultTotalWeeks`；`AppDatabase.firstSemester()` 更名为 `currentSemester()` 并补文档，说明按 `firstWeekMonday` 倒序取第一条（最近开始的学期），不判断今天是否在学期内。

- [x] TASK-029 导入体验改造（2026-09-11 完成）：(a) 新增 `ImportSessionCleaner`，离开导入页时清理 WebView HTTP 缓存并清空内存中的课表原始响应；按用户决定保留 Cookie 与 WebStorage，取舍与残留风险记入 DEC-010。(b) 新增 `diffImportedCourses` 纯函数（按稳定的课程 id 比对，只比较教务来源），导入预览新增「相对上次导入：新增 N 条 · 移除 M 条」并列出将被移除的课程。`flutter analyze` 无问题、`flutter test` 100/100。

- [x] TASK-022 建立 Git 基线提交（2026-09-11 完成）：基线提交 `5509a85`（351 文件 / 43324 行）与文档收尾提交 `938c78c` 已推送到 `origin` = `https://gitee.com/chenxihh/test_c.git` 的 `master` 分支，本地与远端一致。提交前扫描确认无密钥、无构建产物、无身份信息；修正 `.gitignore` 对 `android/build/`、本地 Obsidian vault 和 `tmp/` 的遗漏。首次推送因 Git Credential Manager 回退到 `user.name` 导致用户名错误而失败，用户交互式提供 Gitee 私人令牌后推送成功。

- [x] TASK-028 默认学期起点改用校历常量（2026-09-11 完成）：新增 `officialFirstWeekMonday`（2026-08-31），`ensureDefaults()` 不再把“安装当天所在周的周一”当作第一周周一；该启发式会让第 2 周及以后安装的设备少算一周，并使单双周、限定周次课程错位。`flutter analyze` 无问题、`flutter test` 84/84、Debug APK 重新构建并覆盖安装到 OnePlus PLC110；该机旧学期记录已定向修正。真机首页周次文案未截屏确认（截屏时手机在前台使用，画面被其他 App 浮窗覆盖）。

- [x] TASK-027 在 OnePlus PLC110（Android 16 / API 36，arm64-v8a）上安装 Debug APK（2026-09-11 完成）：全新安装成功、冷启动无致命异常；发现该机默认学期被旧启发式算成 2026-09-07（显示第 1 周）后转 TASK-028 处理。设备数据库中已有 27 条 `source=ncpu` 课程，说明教务导入已在本机完成过一次真实写入。

- [x] TASK-026 依据《2026-2027学年教学周历》接入官方作息（2026-09-10 完成）：10 节通用作息已替换旧内置时间；第 3/4 节按教室文本自动区分明志楼/明德楼/至善楼（10:15-11:45）与其他教学场所（10:25-11:55）。课程卡、详情页和 Android 小组件共用同一解析规则；`flutter analyze` 无问题、`flutter test` 83/83、Debug APK 构建和真机覆盖安装成功。脱敏载荷核对确认两类课程时间全部正确。

- [x] TASK-025 安装 UI 重做后的最新版并完成 Android 真机自动化验收（2026-09-10 完成）：vivo V1981A / Android 12 安装 Debug APK 成功，冷启动成功且无 Flutter/Android 致命异常；1080×2408 真机截图及无障碍边界确认新版纵向日程、中文字体、卡片和浮动按钮正常。按用户确认将当前学期开学周一从误设的 2026-09-07 修正为 2026-08-31，冷启动后首页显示第 2 周、日期 9/7–9/13，课程数据完整保留，小组件载荷同步更新。原始数据库副本和含课程信息的验收截图在核验后删除。

- [x] TASK-016 Android 真机基础验收（2026-09-10 完成）：设备识别、APK 覆盖安装、冷启动、跨进程 SQLite 持久化、首页渲染、崩溃日志与包信息均已验证；教务重新导入和主屏小组件交互分别由 TASK-021 / TASK-019 跟踪。

- [x] TASK-024 新建独立 Obsidian“课表知识库”仓库（2026-09-10 完成）：仓库位于 `D:\桌面\课程表\课表知识库`，已生成 `.obsidian` 配置和入口 README；用 `项目知识` Junction 直接展示项目 `knowledge` 原文件，避免双份文档漂移；原数模知识库的“南工课表”页面已迁入新仓库历史目录，并从数模项目索引移除。Obsidian 注册表确认“课表知识库”和“数模知识库”为两个独立 vault。

- [x] TASK-023 统一 App 视觉并重做核心课表 UI（2026-09-10 完成）：用移动端纵向日程替换五列压缩表格，补齐周六/周日；新增周概览、七天日期条、按天分组课程卡片，卡片展示节次/教室/教师；统一 Material 3 主题、输入框、按钮、空状态、错误状态、设置页分组卡片与课程详情页。保持数据、导入和桌面小组件逻辑不变。`flutter analyze` 无问题，`flutter test` 78/78；已生成 412×915 Flutter 渲染预览检查布局，真机视觉仍待设备验收。

- [x] TASK-020 核对本地实现并收口知识库（2026-09-10 完成）：确认 Codex 中“课程表”项目路径为 `D:\桌面\课程表`、Git 仓库独立于“数模”项目 `D:\桌面\数模`；按当前源码修正 README、当前状态、任务、架构、导入、测试、问题与变更日志中的过期描述。重新验证 `flutter analyze` 无问题、`flutter test` 77/77、`gradlew :app:testDebugUnitTest` 13/13；当前无 Android 设备，真机验收单列为 TASK-021/TASK-019/TASK-016。

- [x] TASK-013 基于真实响应实现 parser 和导入预览（2026-09-10 代码完成）：`NcpuTimetableParser` 按 key 解析 `kbList` 的课程名、星期、节次、周次、教室、教师、学分与课程性质，忽略 `xsxx` 身份字段；`NcpuAdapter.parseTimetable` 返回 sealed 结果；WebView 内存接收课表原始响应，预览确认后 `replaceImportedCourses` 只替换 `ncpu` 来源课程。解析器/适配器自动测试通过；真机端到端验收转 TASK-021。

- [x] TASK-012 实现脱敏 Debug 接口发现工具（2026-09-10 完成）：脱敏器 + 同源 XHR/fetch JS 注入 + 采集页/自动保存 + 单元测试已完成，并通过真机采集确认正方教务核心课表接口、菜单号、`kbList`/节次字段结构；原始课表响应只留内存，脱敏报告不保存密码、Cookie、Session、Token 或身份原文。事实见 `knowledge/ncpu_import.md`。

- [x] TASK-018 实现 Android 桌面小组件（2026-09-10 完成）：Flutter 侧构建整周课表快照 JSON 并经 MethodChannel 推送，Android 侧用 `WidgetScheduleCalculator`（纯 Kotlin，自写 civil-days 日期算法，不依赖 java.time）按设备日期自行判断「今天是第几周、有哪些课」，因此 App 未运行时小组件仍显示正确；RemoteViews 列表按小组件实际高度决定行数，超出显示「还有 N 门课」，点击打开 App，night 配色随系统。`flutter analyze` 无问题，`flutter test` 53/53，`gradlew :app:testDebugUnitTest` 13/13，Debug APK 构建通过且清单/资源静态校验通过，未新增权限。真机渲染验收转 TASK-019（当时保持 BLOCKED，后续已完成添加/渲染/点击三项）。

- [x] TASK-017 收口教务登录骨架安全与构建复现性（2026-09-10 完成）：候选 HTTP 地址必须显式确认后才创建 WebView；移除误导性的“已验证官方页面”状态和裸 Cookie 接口；统一 scheme/host 校验；稳定版 Android 插件及 AGP 9 修复固化到项目 `third_party/`。`flutter analyze` 无问题，`flutter test` 44/44，通过恢复全局 Pub Cache 原状后的干净 APK 构建；WebView 真机交互当时保持 BLOCKED（后续 TASK-021 已完成端到端验收）。

- [x] TASK-000 创建 AGENTS.md 与知识库
- [x] TASK-001 初始化 Flutter 项目与目录结构
- [x] TASK-002 实现领域模型和 Drift 数据库
- [x] TASK-003 实现 Riverpod 数据层
- [x] TASK-004 实现周次解析器及测试
- [x] TASK-005 实现当前教学周计算及测试
- [x] TASK-006 实现手动新增、编辑、删除课程
- [x] TASK-007 实现周课表主页和课程详情
- [x] TASK-008 运行静态检查和自动测试
- [x] TASK-009 实现学期设置与清空当前学期课程
- [x] TASK-015 Android 工具链配置与 Debug APK 验证（2026-09-10 完成）：Temurin JDK 17.0.20.1+1 + Android SDK 36 + build-tools 36.0.0 + platform-tools 37.0.1 + NDK 28.2.13676358 安装到位；`flutter doctor -v` Android toolchain 全绿、licenses 全部接受；`flutter analyze` / `flutter test` 17/17 通过；`flutter build apk --debug` 300 s 产出 `D:\桌面\课程表\build\app\outputs\flutter-apk\app-debug.apk`（170,936,973 B），apksigner v2 通过、aapt2 清单校验通过。
- [x] TASK-010 实现 NcpuSchoolConfig 与 SchoolAdapter 骨架（2026-09-10 完成）：sealed ImportResult 层级（ImportSuccess / ImportInterfaceNotYetDiscovered / ImportError）；SchoolAdapter 抽象类（loginUrl / importCourses）；NcpuAdapter 骨架（importCourses 返回 ImportInterfaceNotYetDiscovered，不猜测接口）；NavigationPolicy 纯 Dart 导航策略（URL/host/scheme 白名单校验）；NcpuSchoolConfig 含 acceptedHosts + allowedSchemes；`flutter analyze` 无问题，`flutter test` 42/42 通过（新增 navigation_policy_test 11 + ncpu_adapter_test 5 + import_entry_test 2）。
- [x] TASK-011 实现安全受限的 WebView 登录页（2026-09-10 完成）：flutter_inappwebview 6.1.5 + InAppWebView；shouldOverrideUrlLoading 通过 NavigationPolicy 做域名白名单拦截；安全提示横幅 + 加载进度条 + 返回/刷新按钮；当时按钮仅提示“课表接口尚未确认”，后续已由 TASK-012/TASK-013 接通采集、解析、预览与写入；Android/iOS 仅对 `jwxt.ncpu.edu.cn` 做 HTTP 域名级例外；该阶段 APK 构建通过，当前端到端验收见 TASK-021。
