# 桌面小组件（Android）

## 目标

主屏上直接看到「今天要上的课」，不需要打开 App。展示「第 N 周 · 周X」表头与今天的课程（节次时间 + 课名 + 教室 + 课程色条）；无课显示「今天没有课」，学期前后显示对应状态。点击任意位置打开 App。

## 设计要点（为什么 App 关着也准）

小组件不能依赖 App 在后台运行，因此分工是：

- **Flutter 只推「整周原始数据」**：开学周一、总周数、全部课程（星期/节次/生效周次）、节次时间、课程颜色。
- **Android 侧自行计算今天是第几周、周几、有哪些课**：用设备时钟，算法与 `SemesterService.currentWeek` 对齐。

结果是 App 一周不打开，小组件每天仍然显示正确内容；反过来，App 内手动切到「第 5 周」不会影响小组件（它始终按真实当前周显示）。

## 数据流

```text
课程增删改 / 学期设置 / App 启动 / App 回到前台
        ↓
WidgetSync（同一轮数据变化只推一次）
        ↓  查库取快照：firstSemester + watchCourses(semesterId).first + allSectionTimes
buildWidgetPayload()  →  JSON
        ↓  MethodChannel "cn.edu.ncpu.timetable/widget" / "updatePayload"
MainActivity → WidgetPreferences.save → TimetableWidgetProvider.refreshAll
        ↓
WidgetScheduleCalculator.evaluate(payload, today)   ← 设备日期
        ↓
WidgetRenderer → RemoteViews → 主屏
```

系统每 30 分钟（`updatePeriodMillis = 1800000`）也会调用一次 `onUpdate` 重绘，覆盖凌晨跨天与「App 长期没打开」。这条通路不需要 `AlarmManager`、`BOOT_COMPLETED` 或任何新权限。

## 载荷协议（schemaVersion = 1）

Dart 侧 `buildWidgetPayload`（`lib/features/widget/services/widget_payload_builder.dart`）与 Kotlin 侧
`WidgetPayloadParser`（`android/app/src/main/kotlin/cn/edu/ncpu/timetable/ncpu_timetable/widget/WidgetPayloadParser.kt`）
必须同时修改 `schemaVersion`，任一侧版本不匹配时原生侧返回 null 并降级为「打开 App 完成课表设置」。

```json
{
  "schemaVersion": 1,
  "semester": { "name": "当前学期", "firstWeekMonday": "2026-08-31", "totalWeeks": 20 },
  "courses": [
    {
      "name": "高等数学", "classroom": "A101",
      "weekday": 1, "startSection": 1, "endSection": 2,
      "startTime": "08:20", "endTime": "09:50",
      "weeks": [1, 2, 3], "colorHex": "#5B8FF9"
    }
  ],
  "sectionTimes": [{ "section": 1, "startTime": "08:20", "endTime": "09:00" }]
}
```

说明：

- `firstWeekMonday` 是纯日期字符串（`yyyy-MM-dd`），避免两端时区解析偏差。
- Dart 侧按 `CourseTimeService` 把课程明确时间或教学楼推导时间写入 `startTime`/`endTime`；明志楼、明德楼、至善楼第 3/4 节使用提前作息，其他场所使用通用作息。原生侧仍保留 `sectionTimes` 兜底，均缺失时显示「第X-Y节」。
- `colorHex` 来自 `lib/core/theme/course_colors.dart`，与课表 UI 同一取色规则（`colorKey.abs() % 8`）。
- 载荷只含课表数据，不含账号、Cookie、Session 或 Token。

## 原生计算规则

`WidgetScheduleCalculator`（纯 Kotlin，不 import Android，可 JVM 单测）：

| 条件 | 结果 |
| --- | --- |
| 载荷缺失/损坏/版本不符 | `Empty` → 「打开 App 完成课表设置」 |
| `today < firstWeekMonday` | `NotStarted` → 「学期还没开始」 |
| `week = (today - firstWeekMonday)/7 + 1 > totalWeeks` | `Finished` → 「学期已结束」 |
| 其余 | `InTerm(week, weekday, items)` |

