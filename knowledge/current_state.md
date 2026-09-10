# Current State

## Last Updated

2026-09-11 01:35 +08:00

## Project Boundary

- `CONFIRMED`：Codex 中“课程表”是独立项目，根目录为 `D:\桌面\课程表`，且该目录是独立 Git 仓库。
- `CONFIRMED`：Obsidian 中已新建独立仓库“课表知识库”，路径为 `D:\桌面\课程表\课表知识库`；其中 `项目知识` Junction 直连项目的 `knowledge` 目录。
- `CONFIRMED`：“数模”是另一个 Codex 项目，根目录为 `D:\桌面\数模`。
- 原 `数模知识库/项目/南工课表.md` 已迁入新仓库的 `历史/数模知识库旧索引.md`，数模项目索引中的链接已移除。
- 本知识库只记录南工课表 App；不得再把状态同步到数模知识库或数模项目页。

## Current Milestone

里程碑 1（本地课表）已完成 Android 真机基础验收；里程碑 2（教务导入主链路代码）和里程碑 3（Android 桌面小组件代码）均已达到自动化验证通过状态。教务真实接口已由真机脱敏采集确认，解析、预览、确认写入链路已实现；剩余工作主要是需要用户登录/主屏操作的端到端验收与本地通知。

## Working Features

- Flutter Android/iOS 工程；Riverpod + GoRouter + Drift/SQLite 单机架构。
- Course / Semester / SectionTime 模型，课程 CRUD、按学期/教学周查询、默认学期和默认节次时间。
- 手动新增、编辑、删除课程；周课表、周切换、课程详情；学期设置及清空当前学期课程。
- 移动端纵向周日程 UI：周概览、七天日期条、周一至周日课程分组；课程卡显示节次、教室与教师，设置/详情/表单共用统一 Material 3 视觉。
- 依据 2026-2027 教学周历显示官方上课时间；第 3/4 节会按明志楼、明德楼、至善楼与其他教学场所自动选择对应作息，课程卡、详情页和桌面小组件一致。
- 全新安装的默认学期起点来自校历常量 `officialFirstWeekMonday`（2026-08-31），不再按“安装当天所在周的周一”推断。
- 学期日期与今天不匹配时课表页给出提示条（`SemesterService.termStatus`），避免学期设置过期后周次静默停在第 N 周。
- 导入预览会显示相对上一次导入的新增/移除条数，并列出将被移除的课程。
- 离开导入页时清理 WebView HTTP 缓存并清空内存中的课表原始响应；按用户决定保留 Cookie 与 WebStorage（DEC-010）。
- 周次解析（范围、单双周、离散周、中英文括号）。
- `manual` / `ncpu` 来源隔离，重新导入只替换教务来源课程。
- 正方教务受限 WebView：HTTP 风险确认门、scheme + host 白名单、加载/错误提示、Debug 脱敏采集页。
- 同源 XHR/fetch 钩子：脱敏采集报告可落盘；含身份字段的课表原始响应仅驻留内存，不写文件或日志。
- 已确认核心接口 `POST /jwglxt/kbcx/xskbcx_cxXsgrkb.html?gnmkdm=N253508`，并实现 `NcpuTimetableParser`、`NcpuAdapter.parseTimetable`、导入预览、确认后本地替换写入。
- Android 桌面小组件：Flutter 推送整周快照，Android 按设备日期计算当天课程，支持无课/学期前后状态、按高度截断及点击打开 App。
- Windows Android 工具链与 Debug APK 构建通路已打通；项目内固定 `flutter_inappwebview_android` 兼容补丁，不依赖全局 Pub Cache。

## In Progress

- 无。

## Not Started

- TASK-014 本地通知。

## Current Blockers

