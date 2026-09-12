# Current State

## Last Updated

2026-09-12 12:37 +08:00

## Project Boundary

- `CONFIRMED`：Codex 中“课程表”是独立项目，根目录为 `D:\桌面\课程表`，且该目录是独立 Git 仓库。
- `CONFIRMED`：Obsidian 中已新建独立仓库“课表知识库”，路径为 `D:\桌面\课程表\课表知识库`；其中 `项目知识` Junction 直连项目的 `knowledge` 目录。
- `CONFIRMED`：“数模”是另一个 Codex 项目，根目录为 `D:\桌面\数模`。
- 原 `数模知识库/项目/南工课表.md` 已迁入新仓库的 `历史/数模知识库旧索引.md`，数模项目索引中的链接已移除。
- 本知识库只记录南工课表 App；不得再把状态同步到数模知识库或数模项目页。

## Current Milestone

里程碑 1（本地课表）、里程碑 2（教务导入主链路）均已完成真机端到端验收 —— 用户本人登录导入并确认写入，替换等价且手动课程保留。里程碑 3（Android 桌面小组件）已真机确认：可在启动器找到并添加、表头与当天课程渲染正确、点击可打开 App。Android 本地上课提醒代码已完成并通过自动化、原生构建与 APK 静态校验，尚待真机验证权限、实际到点、重排和重启恢复。Android 模拟器验证环境（AVD `ncpu_api36`）已搭建并通过实测，后续「可造数据、可改时钟、可重启」的验收转入模拟器执行。剩余工作：小组件剩余验收项、通知真机验收（TASK-039）、release 分发准备。

## Working Features

- Flutter Android/iOS 工程；Riverpod + GoRouter + Drift/SQLite 单机架构。
- Course / Semester / SectionTime 模型，课程 CRUD、按学期/教学周查询、默认学期和默认节次时间。
- 手动新增、编辑、删除课程；周课表、周切换、课程详情；学期设置及清空当前学期课程。
- 课表首页分为“今日 / 整周”两个独立栏目：默认今日只展示设备当天课程；整周为横向可滑动的七列周视图，一天一列，每列上半为上午 1-4 节、下半为“下午 / 晚间”5-10 节且等高。上午按 1-2 / 3-4、下半按 5-6 / 7-8 / 9-10 固定分格，列内不允许上下滚动，满课五张卡一屏完整可见；窄列卡保留课程名、节次、时间、教室与教师。
- 依据 2026-2027 教学周历显示官方上课时间；第 3/4 节会按明志楼、明德楼、至善楼与其他教学场所自动选择对应作息，课程卡、详情页和桌面小组件一致。
- 全新安装的默认学期起点来自校历常量 `officialFirstWeekMonday`（2026-08-31），不再按“安装当天所在周的周一”推断。
- 学期日期与今天不匹配时课表页给出提示条（`SemesterService.termStatus`），避免学期设置过期后周次静默停在第 N 周。
- 导入预览会显示相对上一次导入的新增/移除条数，并列出将被移除的课程；同 id 的课程详情变化（名称、教师、教室、星期、节次、周次、起止时间、备注）单独计入「修改」，并以「旧值 → 新值」展示。
- 离开导入页时清理 WebView HTTP 缓存并清空内存中的课表原始响应；按用户决定保留 Cookie 与 WebStorage（DEC-010）。
- 周次解析（范围、单双周、离散周、中英文括号）。
- `manual` / `ncpu` 来源隔离，重新导入只替换教务来源课程。
- 正方教务受限 WebView：HTTP 风险确认门、scheme + host 白名单、加载/错误提示、Debug 脱敏采集页。
- 同源 XHR/fetch 钩子：脱敏采集报告可落盘；含身份字段的课表原始响应仅驻留内存，不写文件或日志。
- 已确认核心接口 `POST /jwglxt/kbcx/xskbcx_cxXsgrkb.html?gnmkdm=N253508`，并实现 `NcpuTimetableParser`、`NcpuAdapter.parseTimetable`、导入预览、确认后本地替换写入。
- Android 桌面小组件：Flutter 推送整周快照，Android 按设备日期计算当天课程，支持无课/学期前后状态、按高度截断及点击打开 App。
- Android 本地上课提醒：默认关闭，用户主动开启；默认提前 15 分钟，可选 5/10/15/30。按当前学期、课程周次与统一作息排程，数据变化/回前台时重建；精确闹钟不可用时降级并提示。
- Windows Android 工具链与 Debug APK 构建通路已打通；项目内固定 `flutter_inappwebview_android` 兼容补丁，不依赖全局 Pub Cache。
- Android 模拟器验证环境已就绪：AVD `ncpu_api36`（API 36 / google_apis / x86_64），WHPX 硬件加速可用，Debug APK 可安装冷启动，x86_64 原生 SQLite 与小组件载荷链路均正常。用于承担需要造数据、改时钟、重启的验证。

