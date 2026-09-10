# Testing

## Automated Strategy

- Week parser：范围、单双周、分段、离散周、中英文括号和非法输入。
- Semester service：第一周、第二周、开学前、学期后边界；`termStatus` 的学期前/最后一天/结束后边界；`dateFor` 不夹取周次。
- Database：CRUD、按学期/教学周查询、仅替换 ncpu 来源课程。
- Database defaults：`ensureDefaults` 幂等；全新安装的默认学期起点来自校历常量（2026-08-31），而非安装当天所在周的周一。
- Widget：空状态、课程展示、周切换和详情导航、设置页教务导入入口。
- NavigationPolicy：URL/host/scheme 白名单校验、子域名边界与脱敏域名显示（15 个测试）。
- Import capture：敏感键/长数字/高熵串脱敏、JSON 结构、数组摘要、报告输出（9 个测试）。
- NcpuTimetableParser：真实 `kbList` 关键字段、字段乱序、周次/节次回退、身份字段忽略与异常响应（12 个测试）。
- NcpuAdapter：loginUrl、scheme/host 联合校验、空数据/异常/合法响应 sealed 结果（11 个测试）。
- Import entry widget：设置页入口存在 + 导航到 WebView 页（2 个测试）。
- Import login widget：用户确认风险前只渲染候选 HTTP 风险门、不创建 WebView 加载状态（1 个测试）。
- Widget payload builder：协议版本、学期字段、课程序列化、配色规则（含 colorKey 取绝对值）、节次时间（5 个测试）。
- Widget sync：原生通道缺失时降级返回 false、启动快照含默认学期与 10 条节次时间、新增/删除课程后重新推送（4 个测试，用 `TestDefaultBinaryMessengerBinding` 打桩通道）。
- Widget 日程计算（JVM / JUnit）：`gradlew :app:testDebugUnitTest`，EpochDay/ISO 星期、开学前、第 1 周、第 2 周周三、第 20 周周日、学期结束后、总周数非法、周次与星期过滤排序、时间来源优先级（13 个测试）。
- ImportDiff：首次导入全为新增、内容相同无差异、单侧增删、手动课程不参与、同 id 改名不算差异（6 个测试）。
- ImportSessionCleaner：平台实现未注册时静默降级、不抛异常（1 个测试）。
- Timetable page：学期已结束/开学日在未来时显示提示条，学期日期在范围内时不显示（3 个测试，按运行日期推算学期避免时间依赖）。
- Android toolchain：`flutter doctor -v` 全绿 + Debug APK 静态校验（签名 + 清单 + ABI + 权限）。

## Passed

