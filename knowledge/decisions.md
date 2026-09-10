# Decisions

## DEC-001 使用 Flutter

Status: Accepted

Context: 需要 Android 优先且保持 iOS 兼容。

Decision: 使用 Flutter / Dart。

Reason: 一套代码覆盖双平台，适合课表 UI。

Consequences: 依赖 Flutter 工具链与 Dart 生态。

## DEC-002 V1 不做后端

Status: Accepted

Context: 首版目标是单校课表导入与本地使用。

Decision: 不做账号体系、后端、云同步。

Reason: 缩小安全面和交付范围。

Consequences: 数据仅保存在当前设备。

## DEC-003 密码只在学校官方 WebView 输入

Status: Accepted

Context: 教务凭证高度敏感。

Decision: App 不提供自建密码表单，不收集、不保存、不上传密码。

Reason: 避免接触用户凭证并遵循学校认证流程。

Consequences: 导入依赖校方页面可用性和本机会话。

## DEC-004 首个里程碑先完成本地课表

Status: Accepted

Context: 教务接口尚未真实确认。

Decision: 先实现模型、持久化、解析器、手动课程与课表 UI。

Reason: 先验证独立于教务系统的核心闭环。

Consequences: 教务导入推迟到本地闭环通过后。

## DEC-005 依赖注入与持久化方案

Status: Accepted

Context: 需求指定 Riverpod、GoRouter 和 Drift。

Decision: 使用 Riverpod 3、GoRouter 18、Drift 2；不使用已 EOL 的 sqlite3_flutter_libs。

Reason: 采用当前受维护的官方/上游版本和接口。

Consequences: 最低 Flutter/Dart 版本随当前依赖要求提升。

## DEC-006 教务 WebView 方案与导航策略

Status: Accepted

Context: 需要在学校官方页面内嵌入 WebView 供用户登录，同时防止凭证泄露到非白名单域名。

Decision: 使用 flutter_inappwebview 6.1.5；导航拦截通过纯 Dart `NavigationPolicy` 类实现，不依赖平台回调。

Reason: flutter_inappwebview 是当前维护活跃、功能完整的跨平台 WebView 插件；`shouldOverrideUrlLoading` 回调可在 Dart 层做域名白名单校验；将导航策略抽为纯 Dart 类便于无平台单元测试。

Consequences: 新增 flutter_inappwebview 依赖（含 Android/iOS 原生组件）；AGP 9.1.0 与稳定版 Android 子包存在 ProGuard 兼容性问题，项目内固化方式见 DEC-008。

## DEC-007 HTTP cleartext 最小化策略

Status: Accepted

Context: 候选教务入口 `http://jwxt.ncpu.edu.cn:8088/jwglxt` 使用 HTTP，Android 9+ 和 iOS 默认禁止 cleartext 流量。

Decision: 不做全局 `usesCleartextTraffic=true` / ATS 全局例外；仅在 Android `network_security_config.xml` 对 `jwxt.ncpu.edu.cn` 放行 HTTP，iOS `Info.plist` 做域名级 `NSExceptionAllowsInsecureHTTPLoads`。

Reason: 最小化安全面，仅对学校已知域名放行 cleartext，避免其他 HTTP 流量意外通过。

Consequences: 若学校启用新域名或子域名，需同步更新安全配置；HTTPS 迁移后可移除例外。

## DEC-008 候选 HTTP 登录入口必须显式确认，插件补丁项目内固化

Status: Accepted

Context: 候选入口尚未经过真机验证且使用 HTTP；原页面自动加载并显示绿色“学校官方页面”会造成错误安全暗示。flutter_inappwebview_android 1.1.3 的全局 Pub Cache 补丁也不能随项目复现。

Decision: 首次进入只显示候选 host、未验证状态与 HTTP 明文风险，用户明确点击继续后才创建 WebView；加载后持续使用警告色和候选页面措辞。`SchoolAdapter.importCourses()` 在真实协议确认前不接收 Cookie。Android 子包 1.1.3 固定到 `third_party/flutter_inappwebview_android`，通过 `dependency_overrides` 使用，仅将两个 ProGuard 默认文件引用改为 `proguard-android-optimize.txt`。

Reason: 防止把白名单误表述为身份认证，减少凭证误用接口，并确保全新环境及 Pub 缓存清理后仍可构建。

Consequences: 仓库增加约 1.1 MB 第三方源码；升级插件时必须核对许可证、移除已被上游解决的补丁并重跑全量 Android 验证。WebView 实际渲染和登录仍需真机验证。

## DEC-009 桌面小组件手写原生实现，不复用 home_widget 插件

Status: Accepted

Context: 需要主屏小组件展示「今天课程」，且 App 未运行时也要正确。社区常用方案是 `home_widget`（0.9.4）。

Decision: 不使用 `home_widget`，改为自建 MethodChannel + SharedPreferences + 自写 AppWidgetProvider；原生侧自行按设备日期计算周次与当天课程。

Reason:
- 2026-09-10 核实 `home_widget` 0.9.4 的 Android 端依赖 `androidx.glance`、`androidx.work`、coroutines，且在 AGP 9.1.0 上的兼容性未经验证；本项目已因 AGP 9 被迫 vendored flutter_inappwebview（ISSUE-006），不宜再引入同类风险。
- 插件能省的只有约 80 行通道与存储管道；RemoteViews 渲染、日期计算、布局资源无论用不用插件都要写。
- 自写使全部代码留在仓库内、零新增依赖，且周次计算可以抽成纯 Kotlin 做 JVM 单元测试。

Consequences: 需要自行维护 Android 原生小组件代码；小组件相关的日期/周次逻辑与 Dart `SemesterService` 形成双实现，必须靠两侧测试与 `knowledge/home_widget.md` 的协议说明保持一致。iOS WidgetKit 未覆盖（需要额外 Xcode target 与 App Group），V1 不做。

## DEC-010 离开导入页只清 HTTP 缓存，保留教务登录态

Status: Accepted

Context: 教务站在明文 HTTP 上运行。App 自身不读取、不保存 Cookie，但 WebView 会把教务登录 Cookie 与 WebStorage 写在设备上，且此前没有任何清理逻辑（`dispose()` 只销毁 controller）。

Decision: 离开导入页（`dispose()`）时清理 WebView 的 HTTP 缓存（含磁盘文件，`InAppWebViewController.clearAllCache`），并清空内存中的课表原始响应；**不清理 Cookie 与 WebStorage**。

Reason: 用户明确选择保留登录态，避免每次导入都要重新登录教务系统。

Consequences:
- 明文 HTTP 会话的 Cookie 与 localStorage 仍会落盘，直到用户退出教务或清除应用数据。**这不是已解决的安全问题，而是被明确接受的取舍**；如需排除，改法是在 `ImportSessionCleaner` 中追加 `CookieManager.deleteAllCookies()` 与 `WebStorageManager.deleteAllData()`，代价是每次导入都要重新登录。
- 清理是尽力而为：失败只影响存储占用，不影响导入功能，因此 `clearHttpCache()` 不抛异常。
- 自动化测试只能验证「不抛异常」与调用时机；缓存确实被清掉需要在真机上对比 `app_webview/` 目录体积。
