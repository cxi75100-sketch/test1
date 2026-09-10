# Issues

## ISSUE-001 南昌工学院课表接口确认（原“接口未知”）

Status: Resolved（接口形状与解析代码已确认；端到端验收另见 TASK-021）

Observed: 初期仅有候选入口。2026-09-10 已通过用户真机脱敏采集确认正方教务系统、核心课表端点 `xskbcx_cxXsgrkb.html?gnmkdm=N253508`、请求参数及 `kbList`/节次关键字段。

Impact: 原阻塞已解除；`NcpuTimetableParser`、`NcpuAdapter.parseTimetable`、预览与替换写入已实现。

Resolution Evidence: 事实见 `knowledge/ncpu_import.md`；2026-09-10 `flutter analyze` 无问题、`flutter test` 77/77。当前仅剩真机端到端体验与持久化结果未验收，单列 TASK-021。

## ISSUE-002 Android/iOS 工具链状态待检查

Status: Partially Resolved（Android 已解决；iOS 保持 Open）

Observed: 2026-09-09 委派时 `flutter doctor -v` 报 `Unable to locate Android SDK`，Windows 桌面 Visual Studio 未安装。2026-09-10 00:01 +08:00 复检：Android toolchain 全绿，SDK 36.0.0、build-tools 36.0.0、Platform android-36、Temurin JDK 17.0.20.1+1，`All Android licenses accepted`；Debug APK 构建 + 静态签名/清单校验通过。Visual Studio 仍 `[X]`，但 V1 不做 Windows 桌面构建，属预期。

Impact: Android Debug 通路已打通；iOS 构建仍未验证，V1 不阻塞。

Possible Solution: Android 侧无需继续动作。iOS 待有 macOS 环境时另开工单。

Assignment: 2026-09-09 委派；2026-09-10 由 Android 工具链 Agent 完成验收。

Resolution Evidence:
- `D:\Tools\jdk-17`（Temurin 17.0.20.1+1，SHA256 `e53a79c3c3d86865bd7e787903884331068e71321714ffd44f145785affc7cb0` 已校验）。
- `D:\Tools\android-sdk`：cmdline-tools/latest（19.0）、platform-tools 37.0.1、platforms;android-36 rev2、build-tools;36.0.0、ndk;28.2.13676358；构建中自动补装 platforms;android-35 rev2 与 cmake;3.22.1；总占用 ≈ 2.6 GB。
- 用户级环境变量已持久化：`JAVA_HOME` / `ANDROID_HOME` / `ANDROID_SDK_ROOT`；PATH 追加 `%JAVA_HOME%\bin` / `%ANDROID_HOME%\platform-tools` / `%ANDROID_HOME%\cmdline-tools\latest\bin` / `D:\Tools\flutter\bin`。
- `flutter config --android-sdk D:\Tools\android-sdk --jdk-dir D:\Tools\jdk-17` 已写入。
- APK：`D:\桌面\课程表\build\app\outputs\flutter-apk\app-debug.apk`，170,936,973 B，SHA256 `1daf867fc31a15f053c1ef17f69f109110bcd061f1e85a6e1ccd632c1222aa06`；apksigner v2 通过，Signer CN=Android Debug；aapt2 输出 package=`cn.edu.ncpu.timetable.ncpu_timetable`、compileSdk=36、minSdk=24、targetSdk=36、label=`南工课表`、权限仅 INTERNET + DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION。

## ISSUE-003 中文工作区触发 Flutter 工具异常

Status: Resolved in Project（上游稳定版问题仍存在）