- `flutter analyze`（在 `R:\` 下）：No issues found。
- `flutter test`（2026-09-11 +08:00）：100 tests passed。
- `flutter test`（2026-09-11 00:03 +08:00）：84 tests passed。
- `flutter test`（2026-09-10 23:47 +08:00）：83 tests passed。
- `gradlew :app:testDebugUnitTest`（2026-09-10 TASK-018）：13 tests / 0 failures / 0 errors / 0 skipped（结果见 `build/app/test-results/testDebugUnitTest/`）。
- Week parser：范围、单双周、中英文括号、分段、离散、去重排序和非法输入。
- Semester service：第一周、第二周、开学前、学期后边界、日期时间归一化。
- Database：CRUD、按教学周查询、导入替换保留 manual 课程。
- Widget：App 启动、空状态、进入新增页、保存并在课表显示课程、设置页教务导入入口。
- Timetable UI：纵向日程可展示周日课程，并显示课程名、教室、教师与节次。
- Course time：教学周历 10 节官方作息、明志/明德/至善楼第 3-4 节提前规则、其他教学场所规则和课程明确时间优先级。
- NavigationPolicy：合法 URL 放行、非白名单 host 拦截、非白名单 scheme 拦截、null URL 拦截、空 config 全拦截。
- NcpuAdapter：loginUrl 来自学校配置；空响应不伪造课程；异常/合法响应分别映射为 `ImportError` / `ImportSuccess`；危险 scheme + 白名单 host 仍拒绝。
- NcpuTimetableParser：按 key 解析课程/星期/节次/周次/教室/教师；忽略身份字段；同课多安排保留；非法响应返回可读错误。
- 教务导入静态链路：WebView 课表响应进内存 → adapter 解析 → 预览确认 → `replaceImportedCourses`；真实端到端交互仍见 Manual Testing。
- ImportLoginPage：默认显示未验证与 HTTP 风险；刷新禁用；未出现“学校官方页面”文案；未渲染 WebView 加载进度。
- `flutter doctor -v`（2026-09-10 记录）：
  - Flutter 3.47.2 stable / Dart 3.13.2 / DevTools 2.60.0 ✓
  - Windows Version（Windows 11 25H2, 10.0.26200.8037）✓
  - **Android toolchain ✓**：SDK 36.0.0，Platform android-36，build-tools 36.0.0，`ANDROID_HOME=D:\Tools\android-sdk`，Java 位于 `D:\Tools\jdk-17\bin\java`，`OpenJDK Runtime Environment Temurin-17.0.20.1+1`，`All Android licenses accepted`。
  - Chrome ✓ / Connected device（3 available：Windows/Chrome/Edge）✓ / Network resources ✓
  - Visual Studio `[X]`：预期，V1 不做 Windows 桌面构建。
- `flutter clean` → `flutter pub get` → `flutter build apk --debug`（2026-09-10 TASK-017）：全局 Pub Cache 已恢复为原始不兼容配置，依赖解析明确使用项目内 `third_party/flutter_inappwebview_android`，干净构建成功。
- APK 静态校验（TASK-017 后）：
  - 产物 `D:\桌面\课程表\build\app\outputs\flutter-apk\app-debug.apk`，大小 174,296,188 B（≈166.22 MiB），SHA256 `da582782b6b10f4e165e61d9b35fb6c66a4b8d19e1920fdcf53911b501d4a7eb`。
  - apksigner：v2=true，Signer `CN=Android Debug`，RSA 2048。
  - aapt2：package=`cn.edu.ncpu.timetable.ncpu_timetable`，compileSdk/targetSdk=36，minSdk=24，label=`南工课表`；权限仅 INTERNET + DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION。
- APK 静态校验（TASK-018 后）：
  - 产物 `D:\桌面\课程表\build\app\outputs\flutter-apk\app-debug.apk`，大小 206,292,551 B（≈196.74 MiB），SHA256 `8f1847a6904f72aace89cea379c737c8319641828b60b57d5627f9b3de99ba2a`。
  - apksigner：Signer `C=US, O=Android, CN=Android Debug`，证书 SHA-256 `9f3fff6ec93838bd7c1d4e2a66fc43ccd0d5a19c5856c6c45019571c20dc57b3`。
  - aapt2 `dump xmltree`：合并后清单新增 `cn.edu.ncpu.timetable.ncpu_timetable.widget.TimetableWidgetProvider`，`exported=false`、`APPWIDGET_UPDATE` intent-filter、`android.appwidget.provider` 元数据指向 `@xml/timetable_widget_info`；**权限未增加**（仍为 INTERNET + DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION）。
  - aapt2 `dump resources`：`layout/widget_timetable`、`layout/widget_row`、`drawable/widget_background`、`array/widget_weekdays`、`string/widget_no_class`、`string/widget_open_app_hint` 等小组件资源均已在包内。

## Manual Testing

- Android 真机（2026-09-10 20:00 +08:00，vivo V1981A / Android 12 / API 31，序列号已隐去）：
  - `CONFIRMED`：USB 授权后 `adb devices` 显示 `device`（product PD1981 / model V1981A）。
  - `CONFIRMED`：`adb install` 流式安装被系统拦截（返回空错误），改用 `adb push` + `pm install -r -t` 安装成功；Git Bash 下需 `MSYS_NO_PATHCONV=1`，否则设备路径 `/data/local/tmp/...` 会被转换成 Windows 路径。
  - `CONFIRMED`：`am start` 启动成功，进程存活（`pidof` 有值），logcat 无 `AndroidRuntime` / FATAL / `MissingPluginException`。
  - `CONFIRMED`：**Dart → 原生小组件数据链路在真机工作**：`run-as ... cat shared_prefs/ncpu_timetable_widget.xml` 读到完整载荷（`schemaVersion=1`、`firstWeekMonday=2026-09-07`、`totalWeeks=20`、10 条节次时间、`courses` 为空）。
  - `CONFIRMED`：`dumpsys appwidget` 中已登记 `cn.edu.ncpu.timetable.ncpu_timetable.widget.TimetableWidgetProvider`。
  - `BLOCKED`：小组件在主屏的实际渲染、添加/缩放、跨天重算、点击打开 App——尚未完成，另见 ISSUE-011（provider 信息在 dumpsys 中显示为全 0，待添加小组件后复检）。
  - 环境注意：本轮 USB 连接多次掉线，掉线后偶发需要重新授权；单条命令内尽量一次完成多个查询。
- Android 真机（2026-09-10 23:35 +08:00，同一 vivo V1981A）：
  - `CONFIRMED`：新版 Debug APK 经 `adb push` + `pm install -r -t` 覆盖安装成功；包版本 1.0.0 (1)，`lastUpdateTime=2026-09-10 23:28:52`。
  - `CONFIRMED`：两次 force-stop 后均可冷启动；启动耗时分别约 1.9 s / 1.7 s，logcat 未发现 `FATAL EXCEPTION`、`AndroidRuntime`、`MissingPluginException` 或 `E/flutter`。
  - `CONFIRMED`：用户确认 2026-09-10 已是第 2 周后，仅定向修正当前学期 `firstWeekMonday` 为 2026-08-31；SQLite `quick_check=ok`，课程表未清空。
  - `CONFIRMED`：1080×2408 真机截图和 UIAutomator 边界显示首页为“第 2 周”，日期条为 9/7–9/13；首日标题、课程卡片、设置按钮与新增按钮均在有效可见区域，无溢出或互相遮挡。
  - `CONFIRMED`：冷启动后课程仍存在，证明当前生产 SQLite 数据可跨进程恢复；小组件载荷同步为 `schemaVersion=1`、`firstWeekMonday=2026-08-31`、`totalWeeks=20`。
  - 隐私处理：验收过程中未输出账号、Cookie、Session 或 Token；含课程信息的截图、UI dump 和数据库副本在完成核验后删除。
- Android 真机（2026-09-10 23:47 +08:00，教学周历作息）：
  - `CONFIRMED`：新 APK 覆盖安装并冷启动成功，首页仍为第 2 周，课程卡同时显示节次与起止时间；1080×2408 画面无文本溢出。
  - `CONFIRMED`：脱敏解析小组件载荷，仅统计类别和时间；2 条指定教学楼 3-4 节课程均为 10:15-11:45，4 条其他教学场所 3-4 节课程均为 10:25-11:55。
  - `CONFIRMED`：sectionTimes 已同步为教学周历公布的 10 条通用作息；logcat 未发现 Flutter/Android 致命异常。
- Android 真机（2026-09-11 00:05 +08:00，OnePlus PLC110 / Android 16 / API 36 / arm64-v8a，序列号已隐去）：
  - `CONFIRMED`：`adb install -r -t` 流式安装成功（无需 push + `pm install` 迂回）；包 `cn.edu.ncpu.timetable.ncpu_timetable` 1.0.0 (1)，minSdk 24 / targetSdk 36，`primaryCpuAbi=arm64-v8a`。
  - `CONFIRMED`：`am start -W` 冷启动 `Status: ok`，进程存活，logcat 无 Flutter/Android 致命异常（`E fatal_log: no such table: download` 来自系统 DownloadProvider，与 App 无关）。
  - `CONFIRMED`：该机为**全新安装**（`firstInstallTime` 等于本次安装时间），此前无同包名记录。
  - `CONFIRMED`：设备数据库中 27 条课程全部 `source=ncpu`，覆盖 14 门课，证明教务导入链路在本机已完成过一次真实写入（预览确认环节仍待用户确认，见 TASK-021）。
  - `CONFIRMED`：修正后 `first_week_monday=2026-08-31`、`total_weeks=20`，SQLite `integrity_check=ok`，课程记录数不变。
  - `CONFIRMED`：覆盖安装后冷启动触发小组件载荷重推，`firstWeekMonday=2026-08-31`、`totalWeeks=20`、`schemaVersion=1`。
  - `UNVERIFIED`：首页“第 2 周”文案未截屏确认（手机当时在前台使用，截屏被其他 App 浮窗覆盖）；该截图已立即删除。
  - 隐私处理：验收过程中的截图与数据库副本已全部删除；未输出账号、Cookie、Session 或 Token。截屏前须确认手机未被他人使用。
- Android 真机（2026-09-11 本轮改造验收，OnePlus PLC110 / Android 16，序列号已隐去）：设备首次连接时掉线，重新接入后完成。
  - `CONFIRMED`：`adb install -r -t` 覆盖安装成功，冷启动 `Status: ok` / `LaunchState: COLD`，logcat 无 `FATAL` / `AndroidRuntime` / `MissingPluginException` / `E/flutter`。
  - `CONFIRMED`：首页语义树显示「第 2 周 · 共 20 周 · 本周 13 条安排」；设置页显示「当前学期 · 20 周 · 开学周一 2026-08-31」。本轮改用 `uiautomator dump` 读取语义树代替截屏，避免拍到其他应用内容。
  - `CONFIRMED`：**HTTP 缓存清理可归因生效**。教务页加载后 `cache/WebView/Default/HTTP Cache` = 2649 KB，返回键离开导入页后 = 65 KB（另一轮 4437 → 65 KB）。
  - `CONFIRMED`：对照实验排除伪因果 —— `am force-stop` 强杀进程（不经过 Dart `dispose`）后 HTTP Cache 保持 1417 KB 不变。
  - `CONFIRMED`：按 DEC-010 保留的登录态确实保留 —— `app_webview/Default/Cookies` 24 KB、`Local Storage/leveldb` 均在。
  - 注意：`app_webview/` 在 WebView 首次初始化时会自行由 4318 KB 降到 234 KB，与本次改动无关；观测清缓存要看 `cache/WebView/Default/HTTP Cache`，不是 `app_webview/`。
  - 未覆盖：导入预览「新增/移除」差异行的真机显示（需真实导入，见 TASK-021）。
- Android 模拟器：未安装，如需可用需追加 `sdkmanager "emulator" "system-images;android-36;google_apis;x86_64"`。
- WebView / 教务导入：`PARTIAL`。用户曾在真机通过 Debug 采集工具登录并打开课表页，已取得脱敏接口形状；当前源码又加入正式解析、预览和确认写入，但尚未对这一完整版本做真机端到端验收（TASK-021）。
- 桌面小组件：`BLOCKED`。原生渲染、添加到主屏、缩放、跨天重算、点击打开 App 均无设备可验证；验收步骤见 `knowledge/home_widget.md`。
- iOS：未开始，首版仅保持代码兼容。

## Not Covered

- 当前版本在真机上的完整教务导入验收：真实登录、课表预览条数/字段、确认写入、手动课程保留、重启后持久化（TASK-021）。
- 通知权限、时区、系统重启后的调度。
- 教务重新导入后的替换持久化、手动课程保留与预览确认（已有课程的普通冷启动持久化已确认）。
- Release 签名（当前 Debug 用 Android Debug 证书；release 走 debug signingConfig，`android/app/build.gradle.kts` 已注明 TODO）。
- Play Store 上传所需的 AAB / v3 签名 / 分包策略。
- WebView 内当前版本的 JavaScript 取数与预览交互；App 不做 Cookie 管理或表单自动填充。
- 桌面小组件的真机表现：RemoteViews 在不同启动器下的尺寸/字号、30 分钟周期刷新的实际时延、SharedPreferences 载荷存储。

## Tooling Note

- Flutter 3.47.2 在中文工作区直接 `flutter analyze` 会触发 LSP JSON 截断异常。
- 使用临时 ASCII 盘符 `R:`（`subst R: "D:\桌面\课程表"`）后分析和测试均通过。
- 建立 `R:` 时，Git Bash 直接把中文路径传给 `cmd //c subst` 会因 UTF-8/GBK 编码不一致失败；改用 `powershell -EncodedCommand <Base64 UTF-16LE>` 稳定成功。
- build_runner 在原路径 AOT 写入失败，使用 `--force-jit` 成功生成 Drift 代码。
- sdkmanager 通过 Git Bash 传参 `--sdk_root=D:\\Tools\\android-sdk` 时反斜杠会被吃成 `D:Toolsandroid-sdk`，导致组件被写到 `D:\Toolsandroid-sdk\`；本轮已合并目录并改用单引号 Windows 路径 `--sdk_root='D:\Tools\android-sdk'`。
- Windows 环境变量持久化统一走 PowerShell `[Environment]::SetEnvironmentVariable(name, value, 'User')`，避免 `setx` 引号被吃进值。
- 本轮工具链占用：`D:\Tools\android-sdk` ≈ 2.6 GB（含自动补装的 platforms;android-35 与 cmake;3.22.1），`D:\Tools\jdk-17` ≈ 304 MB。
- flutter_inappwebview Android 子包 1.1.3 已通过项目内 path override 固化；全局 Pub Cache 无需修改，详见 ISSUE-006 / DEC-008。
- `gradlew :app:testDebugUnitTest` 可直接在 `android/` 下运行（本轮未触发 Dart 构建，约 2 分钟）：小组件等纯 Kotlin 逻辑因此能在无设备环境完成验证；测试结果在 `build/app/test-results/testDebugUnitTest/`。
