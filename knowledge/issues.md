# Issues

## ISSUE-014 本地上课提醒真机行为待验收

Status: Open（代码与构建已完成，真机行为未验证）

Observed: TASK-014 已实现通知偏好、未来提醒计划、Android 权限请求、精确闹钟降级、数据变化重排和开机恢复声明；自动测试与 Debug APK 静态校验通过。本轮 `adb devices -l` 无设备。

Impact: 不能确认目标手机的通知权限/精确闹钟系统页、厂商后台限制、实际到点时延、课程变化后的待触发通知替换和重启恢复。

Next Step: 连接 Android 真机后按 `knowledge/notifications.md` 执行 TASK-039；不修改系统时间，不保存课程详情或会话数据，使用临时手动课程并在验收后删除。

## ISSUE-001 南昌工学院课表接口确认（原“接口未知”）

Status: Resolved（接口形状与解析代码已确认；端到端验收另见 TASK-021）

Observed: 初期仅有候选入口。2026-09-10 已通过用户真机脱敏采集确认正方教务系统、核心课表端点 `xskbcx_cxXsgrkb.html?gnmkdm=N253508`、请求参数及 `kbList`/节次关键字段。

Impact: 原阻塞已解除；`NcpuTimetableParser`、`NcpuAdapter.parseTimetable`、预览与替换写入已实现。

Resolution Evidence: 事实见 `knowledge/ncpu_import.md`；2026-09-10 `flutter analyze` 无问题、`flutter test` 77/77。真机端到端已由 TASK-021（2026-09-11）验收通过。

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

Status: Resolved（2026-09-11，TASK-021）

Observed: 风险门、受限 WebView、同源课表取数、解析、预览与替换写入代码均已完成；真机脱敏采集已确认接口，设备现已连接且生产库内已有教务课程。剩余重新导入必须由用户本人登录并确认预览。

Impact: 无法确认当前版本的 WebView 加载/导航拦截、课表响应进入内存、预览内容、确认写入及重启持久化是否在真机整链路工作；不能声称正式导入已真机验收。

Resolution: 2026-09-11 用户在 OnePlus PLC110 / Android 16 上本人登录教务完成导入。预览 27 条；`source=ncpu` 的 27 条 id 集合指纹导入前后完全相同（替换等价）；手动课程经 rowid 位移（`1..27` → `29..55`，插入起点 29）反证保留成功；学期记录未变、`integrity_check=ok`。证据见 `knowledge/testing.md` 的 TASK-021 段落。

Remaining: 差异区块在教务数据真实变化时的真机显示（当日数据未变）——由自动测试覆盖，未升级为已确认。

## ISSUE-008 候选 HTTP 页面被错误显示为已验证官方页面

Status: Resolved（真机交互已由 TASK-021 验证，2026-09-11）

Observed: 原 ImportLoginPage 会立即加载未经真机确认的 HTTP 候选地址，并在加载后显示绿色 verified 图标和“学校官方页面”文案。

Impact: 白名单只限制导航范围，不能证明站点身份；该文案可能诱导用户在明文 HTTP 页面输入凭证。

Resolution: 增加阻断式风险确认门，清楚展示候选 host、未验证状态与 HTTP 明文风险；用户明确继续后才创建 WebView，加载期间及完成后均保持警告状态。新增 widget 测试确认默认状态不创建 WebView 进度 UI且不出现“学校官方页面”文案。

## ISSUE-009 适配器裸 Cookie 参数与 URL 校验职责不一致

Status: Resolved

Observed: 尚未确认真实接口时，通用 `SchoolAdapter.importCourses` 已接收裸 Cookie 字符串；`NcpuSchoolConfig.accepts` 只检查 host，导致危险 scheme 可被 adapter 的 `canHandle` 接受。

Impact: 形成未来误传凭证的接口脚手架，且 adapter 与 NavigationPolicy 对同一 URI 结论可能不一致。

Resolution: 在协议确认前移除 Cookie 参数；`NcpuSchoolConfig.accepts` 同时检查 scheme 与 host。新增 `javascript://jwxt.ncpu.edu.cn` 拒绝测试。

## ISSUE-010 桌面小组件主屏交互待用户添加

Status: Partially Resolved（2026-09-11 真机复验后更新剩余范围）

Observed: TASK-018 的 Dart 桥接、原生小组件代码与资源均已完成；2026-09-10 23:47 真机再次确认 provider 注册、Dart → SharedPreferences 载荷链路、正确学期起点及按教学楼解析的课程时间。2026-09-11 用户在 OnePlus PLC110 上把小组件添加到主屏。

Impact: 添加、表头/当天课程渲染、点击打开 App 已确认可用；数据变更后的即时刷新、缩放、「还有 N 门课」溢出、跨天重算及 30 分钟周期刷新的真实时延仍未验证，不能声称桌面小组件整体验收通过。