Observed: Flutter 3.47.2 在 `D:\桌面\课程表` 直接运行 analyze 时，analysis server 报 LSP JSON `Unterminated string`；build_runner AOT 也无法写入输出。本轮补充观察：Git Bash 直接把中文路径传给 `cmd //c subst` 会因 UTF-8/GBK 编码不一致失败（错误信息里目标路径变成乱码 `\D:\????\?γ̱?\`）。

Impact: 直接使用原路径的部分开发命令失败，但不影响项目源码。

Possible Solution:
- 已固化：`powershell -NoProfile -EncodedCommand <Base64 UTF-16LE>` 建立 `subst R: "D:\桌面\课程表"`，之后所有 Flutter / Dart 命令在 `R:\` 下执行；本轮 analyze / test / build apk 均在 `R:\` 下通过。
- 已固化：build_runner 使用 `D:\Tools\flutter\bin\dart.bat run build_runner build --force-jit`。
- 后续 Flutter 版本修复中文路径后复测，届时可撤销 subst。

## ISSUE-004 Android 真机 / 模拟器未接入，TASK-016 BLOCKED

Status: Resolved（2026-09-10 23:35 +08:00）

Observed: 2026-09-10 23:28 后 vivo V1981A 稳定接入；最新版 APK 覆盖安装、两次冷启动、首页渲染、SQLite 跨进程持久化和致命日志检查均已完成。

Resolution: TASK-016 基础真机验收完成。教务重新导入、小组件主屏和通知分别由 TASK-021、TASK-019、TASK-014 独立跟踪。

Possible Solution:
- 首选：用户接入 Android 真机（USB + 开发者模式 + adb 授权），复跑 `flutter devices` 后执行 `flutter run --debug`。
- 备选：明确授权后追加 `sdkmanager "emulator" "system-images;android-36;google_apis;x86_64"`（约 1.5–2 GB），创建 AVD 并确认 CPU 虚拟化（Intel HAXM / Windows Hypervisor Platform / AMD AEHD）可用；此路径需用户确认，本轮未擅自启动。

## ISSUE-005 sdkmanager 通过 Git Bash 传 Windows 路径反斜杠被吃

Status: Resolved（本轮遇到并修复；已固化规避手段）

Observed: 首次调用 `sdkmanager.bat --sdk_root=D:\\Tools\\android-sdk ...` 时，bash→bat→Java 多层转义把反斜杠吃掉，实际写入路径变成 `D:Toolsandroid-sdk`（相对当前盘符），组件被安装到 `D:\Toolsandroid-sdk\`。日志中 `Installing NDK... in D:Toolsandroid-sdk\ndk\28.2.13676358` 是唯一可见线索；`sdkmanager --list_installed` 仍报告成功，仅靠 `ls D:\Tools\android-sdk\` 才发现目录为空。

Impact: 若未及时发现会导致 Flutter / Gradle 找不到 SDK 组件；本轮通过合并目录（`mv D:\Toolsandroid-sdk\* D:\Tools\android-sdk\`）恢复。

Possible Solution（已固化）:
- 从 Git Bash 调用 sdkmanager 时，Windows 路径统一用单引号：`--sdk_root='D:\Tools\android-sdk'`（bash 单引号保留字面量，Java 命令行不再解析反斜杠转义）。
- 或者从 PowerShell / cmd 直接调用 sdkmanager，避免 bash 转义层。
- setx 同类问题：`setx KEY \"value\"` 会把引号写入值；改用 PowerShell `[Environment]::SetEnvironmentVariable($k, $v, 'User')`。

## ISSUE-006 flutter_inappwebview 插件 proguard 与 AGP 9.1.0 不兼容

Status: Workaround Confirmed（问题仍存在，规避手段已固化）

Observed: `flutter_inappwebview_android-1.1.3/android/build.gradle` 使用 `getDefaultProguardFile('proguard-android.txt')`，AGP 9.1.0 已移除对该文件的支持（因内含 `-dontoptimize`），构建报错：`getDefaultProguardFile('proguard-android.txt') is no longer supported since it includes -dontoptimize`。

Impact: 直接 `flutter build apk` 失败；不影响 `flutter analyze` 和 `flutter test`。

Resolution:
- 将 pub.dev 稳定版 `flutter_inappwebview_android` 1.1.3 固定到项目 `third_party/flutter_inappwebview_android`，保留原 LICENSE 与包元数据。
- 根 `pubspec.yaml` 通过 path override 使用项目内副本；两个 buildType 的默认 ProGuard 文件改为 `proguard-android-optimize.txt`。
- 已把全局 Pub Cache 恢复为原始不兼容状态，并执行 `flutter clean` → `flutter pub get` → `flutter build apk --debug`；干净构建成功，确认不再依赖机器级补丁。
- 详见 DEC-008 与 `third_party/README.md`。

## ISSUE-007 WebView / 教务导入端到端验收需用户登录确认

Status: Open（BLOCKED）

Observed: 风险门、受限 WebView、同源课表取数、解析、预览与替换写入代码均已完成；真机脱敏采集已确认接口，设备现已连接且生产库内已有教务课程。剩余重新导入必须由用户本人登录并确认预览。

Impact: 无法确认当前版本的 WebView 加载/导航拦截、课表响应进入内存、预览内容、确认写入及重启持久化是否在真机整链路工作；不能声称正式导入已真机验收。

Possible Solution:
- 首选：用户接入 Android 真机后执行 `flutter run --debug`，导航到设置页 → 教务导入 → 验证 WebView 页面。
- 备选：授权安装 emulator + system-image 后在模拟器上验证。
- 复测：`flutter devices` 确认设备 → 设置页 → 教务导入 → 自行登录并打开学生课表查询 → 核对预览 → 确认写入 → 检查手动课程保留 → 重启 App 检查持久化（TASK-021）。

