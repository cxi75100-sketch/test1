# Changelog

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
- `BLOCKED` 推送失败：GCM 返回 `cjh: Incorrect username or password (access token)`，需用户本人交互式认证后重推。

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
