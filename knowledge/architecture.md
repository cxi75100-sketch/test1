# Architecture

## Overview

Flutter 单机应用，Riverpod 负责依赖和界面状态，GoRouter 负责导航，Drift + SQLite 持久化。首版不设后端。

## Current Structure

```text
lib/
  main.dart, app.dart        # app.dart 挂载 widget 同步作用域 + 生命周期观察
  core/{database,router,theme,utils}/
    theme/course_colors.dart # 课程配色（课表 UI 与桌面小组件共用）
  models/
    school.dart              # NcpuSchoolConfig（allowedHosts + allowedSchemes）
  features/timetable/{pages,widgets,providers,services}/
  features/import/
    adapters/
      school_adapter.dart    # SchoolAdapter 抽象类 + sealed ImportResult
      ncpu_adapter.dart      # NcpuAdapter 骨架（返回 ImportInterfaceNotYetDiscovered）
    pages/
      import_login_page.dart # 风险确认门 + InAppWebView 受限登录页
    providers/
      import_providers.dart  # Riverpod adapter/schoolConfig provider
    services/
      import_capture.dart        # 请求/响应形状脱敏器
      import_capture_script.dart # 同源 XHR/fetch 钩子；课表原文单独回传内存
      import_capture_file.dart   # 仅保存脱敏报告
      navigation_policy.dart # 纯 Dart 域名白名单导航策略
    parsers/
      ncpu_timetable_parser.dart # 真机确认的 kbList → Course
      week_parser.dart           # 正方周次文本解析
    widgets/
      import_preview_dialog.dart # 写库前预览确认
  features/widget/
    providers/
      widget_sync_providers.dart  # allCourses/sectionTimes provider + WidgetSync
    services/
      widget_payload_builder.dart # 整周课表快照 JSON（纯 Dart）
      widget_bridge.dart          # MethodChannel 封装
  features/settings/{pages,providers}/
  services/
```

Android 原生（`android/app/src/main/kotlin/cn/edu/ncpu/timetable/ncpu_timetable/`）：

```text
MainActivity.kt              # 注册 MethodChannel，保存载荷并刷新小组件
widget/
  WidgetChannel.kt           # 通道名/方法名约定
  WidgetPayload.kt           # 载荷数据类 + CivilDate（自写 EpochDay 算法）
  WidgetPayloadParser.kt     # org.json 解析，版本不符返回 null
  WidgetScheduleCalculator.kt# 纯 Kotlin 周次/星期计算（可 JVM 单测）
  WidgetRenderer.kt          # RemoteViews 渲染
  TimetableWidgetProvider.kt # AppWidgetProvider
  WidgetPreferences.kt       # SharedPreferences 存储
```


## Import Feature Architecture

- **SchoolAdapter**（抽象类）：定义学校元数据、`canHandle` 和 `parseTimetable(rawResponse, semesterId)`。
- **sealed ImportResult**：`ImportSuccess` / `ImportInterfaceNotYetDiscovered` / `ImportError`，强制调用方处理所有状态。
- **NcpuAdapter**：调用 `NcpuTimetableParser` 解析已确认的正方教务 `kbList`；空数据返回 `ImportInterfaceNotYetDiscovered`，结构异常返回 `ImportError`。
- **NavigationPolicy**：纯 Dart 逻辑，接收 `NcpuSchoolConfig`，对 URI 做 host/scheme 白名单校验，返回 `NavigationDecision`。可在无平台环境下单元测试。
- **ImportLoginPage**：先展示阻断式 HTTP 风险确认页；用户明确继续后才创建 `InAppWebView`。同源 XHR/fetch 脚本捕获课表响应：原始响应只进内存，Debug 脱敏形状走独立通道和采集页。用户打开学生课表查询后点击导入，先预览，再确认写入。
- **NcpuTimetableParser**：按 key 读取 `kcmc`、`xqj`、`jcs/jcor/jc`、`zcd`、`cdmc`、`xm`、`xf`、`kcxz`，忽略 `xsxx` 和噪声字段；同一教学班不同周次段使用周次指纹形成不同 ID。
- **Android 插件来源**：根 `pubspec.yaml` 用 path override 固定项目内 `third_party/flutter_inappwebview_android` 1.1.3；仅修正 AGP 9 不兼容的 ProGuard 默认文件，避免依赖本机 Pub Cache 改动。
- **平台安全配置**：
  - Android：`network_security_config.xml` 仅对 `jwxt.ncpu.edu.cn` 放行 HTTP cleartext。
  - iOS：`Info.plist` NSAppTransportSecurity 域名级例外（`NSExceptionAllowsInsecureHTTPLoads`）。

## Data Flow

页面 → Riverpod provider/controller → repository → Drift database → SQLite。

教务导入：风险确认 → 受限 WebView 自行登录 → 打开学生课表查询 → 同源脚本把课表响应送入内存 → `SchoolAdapter.parseTimetable` → `diffImportedCourses` 与上次导入比对 → 预览（含新增/移除）→ 用户确认 → `replaceImportedCourses` → 离开页面时 `ImportSessionCleaner` 清 HTTP 缓存并清空内存响应。适配器不接收 Cookie 或其他凭证；原始响应不落盘，学校原始字段不得进入 UI。

周次与日期：`SemesterService` 统一提供 `currentWeek`（超出学期时封顶到 `totalWeeks`）、`termStatus`（学期前/中/后，用于发现学期设置过期）与 `dateFor`（第 N 周星期 X 的日期）。课表页在 `termStatus != within` 时显示提示条跳转设置页。

桌面小组件：课表数据变化 / App 回到前台 → `WidgetSync`（合并重复推送）→ 查库取整周快照 → `buildWidgetPayload` → MethodChannel → 原生 SharedPreferences → 系统周期更新或推送触发重绘。原生侧按设备日期自行计算周次与当天课程，因此 App 未运行也能显示正确内容；详细协议与验收步骤见 `knowledge/home_widget.md`。

## Domain Relations

- Semester 1:N Course。
- Course.weeks 表示生效教学周；weekday 使用 1（周一）至 7（周日）。
- SectionTime 定义可配置节次时间。
- Course.source 区分 `manual` 与 `ncpu`，重新导入只替换 `ncpu`。

## Notifications

课程数据稳定后由 NotificationService 根据课程和提醒偏好生成本地通知；重新导入时仅重建目标学期通知。