## In Progress

- 无。

## Not Started

- Release 签名与分发准备。

## Current Blockers

- `BLOCKED`（TASK-019 剩余项）：provider 注册、数据同步、启动器添加、表头与当天课程渲染、点击打开 App 均已有真机记录（2026-09-11，OnePlus PLC110）。仍缺真机记录：课程变化后的即时刷新、缩放、「还有 N 门课」溢出分支、跨天重算。溢出分支在正常课量下无法触发（当天 3 门课，启动器最小高度可容 5 行）；曾尝试直接向真机生产库注入临时课以制造溢出，因中文 SQL 编码事故导致 App 加载失败并已回退（见 `knowledge/incident_2026-09-11_db_injection.md`），**不得再为补验证直接修改真机生产数据库**。跨天重算建议改学期开学周一，而不是改系统日期。2026-09-12 起上述两项可由模拟器安全解除：在 `ncpu_api36` 上造当天多门课程、改日期/时区都不触及真机生产库（TASK-040）。

## Important Context

- V1 仅支持南昌工学院，不做后端、账号或云同步。
- App 不提供密码输入框；用户只在明确接受 HTTP 明文风险后于学校 WebView 自行登录。所有课程数据本地处理。
- 教务系统与核心接口已由公网非登录探测和用户真机脱敏采集确认；用户名、姓名、密码、Cookie、Session、Token 和原始报告不得写入知识库。
- `kbList` 每条代表一个“星期 + 节次 + 周次段”安排，字段顺序不固定；`zcd` 是周次，`zcmc` 是职称名称，不得混用。
- 课表原始响应只留在 `importRawTimetableProvider` 内存；解析器只读取通用课程字段并忽略 `xsxx` 身份信息。
- Flutter 3.47.2 / Dart 3.13.2 位于 `D:\Tools\flutter`；JDK 17 位于 `D:\Tools\jdk-17`；Android SDK 位于 `D:\Tools\android-sdk`。
- 中文工作区直接运行 `flutter analyze` 仍可能触发 LSP JSON 异常；使用 `subst R: "D:\桌面\课程表"` 后在 `R:\` 执行。
- Android Gradle 仍输出 AGP 9 built-in Kotlin 迁移/Gradle 10 兼容性弃用警告；当前不影响构建与测试，后续单独升级处理。
- 小组件协议为 `schemaVersion=1`；修改时必须同步 Dart/Kotlin 常量与两侧测试。
- 当前学期开学第一周周一为 `2026-08-31`（用户确认，且与教学周历一致）；`2026-09-10` 起属于第 2 周。该值已固化为代码默认常量，两台真机的生产库和小组件载荷均已同步为该日期。
- 两台真机：vivo V1981A（Android 12 / API 31，2026-09-10 完成覆盖安装与冷启动验收）与 OnePlus PLC110（Android 16 / API 36 / arm64-v8a，2026-09-11 完成全新安装）。
- Android 模拟器：AVD `ncpu_api36`（pixel_7 / API 36 / google_apis / x86_64 / 2 GB RAM），`emulator` 37.1.11.0，硬件加速走 WHPX（`emulator -accel-check` 退出码 0），启动器为 Launcher3（支持小组件）。用途是替代真机做**可造数据、可改时钟、可重启**的验证；**不替代**厂商启动器下的 RemoteViews 排版、厂商省电策略下的后台/通知行为与 arm64 原生库路径。
- `CONFIRMED`：Git 基线已建立并推送，远端 `origin` 为 `https://gitee.com/chenxihh/test_c.git`（公开仓库）；TASK-014 功能提交 `0342855` 已推送，本地、tracking 与 Gitee 远端读回一致。后续提交使用用户指定的仓库级专用邮箱，未改写前 9 个提交的历史。