Resolution Evidence: 添加后 ISSUE-013（inflate 失败）修复并复验，表头「第 2 周 · 周五」与当天 3 门课、时间与官方作息一致；点击经 `START u0 flg=0x14000000 mRealCallingUid=10218` 确认由我们 PendingIntent 启动。详见 `knowledge/tasks.md` 的 TASK-019 与 `knowledge/home_widget.md`。

Next Step: 按 `knowledge/home_widget.md` 步骤 5、7、8 复检。溢出分支正常课量下无法触发，**不得再直接改真机生产库**制造数据。

## ISSUE-011 小组件 provider 在 dumpsys 中配置全为 0

Status: Resolved（2026-09-11 复检）

Observed: 2026-09-10 在 vivo V1981A 上安装后，`dumpsys appwidget` 中该 provider 显示各项全 0（同机其他小组件正常）。

Resolution: 2026-09-11 在 OnePlus PLC110 上添加小组件后复检，配置全部正常：
`min=(46081x28161) minResize=(46081x28161) updatePeriodMillis=1800000 resizeMode=3 widgetCategory=1 initialLayout=#7f0c0030`。

`min` 的数值形如 `180<<8|1 = 46081`、`110<<8|1 = 28161`，即该版本 dumpsys 把 dp 值与标志位打包输出，**实际就是 `timetable_widget_info.xml` 里的 180dp × 110dp，并非异常**。此前"配置全为 0"只是 provider 信息尚未被系统加载（首次安装后未打开过小组件选择器），属惰性加载，不是缺陷。

Next Step: 无需动作。以后判断该 provider 是否正常，请把 dumpsys 数值按 `>>8` 解读后再比较。

## ISSUE-013 小组件显示「载入小窗口时出现问题」（RemoteViews 不接受 View 控件）

Status: Resolved（2026-09-11）

Observed: 2026-09-11 用户在 OnePlus PLC110 上把「南工课表」小组件添加到主屏后，显示系统的加载失败文案。日志中 `AppWidgetHostView: inflateAsync(rvToApply)` 之后立刻 `mViewMode == VIEW_MODE_ERROR`，**且启动器不打印任何异常堆栈**（欧加定制启动器吞掉了错误），因此从日志无法直接得到原因。

已排除：provider 注册、载荷数据、Dart 侧渲染都已确认正常 —— `WidgetRenderer.render` 成功产出 `RemoteViews` 并通过 `updateAppWidgetIds` 提交，我们自己进程内无异常。

Root cause: 布局 `widget_timetable.xml` 的 `widget_divider` 与 `widget_row.xml` 的 `widget_row_color` 使用了 `android.view.View`。**RemoteViews 的 LayoutInflater 只允许带 `@RemoteView` 注解的类**，`android.view.View` 与 `android.view.ViewGroup` 都没有该注解。可用 `javap -v -classpath <android.jar> <类名> | grep RemoteView` 验证：`LinearLayout`/`TextView`/`ImageView` 有，`View`/`ViewGroup` 没有。

Impact: 整个小组件 inflate 失败并停留在错误态；`mViewMode` 为 ERROR 后即使后续送来正确 RemoteViews 也会持续显示错误视图。

Resolution: 两处 `<View>` 改为无文字的 `<TextView>`（分隔线、课程色条）。`setBackgroundColor` / `setViewVisibility` 对 TextView 同样有效，Kotlin 侧无需改动。

Resolution Evidence: 重装后 `mViewMode == VIEW_MODE_ERROR` 归零；主屏语义树读到表头「第 2 周 · 周五」，当天 3 门课全部命中，时间 `10:25-11:55` / `14:00-15:30` / `15:55-17:25` 与官方作息一致。

Prevention: 见 `knowledge/home_widget.md`「布局硬约束」。

## ISSUE-012 Git 仓库没有基线提交

Status: Resolved（2026-09-11，TASK-022）

Observed: 2026-09-10 22:33 +08:00，`git log` 报当前 `master` 分支尚无 commit，`git status --short` 显示项目文件全部为 untracked。

Impact: 当前开发成果没有 Git 历史、差异基线或可靠的文件级恢复点；也无法用普通 `git diff` 审核本轮改动。

Resolution: 2026-09-11 建立基线提交 `5509a85` 与文档收尾提交 `938c78c` 并推送到 `origin`（`https://gitee.com/chenxihh/test_c.git`），本地与远端一致；当前 `master` 共 9 个提交。提交前已扫描确认无密钥、无构建产物、无身份字段。

Remaining: 公开提交元数据含个人 Gmail 地址，属身份信息公开（TASK-033 P2-3）；是否改写历史需用户单独决定，未经授权不执行。