## ISSUE-008 候选 HTTP 页面被错误显示为已验证官方页面

Status: Resolved in Code（真机交互仍 BLOCKED）

Observed: 原 ImportLoginPage 会立即加载未经真机确认的 HTTP 候选地址，并在加载后显示绿色 verified 图标和“学校官方页面”文案。

Impact: 白名单只限制导航范围，不能证明站点身份；该文案可能诱导用户在明文 HTTP 页面输入凭证。

Resolution: 增加阻断式风险确认门，清楚展示候选 host、未验证状态与 HTTP 明文风险；用户明确继续后才创建 WebView，加载期间及完成后均保持警告状态。新增 widget 测试确认默认状态不创建 WebView 进度 UI且不出现“学校官方页面”文案。

## ISSUE-009 适配器裸 Cookie 参数与 URL 校验职责不一致

Status: Resolved

Observed: 尚未确认真实接口时，通用 `SchoolAdapter.importCourses` 已接收裸 Cookie 字符串；`NcpuSchoolConfig.accepts` 只检查 host，导致危险 scheme 可被 adapter 的 `canHandle` 接受。

Impact: 形成未来误传凭证的接口脚手架，且 adapter 与 NavigationPolicy 对同一 URI 结论可能不一致。

Resolution: 在协议确认前移除 Cookie 参数；`NcpuSchoolConfig.accepts` 同时检查 scheme 与 host。新增 `javascript://jwxt.ncpu.edu.cn` 拒绝测试。

## ISSUE-010 桌面小组件主屏交互待用户添加

Status: Open（BLOCKED）

Observed: TASK-018 的 Dart 桥接、原生小组件代码与资源均已完成；2026-09-10 23:47 真机再次确认 provider 注册、Dart → SharedPreferences 载荷链路、正确学期起点及按教学楼解析的课程时间。尚未由用户添加到主屏。

Impact: 无法确认 RemoteViews 在主屏的实际渲染、添加/缩放行为、跨天重算、点击打开 App、30 分钟周期刷新的真实时延；不能声称桌面小组件功能验证通过。

Possible Solution:
- 首选：用户接入 Android 真机（USB + 开发者模式 + adb 授权）后执行 `flutter run --debug`，按 `knowledge/home_widget.md` 的 9 步验收流程逐项确认。
- 备选：授权安装 emulator + system-image 后在模拟器验证（模拟器可改系统日期，便于跨天验证）。

## ISSUE-011 小组件 provider 在 dumpsys 中配置全为 0（待复检）

Status: Open（待真机复检）

Observed: 2026-09-10 20:1x 在 vivo V1981A / Android 12 (API 31) 上安装 Debug APK 后，`dumpsys appwidget` 中该 provider 显示 `min=(0x0) minResize=(0x0) updatePeriodMillis=0 resizeMode=0 widgetCategory=0 initialLayout=#0`（同机 bilibili 小组件显示正常值）。

已排除的原因：APK 内编译资源经 aapt2 `dump xmltree --file res/xml/timetable_widget_info.xml` 校验**完全正确**：`minWidth=180dp`、`minHeight=110dp`、`updatePeriodMillis=1800000`、`initialLayout`/`previewLayout` 指向 `@layout/widget_timetable`、`resizeMode=0x3`、`widgetCategory=0x1`、`targetCellWidth=3`/`targetCellHeight=2`；清单内 `android.appwidget.provider` 指向 `@0x7f120003`。

初步判断：可能只是系统尚未加载新安装应用的 `AppWidgetProviderInfo`（惰性加载），需先打开一次小组件选择器或添加小组件后再复检 `dumpsys appwidget`。

Impact: 若为真实问题，小组件可能不出现在选择器中，或无法按 `updatePeriodMillis` 周期刷新（跨天自动换天失效，仅剩 App 打开时的推送）。

Next Step: 用户在主屏长按 → 添加小组件，确认列表是否出现「南工课表」、能否添加、能否正常显示；随后复检 `dumpsys appwidget`。若添加后仍为全 0，需排查 vivo 启动器（`com.bbk.launcher2`）对该 provider 的解析与兼容性。

## ISSUE-012 Git 仓库没有基线提交

Status: Open

Observed: 2026-09-10 22:33 +08:00，`git log` 报当前 `master` 分支尚无 commit，`git status --short` 显示项目文件全部为 untracked。

Impact: 当前开发成果没有 Git 历史、差异基线或可靠的文件级恢复点；也无法用普通 `git diff` 审核本轮改动。

Possible Solution: 执行 TASK-022；先核对 `.gitignore` 与提交范围，确认不包含构建产物、调试采集报告或任何身份/会话数据，再由用户确认是否创建首个基线提交。