- 日期用自写 civil-days 算法（`CivilDate.toEpochDay()`），**不使用 `java.time`**：minSdk 24 上 `java.time` 需要 API 26 或额外 desugaring 依赖。
- ISO 星期（1 = 周一 … 7 = 周日）由 `(epochDay + 3) mod 7 + 1` 得出，与 Dart `DateTime.weekday` 一致。
- 2026-09-07 是周一，Kotlin 日期算法单测以此为固定样例；当前实际学期第一周周一为 2026-08-31。

## 刷新时机

1. 课表数据变化：`widgetSyncProvider` 监听 `allCoursesProvider` / `semestersProvider` / `sectionTimesProvider`。
2. App 回到前台（`WidgetsBindingObserver` → `resumed`）。
3. 系统周期更新（`updatePeriodMillis`，最短 30 分钟）。
4. 用户调整小组件尺寸（`onAppWidgetOptionsChanged`）。

## 文件清单

Dart：

- `lib/core/theme/course_colors.dart`
- `lib/features/widget/services/widget_payload_builder.dart`
- `lib/features/widget/services/widget_bridge.dart`
- `lib/features/widget/providers/widget_sync_providers.dart`
- `lib/app.dart`（同步作用域 + 生命周期观察）
- `lib/core/database/app_database.dart`（`watchSectionTimes` / `allSectionTimes`）

Android：

- `android/app/src/main/kotlin/.../widget/{WidgetPayload,WidgetPayloadParser,WidgetScheduleCalculator,WidgetRenderer,TimetableWidgetProvider,WidgetPreferences,WidgetChannel}.kt`
- `android/app/src/main/kotlin/.../MainActivity.kt`
- `android/app/src/main/res/layout/widget_timetable.xml`、`widget_row.xml`
- `android/app/src/main/res/xml/timetable_widget_info.xml`
- `android/app/src/main/res/drawable/widget_background.xml`
- `android/app/src/main/res/values/{strings,colors}.xml`、`values-night/colors.xml`
- `android/app/src/main/AndroidManifest.xml`（receiver）
- `android/app/src/test/kotlin/.../widget/WidgetScheduleCalculatorTest.kt`

## 真机验收步骤（TASK-019，待设备）

1. `flutter devices` 确认设备 → `flutter run --debug`。
2. 在 App 内确认已有课程（无则手动加一节今天的课）。
3. 回到主屏 → 长按空白 → 添加小组件 → 找到「南工课表」。
4. 核对表头周次/星期与今天课程、时间、教室、颜色。
5. 在 App 内新增/删除一节今天的课，回主屏确认小组件立即刷新（无需重开 App）。
6. 点击小组件，确认打开 App 并停在课表页。
7. 调整小组件尺寸，确认行数变化且超出时显示「还有 N 门课」。
8. 跨天验证：临时把系统日期改到明天（或下周同一天），确认小组件重算周次与课程；改回后复原。若不便改日期，可改学期开学周一使「今天」落到别的周次。
9. 记录结果到 `knowledge/testing.md` 与 `knowledge/issues.md`（若有问题）。

## 已知局限与风险

- `updatePeriodMillis` 最细 30 分钟：跨天后最多延迟 30 分钟自动换天（打开 App 或点小组件会立即修正）。
- 小组件未运行过 App 时只能显示「打开 App 完成课表设置」。
- 不同启动器对 RemoteViews 的尺寸/字号处理存在差异，实测为准。
- 学期边界展示与 App 内不同（见上表），属有意设计。
- 未在真机验证前，小组件渲染结论一律保持 `BLOCKED`。

## 验证状态

- `CONFIRMED`：`flutter analyze` 无问题；`flutter test` 53/53；`gradlew :app:testDebugUnitTest` 13/13；Debug APK 构建通过，清单含 receiver 与 appwidget 元数据，未新增权限。
- `BLOCKED`：真机渲染、添加/缩放、跨天刷新、点击打开 App。
