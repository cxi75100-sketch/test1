# Tasks

## Now

- 无。

## Next

- [ ] TASK-014 实现本地通知
- [ ] TASK-022 建立 Git 基线提交 —— 当前仓库尚无 commit，项目文件全部为 untracked；需先确认提交边界并排除本机/构建产物，再创建首个可恢复基线。

## Blocked

- [ ] TASK-021 教务课表导入真机端到端验收 —— `BLOCKED`：接口、解析器、预览与本地替换写入代码均已完成，真机现已可连接且生产库中已有教务课程；仍需用户本人在 WebView 完成登录并当场确认预览条数/字段、手动课程保留及再次导入结果。不得自动填写或保存账号密码。
- [ ] TASK-019 桌面小组件真机验收 —— `BLOCKED`：真机已确认 provider 注册和 Dart → SharedPreferences 数据同步；仍需用户在 vivo 启动器手动添加小组件，才能验收主屏渲染、缩放、跨天重算与点击打开 App（验收步骤见 `knowledge/home_widget.md`）。

## Done

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

- [x] TASK-018 实现 Android 桌面小组件（2026-09-10 完成）：Flutter 侧构建整周课表快照 JSON 并经 MethodChannel 推送，Android 侧用 `WidgetScheduleCalculator`（纯 Kotlin，自写 civil-days 日期算法，不依赖 java.time）按设备日期自行判断「今天是第几周、有哪些课」，因此 App 未运行时小组件仍显示正确；RemoteViews 列表按小组件实际高度决定行数，超出显示「还有 N 门课」，点击打开 App，night 配色随系统。`flutter analyze` 无问题，`flutter test` 53/53，`gradlew :app:testDebugUnitTest` 13/13，Debug APK 构建通过且清单/资源静态校验通过，未新增权限。真机渲染验收转 TASK-019，保持 BLOCKED。

- [x] TASK-017 收口教务登录骨架安全与构建复现性（2026-09-10 完成）：候选 HTTP 地址必须显式确认后才创建 WebView；移除误导性的“已验证官方页面”状态和裸 Cookie 接口；统一 scheme/host 校验；稳定版 Android 插件及 AGP 9 修复固化到项目 `third_party/`。`flutter analyze` 无问题，`flutter test` 44/44，通过恢复全局 Pub Cache 原状后的干净 APK 构建；WebView 真机交互保持 BLOCKED。

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