## Validation Snapshot

- `CONFIRMED`（2026-09-12 12:37 +08:00，TASK-044）：整周日列已移除半区内部 `ListView`，上午两格和下午/晚间三格按节次定位；满课 Widget 回归确认五张课程卡均渲染、两半等高且半区内无 `Scrollable`。新增入口从右下悬浮按钮移至顶部，避免遮挡末节课程。`flutter analyze` 无问题，`flutter test` 132/132，Debug APK 构建并在 `ncpu_api36` 覆盖安装、启动成功；真实 Android 画面确认周四五张满课卡一次全部可见、周五单门上午课落在对应节次格，logcat 无致命异常或布局溢出。未修改课程数据。
- `CONFIRMED`（2026-09-12 12:22 +08:00，TASK-043）：整周课表已重做为“一天一列、上下各半”的横向周视图；七天横向滑动、上午/下午晚间等高、晚课保留、课程详情与完整元数据均有 Widget 回归。`flutter analyze` 无问题，`flutter test` 132/132；Debug APK 构建成功，在 `ncpu_api36` 覆盖安装与冷启动成功（2474 ms）。真实 Android 画面检查首屏约两列半、横滑后连续显示后续日期，列间无重叠，浮动按钮未遮挡课程；logcat 无致命异常或布局溢出。临时 Computer Use 截图已清理，未修改课程数据。
- `CONFIRMED`（2026-09-12 11:45 +08:00，TASK-042）：整周课表已按官方节次增加“上午 / 下午 / 晚上”时段标题、图标、节次范围、分隔线与留白；跨时段课程按开始节次唯一归类。`flutter analyze` 无问题，`flutter test` 132/132；Debug APK 构建成功，在 `ncpu_api36` 覆盖安装及冷启动成功（2793 ms），语义树确认上午/下午时段层级已渲染，logcat 无 App 致命异常。临时 UI dump 已删除；未修改课程数据。
- `CONFIRMED`（2026-09-12 11:28 +08:00，TASK-041）：课表首页“今日 / 整周”双栏目完成；412×915 匿名数据渲染预览确认栏目切换、日期主卡、三张课程卡与浮动按钮无互相遮挡；`flutter analyze` 无问题，`flutter test` 131/131，Debug APK 构建成功并在 `ncpu_api36` 覆盖安装、冷启动成功（2739 ms）。模拟器真实 Android 字体画面确认今日空状态无遮挡；语义树确认“今日”默认选中，“整周”可切换并显示周概览、日期条和课程列表；logcat 无 App 致命异常。临时截图/UI dump 已删除。`UNVERIFIED`：厂商真机手势体验待下次设备验收。
- `CONFIRMED`（2026-09-12 11:25 +08:00，TASK-040）：Android 模拟器环境搭建完成并实测通过。`emulator` 37.1.11.0 + `system-images;android-36;google_apis;x86_64`，AVD `ncpu_api36`。`emulator -accel-check` 返回 `WHPX(10.0.26200) is installed and usable`（退出码 0），日志 `Windows Hypervisor Platform accelerator is operational`，**无需管理员改 Windows 功能、无需重启**（此前据 `Win32_OptionalFeature InstallState=2` 推断 WHPX 禁用是错的，该属性不可作依据）。设备 `emulator-5554` / `sdk_gphone64_x86_64` / API 36 / x86_64，`sys.boot_completed=1`。Debug APK 流式安装成功，冷启动 `Status: ok` / COLD / 3696 ms，logcat 无 `FATAL`/`AndroidRuntime`/`MissingPluginException`/`E/flutter`；`app_flutter/ncpu_timetable.sqlite` 建库成功证明 **x86_64 原生 SQLite 可用**；小组件载荷 `schemaVersion=1 / firstWeekMonday=2026-08-31 / totalWeeks=20` 已写入且 `TimetableWidgetProvider` 已注册；语义树显示「第 2 周 / 共 20 周 · 本周 0 条安排 / 9-7–9/13」。启动器为 Launcher3（支持小组件），时区已设为 `Asia/Shanghai`。
- `CONFIRMED`（2026-09-12 10:57 +08:00，TASK-014）：本地上课提醒默认关闭、15 分钟默认值、5/10/15/30 选项、权限拒绝、精确闹钟降级、调度失败回滚、未来计划与数据变化重排均有自动化覆盖；`flutter analyze` 无问题、`flutter test` 130/130、Android JVM 单测 13/13、Debug APK 构建及权限/receiver/图标静态校验通过；功能提交 `0342855` 已推送。`UNVERIFIED`：本轮无 Android 设备，系统权限弹窗、实际到点通知、课程变化后的系统排程与重启恢复转 TASK-039。
- `CONFIRMED`（2026-09-11 20:43 +08:00，TASK-038）：用户确认后已将 Git 作者邮箱仅配置在本仓库，不改全局配置；提交 `40c75cd` 的 author/committer 均为新邮箱。提交前扫描确认暂存差异无邮箱明文、会话凭据赋值或构建产物；`flutter analyze` 无问题、`flutter test` 112/112、Android 原生单测重跑成功。本地 `HEAD`、`origin/master` 与 Gitee `refs/heads/master` 均为 `40c75cd`。
- `CONFIRMED`（2026-09-11 20:22 +08:00，TASK-037）：TASK-036 发现的批量修改弹窗溢出已修复；差异明细、课程列表与提示共用最大为视口高度 65% 的单一滚动区，按钮固定。27 条修改、360×800 视口回归测试确认无异常，可滚到最后一条修改和列表底部；`flutter analyze` 无问题、`flutter test` 112/112、Android 原生单测强制重跑成功。文档旧接口名和计数同步修正。
- `PARTIAL`（2026-09-11 20:14 +08:00，TASK-036）：独立重跑 `flutter analyze`、`flutter test` 111/111、Android 原生单测均通过；但 27 条课程同时发生详情变化时，导入预览在 360×800 视口可复现 `RenderFlex overflowed by 698 pixels`。TASK-035 暂不建议提交，需先给修改明细增加有界滚动并补批量回归测试。详见 `knowledge/review_2026-09-11_task035.md`。
- `CONFIRMED`（2026-09-11 20:05 +08:00，TASK-035）：Zcode 修改任务书整改完成。`flutter analyze` 无问题、`flutter test` **111/111**、`gradlew :app:testDebugUnitTest --rerun` 13/13。本轮修复：导入差异新增 `changed`（同 id 逐字段内容比较）、`next` 双侧过滤手动课程、知识库过期结论同步。**未改真机生产数据、未重写 Git 历史、未提交未推送**。
- `CONFIRMED`（2026-09-11 19:54 +08:00，TASK-033）：本地 `HEAD`、`origin/master`、远端 `refs/heads/master` 同为 `6b321a4`；`flutter analyze` 无问题、`flutter test` 103/103、Android 原生单测构建成功。审查发现 3 个 P2 与 1 个 P3，详见 `knowledge/review_2026-09-11_zcode_gitee.md`；该轮只审查和写报告，未修改业务源码。
- `CONFIRMED`（2026-09-11 01:50 +08:00，TASK-021）：教务导入真机端到端验收通过。用户本人登录完成导入；预览 27 条、差异区块显示「与上次导入一致，没有新增或移除」（**当时快照**：该文案自 TASK-035 起改为「与上次导入一致，没有新增、移除或修改。」，并新增「修改」计数）；`source=ncpu` 的 id 集合指纹导入前后完全相同（替换等价、无丢失）；**手动课程经 rowid 位移反证被正确保留**（`1..27` → `29..55`，插入起点 29 说明导入时 rowid 28 的手动课仍在）；学期记录未被改动，`integrity_check=ok`。
- 观测方法修正：**不能用 SQLite `change counter` 判断是否发生过导入** —— `ensureDefaults()` 每次冷启动都会写 `section_times`，实测每启动一次 +1（19→20→21）。可靠信号是 `courses` 的隐式 rowid 位移。
- `CONFIRMED`（2026-09-11 01:30 +08:00，TASK-032）：设备重新接入后在 OnePlus PLC110 / Android 16 上完成真机验收。清缓存**可归因生效**：教务页加载后 `cache/WebView/Default/HTTP Cache` 2649 KB → 离开导入页后 65 KB（另一轮 4437 → 65 KB）；对照实验中 `am force-stop` 强杀进程（不经 `dispose`）后缓存保持 1417 KB 不变，排除"WebView 销毁自身清理"的伪因果。Cookies 24 KB 与 Local Storage 均保留，符合 DEC-010。
- `CONFIRMED`（2026-09-11 01:30 +08:00）：首页语义树显示「第 2 周 · 共 20 周 · 本周 13 条安排」，设置页显示「开学周一 2026-08-31」；学期在范围内故提示条不出现。此前的"首页第 2 周画面确认"改用 `uiautomator dump` 语义树完成，不再需要截屏。
- `UNVERIFIED`：导入预览「移除」分支的真机显示（当日教务数据未变，只观察到「无变化」；该分支由 `test/import_diff_test.dart` 覆盖）。
- `CONFIRMED`（2026-09-11 01:05 +08:00）：`flutter analyze`（`R:\`）No issues found；`flutter test` 103/103 通过。
- `CONFIRMED`（2026-09-11 00:03 +08:00）：`flutter analyze`（`R:\`）No issues found；`flutter test` 84/84 通过（新增默认学期起点测试）。
- `CONFIRMED`（2026-09-11 00:05 +08:00）：Debug APK 构建成功（206,352,868 B，SHA1 `b24127bb6edb69a50a1c59b90ffea42651030725`），`adb install -r -t` 安装到 OnePlus PLC110 / Android 16 成功，冷启动无 Flutter/Android 致命异常。
- `CONFIRMED`（2026-09-11 00:04 +08:00）：OnePlus PLC110 设备库 `first_week_monday` 已修正为 2026-08-31，`total_weeks=20`，SQLite `integrity_check=ok`，27 条课程记录未变；覆盖安装后小组件载荷同步 `firstWeekMonday=2026-08-31`。
- `CONFIRMED`（2026-09-10 22:33 +08:00）：`flutter analyze`（`R:\`）No issues found。
- `CONFIRMED`（2026-09-10 23:47 +08:00）：`flutter test` 83/83 通过；含教学楼作息解析、数据库官方默认时间、小组件载荷和课程卡时间展示测试。
- `CONFIRMED`：`gradlew :app:testDebugUnitTest` 构建成功；13 tests / 0 failures / 0 errors / 0 skipped。
- `CONFIRMED`：生成 412×915 Flutter 渲染预览并检查整体布局、卡片间距、横向日期条和浮动按钮；测试环境字体只适合检查结构，不代替真机中文字体视觉验收。
- `CONFIRMED`（2026-09-10 23:35 +08:00）：vivo V1981A / Android 12 / 1080×2408 上最新版覆盖安装及冷启动成功，首页显示第 2 周与 9/7–9/13；无 Flutter/Android 致命异常，课程跨进程持久化正常。
- `CONFIRMED`：`dumpsys appwidget` 已登记 `TimetableWidgetProvider`；SharedPreferences 载荷为 `schemaVersion=1`、`firstWeekMonday=2026-08-31`、`totalWeeks=20`。
- `CONFIRMED`：教学周历 PDF 与用户陈述共同确认第一周周一为 2026-08-31；真机脱敏载荷核对确认指定教学楼第 3-4 节为 10:15-11:45，其他场所为 10:25-11:55。

## Recommended Next Action

优先在 `ncpu_api36` 模拟器上执行 TASK-039 与 TASK-019 中「可造数据、可改时钟、可重启」的部分：通知的实际到点、课程变化重排、关闭取消、重启恢复，以及小组件的即时刷新、缩放、「还有 N 门课」溢出与跨天重算（改模拟器日期/时区即可，不碰真机生产库）。真机只保留必须项：厂商启动器下的小组件排版、厂商省电策略下的通知与后台行为、arm64 原生库路径。两项真机验收关闭后进入里程碑 4（release 签名与分 ABI 打包）——注意换正式签名必须先卸载，本机课表与登录态会丢，因此只能排在验收之后。

提交邮箱决策已关闭：用户已指定后续使用的专用邮箱，仅写入本仓库 Git 配置。历史 9 个提交不改写；若以后需要清理历史，必须作为独立高风险任务再确认。

## Handoff

### What is implemented

- 本地课表闭环、教务同源取数/脱敏采集、真实响应解析、导入预览与替换写入、Android 桌面小组件均已进入源码。
- `SchoolAdapter` 当前接口为 `parseTimetable(rawResponse, semesterId)`；适配器不接触 Cookie、Session 或 Token。
- 教务原始响应通过独立 JS 桥进入内存，Debug 脱敏报告走另一桥接通道，二者不得合并。
- 导入差异模型 `ImportDiff` 使用 `added` / `removed` / `changed` 三类；`changed` 逐字段按内容比较，并同时保留旧课程与新课程。

### What is verified

- 源码静态检查与 130 个 Dart/Flutter 测试通过。
- 13 个 Android 原生小组件 JVM 测试通过（2026-09-11 `--rerun` 强制重跑确认 13/13；本轮未改动 Kotlin）。
- 真实教务系统类型、登录入口、核心课表端点、菜单号和 `kbList` 关键字段已通过真机脱敏采集确认。
- **教务导入端到端已在真机验收通过（TASK-021）**：用户本人登录 → 预览 27 条 → 确认写入 → 替换等价（id 指纹不变）→ 手动课程经 rowid 位移反证被保留。
- 最新 Debug APK 已在 vivo V1981A 上覆盖安装通过冷启动、首页渲染、持久化和致命日志检查。
- 2026-09-11 之前的版本已在 OnePlus PLC110（Android 16）全新安装并通过冷启动与致命日志检查；该机默认学期起点已修正为 2026-08-31，小组件载荷同步。
- 2026-09-11 本轮改动（TASK-029/030/031）已在 OnePlus PLC110 覆盖安装并冷启动通过；HTTP 缓存清理经对照实验确认可归因生效且保留登录态；首页「第 2 周」经 uiautomator 语义树确认。
- 小组件已在 OnePlus PLC110 真机确认：启动器可选择并添加「南工课表」、表头与当天课程时间渲染正确、点击可打开 App（ISSUE-011 关闭、ISSUE-013 修复后复验）。
- Android 模拟器环境已实测可用（TASK-040）：WHPX 硬件加速、API 36 / x86_64、Debug APK 冷启动、x86_64 原生 SQLite 建库、小组件载荷与 provider 注册、UI 语义树读取均通过；可承担需要造数据、改时钟、重启的验证。
- `officialFirstWeekMonday` 与 `ensureDefaults()` 的关系、`termStatus` 边界、导入差异三类归类（含同 id 详情变化与 `next` 混入 manual）、清理器不抛异常、提示条与预览差异区出现条件均有自动化测试锁定。

### What remains unverified

- 导入预览差异区块在真实教务数据变化时的真机显示（当日数据未变，只观察到「一致」；新增/移除/修改分支均由自动测试覆盖）。
- 小组件剩余行为：数据变更后的即时刷新、「还有 N 门课」溢出分支、缩放、跨天重算（TASK-019）—— 现可在模拟器上验证，仅厂商启动器下的排版需真机。
- 本地通知行为：实际到点通知、数据变化重排、关闭取消、重启恢复现可在模拟器验证；通知/精确闹钟权限弹窗与厂商后台限制仍需真机（TASK-039）。
- iOS 构建与运行；V1 不阻塞。