- `BLOCKED`（TASK-021）：教务重新导入需用户本人在 WebView 登录并确认预览；不得由 Agent 填写或保存账号密码。OnePlus PLC110 的数据库中已出现 27 条 `source=ncpu` 课程（14 门课），证明该完整链路在本机完成过一次真实写入，但仍需用户当场确认预览条数/字段、手动课程保留及再次导入结果；本轮新增的「新增/移除」差异行也要在这次真实导入中一并目视确认。
- `BLOCKED`（TASK-019）：provider 注册和数据同步已在真机确认；主屏添加、渲染/缩放、跨天重算和点击打开 App 仍需用户在启动器手动添加小组件（vivo 或 OnePlus 任一即可）。

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
- `CONFIRMED`：Git 基线已建立并推送 —— `master` 分支 4 个提交，远端 `origin` 为 `https://gitee.com/chenxihh/test_c.git`（公开仓库），本地与远端一致（TASK-022 已完成）。

## Validation Snapshot

- `CONFIRMED`（2026-09-11 01:30 +08:00，TASK-032）：设备重新接入后在 OnePlus PLC110 / Android 16 上完成真机验收。清缓存**可归因生效**：教务页加载后 `cache/WebView/Default/HTTP Cache` 2649 KB → 离开导入页后 65 KB（另一轮 4437 → 65 KB）；对照实验中 `am force-stop` 强杀进程（不经 `dispose`）后缓存保持 1417 KB 不变，排除"WebView 销毁自身清理"的伪因果。Cookies 24 KB 与 Local Storage 均保留，符合 DEC-010。
- `CONFIRMED`（2026-09-11 01:30 +08:00）：首页语义树显示「第 2 周 · 共 20 周 · 本周 13 条安排」，设置页显示「开学周一 2026-08-31」；学期在范围内故提示条不出现。此前的"首页第 2 周画面确认"改用 `uiautomator dump` 语义树完成，不再需要截屏。
- `UNVERIFIED`：导入预览「新增/移除」差异行的真机显示，需在 TASK-021 真实导入时确认。
- `CONFIRMED`（2026-09-11 01:05 +08:00）：`flutter analyze`（`R:\`）No issues found；`flutter test` 100/100 通过。
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

重新接入 Android 真机以完成 TASK-032（清缓存效果、学期提示条、导入预览差异行的真机验收）。设备可用后优先做 TASK-021 的教务导入预览确认与 TASK-019 的小组件主屏验收，这两项只能由用户在手机上完成。无需设备时下一步是里程碑 4（release 签名与包体积），但它必须在 TASK-021 之后 —— 换正式签名会强制卸载，本机课表数据会丢失。

## Handoff

### What is implemented

- 本地课表闭环、教务同源取数/脱敏采集、真实响应解析、导入预览与替换写入、Android 桌面小组件均已进入源码。
- `SchoolAdapter` 当前接口为 `parseTimetable(rawResponse, semesterId)`；适配器不接触 Cookie、Session 或 Token。
- 教务原始响应通过独立 JS 桥进入内存，Debug 脱敏报告走另一桥接通道，二者不得合并。

### What is verified

- 源码静态检查与 100 个 Dart/Flutter 测试通过。
- 13 个 Android 原生小组件 JVM 测试通过（本轮未改动 Kotlin，未重跑，最近一次结果仍有效）。
- 真实教务系统类型、登录入口、核心课表端点、菜单号和 `kbList` 关键字段已通过真机脱敏采集确认。
- 最新 Debug APK 已在 vivo V1981A 上覆盖安装通过冷启动、首页渲染、持久化和致命日志检查。
- 2026-09-11 之前的版本已在 OnePlus PLC110（Android 16）全新安装并通过冷启动与致命日志检查；该机默认学期起点已修正为 2026-08-31，小组件载荷同步。
- 2026-09-11 本轮改动（TASK-029/030/031）已在 OnePlus PLC110 覆盖安装并冷启动通过；HTTP 缓存清理经对照实验确认可归因生效且保留登录态；首页「第 2 周」经 uiautomator 语义树确认。
- `officialFirstWeekMonday` 与 `ensureDefaults()` 的关系、`termStatus` 边界、导入差异归类、清理器不抛异常、提示条出现条件均有自动化测试锁定。

### What remains unverified

- 导入预览「新增/移除」差异行的真机显示（TASK-021 的真实导入中一并确认）。
- 当前版本重新执行教务导入时的预览、确认替换与手动课程保留。
- 小组件在启动器上的实际添加、渲染、缩放、跨天与点击行为。
- iOS 构建与运行；V1 不阻塞。
