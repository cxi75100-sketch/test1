# Android 本地上课提醒

## 已实现行为

- `CONFIRMED`：提醒默认关闭，默认提前 15 分钟；用户可选 5、10、15、30 分钟。
- `CONFIRMED`：只有用户主动开启时才申请 Android 通知权限；通知权限被拒后保持关闭。
- `CONFIRMED`：按当前学期的教学周、星期和上课时间生成未来提醒；课程显式时间优先，否则复用官方节次时间与教学楼特殊作息。
- `CONFIRMED`：课程、学期、节次时间或提醒偏好变化，以及 App 回前台时，取消旧的待触发通知并重建。
- `CONFIRMED`：精确闹钟权限不可用时使用非精确空闲调度，并在设置页提示“系统可能延迟提醒”。
- `CONFIRMED`：提醒标题为“课程名 即将上课”，正文只含上课时间与教室；不包含账号、姓名、Cookie、Session 或 Token。
- `CONFIRMED`：最多安排未来 480 条，避免逼近部分 Android 厂商的待触发闹钟上限。

## Android 平台配置

- 依赖：`flutter_local_notifications`、`timezone`；校园时区固定为 `Asia/Shanghai`。
- 权限：插件合并 `POST_NOTIFICATIONS` / `VIBRATE`；项目声明 `SCHEDULE_EXACT_ALARM` 与 `RECEIVE_BOOT_COMPLETED`。
- Receiver：`ScheduledNotificationReceiver` 接收触发事件，`ScheduledNotificationBootReceiver` 处理开机与应用更新后的恢复。
- 图标：`android/app/src/main/res/drawable/ic_stat_school.xml`，符合通知状态栏单色图标要求。

## 两个必须保留的前提（2026-09-13 修复，见 ISSUE-017 / ISSUE-018）

- **通知图标 `drawable/ic_stat_school` 必须用 `android/app/src/main/res/raw/keep.xml` 的 `tools:keep` 保住。** 它只被 Dart 代码按名字引用，release 的资源裁剪会删掉它，结果是插件 `initialize()` 抛 `invalid_icon`、开启提醒直接失败（v1.0.0～v1.0.2 三个已发布版本都受影响）。更名或换图标时同步维护 keep 列表。
- **任何“现在”的比较都要用校园挂钟基准**（`campusWallClockNow()`），不要用 `DateTime.now()`。设备时区不是 UTC+8 时，用设备本地时间会把当天已过的课判成未来，插件对过去的 `scheduledDate` 会抛异常；而 `replaceAll` 是“先清空再逐条写入”，一条异常就会把整批排程清空且界面仍显示“已开启”。进插件前用 `futureReminders()` 再挡一次。

## 验收结果（2026-09-13，`ncpu_api36` / API 36 / x86_64，release 包）

设备时钟为 UTC（`persist.sys.timezone = GMT`，绝对值正确），校园侧按 UTC+8 计算，正好覆盖“设备时区与校园不一致”这条分支。

| 步骤 | 结果 | 关键证据 |
|---|---|---|
| 1 覆盖安装、冷启动、默认关闭 | `CONFIRMED` | 冷启动进入设置页显示「上课提醒 已关闭 · 默认提前 15 分钟」 |
| 2a 通知权限弹窗 | `CONFIRMED` | 点开关后系统弹出「Allow 南工课表 to send you notifications?」；允许后 `POST_NOTIFICATIONS: granted=true flags=[USER_SET]` |
| 2b 精确闹钟·不允许 | `CONFIRMED` | 继续弹出系统「Alarms & reminders」页，直接返回后调度降级为非精确：闹钟 `window=+1h0m0s0ms` |
| 2c 精确闹钟·允许 | `CONFIRMED` | `cmd appops set ... SCHEDULE_EXACT_ALARM allow` 后同一门课变为精确：`window=0 exactAllowReason=permission` |
| 3 临时 ASCII 课程 + 提前量 | `CONFIRMED` | 临时课 `ZZ-Reminder`（周日 5-6 节），提前量 30/10/5 分钟分别验证 |
| 4 实际到点通知 | `CONFIRMED` | 计划 `05:30:00`（UTC）= 13:30 +08:00 = 第 5 节 14:00 减 30 分钟，到点收到通知：标题「ZZ-Reminder 即将上课」、正文「14:00」，投递记录 `channel=course_reminders importance=4 icon=...id=0x7f08005e`；点击通知不崩溃（pid 不变） |
| 5 数据变化重排 | `CONFIRMED` | 改课（5-6 节→7-8 节）后触发点精确变为 15:25；改提前量 30→10→5 分钟依次变为 15:45 / 15:50；旧时间的闹钟不残留；总数 187→206 只增加该课份数，无重复累积 |
| 6 重启恢复 | `CONFIRMED` | `adb reboot` 后未手动打开 App，待触发闹钟已由 `ScheduledNotificationBootReceiver` 恢复（含当天那条精确闹钟）；App 进程由该接收器拉起 |
| 7 关闭提醒 | `CONFIRMED` | 待触发闹钟 **196 → 0**；`dumpsys alarm` 的历史区可见对应的 `Reason=alarm_cancelled` 记录；提醒状态跨重启保留（重启后仍显示「已开启 · 提前 5 分钟」） |

`UNVERIFIED`（仍需真机）：厂商省电策略/后台限制下的到点可靠性（OriginOS / ColorOS），以及通知在厂商通知中心的展示与折叠行为。

## 真机验收（TASK-039）

前置：连接一台 Android 真机，确认 `adb devices -l` 状态为 `device`。不要更改系统日期/时间；不要输出真实课程详情。

2026-09-12 环境补充（TASK-040）：AVD `ncpu_api36`（API 36 / google_apis / x86_64 / Launcher3）已就绪且实测可运行本项目（x86_64 原生 SQLite 与通知插件均正常）。第 3–7 项（实际到点、数据变化重排、关闭取消、重启恢复）可在模拟器上完成：模拟器允许修改系统日期/时间与重启，且造测试数据不会触及真机生产库。第 2 项的权限弹窗可在模拟器对照，但**厂商省电/后台限制仍必须真机**验证。在模拟器上验收时同样不得输出真实课程详情。

2026-09-13 更正：该模拟器实测时区是 `GMT` 而不是 `Asia/Shanghai`（时钟绝对值正确）。这不是缺陷——提醒按校园时区换算，与设备时区无关（已按上表验证）——但**验收记录必须写清设备时区**，因为 ISSUE-018 正是时区不一致时才暴露的。

1. 覆盖安装最新 Debug APK，冷启动进入设置页，确认“上课提醒”默认关闭且显示默认提前 15 分钟。
2. 开启提醒：确认 Android 13+ 出现通知权限请求；允许后读取设置页状态。若系统提供“闹钟和提醒”权限，分别记录允许与不允许时 App 的提示，不记录其他系统设置内容。
3. 新建一条 ASCII 名称的临时手动课程，时间设置为当前时间后 6–10 分钟，提醒提前量设为 5 分钟；退出 App 后等待通知。
4. 验收通知：课程开始前收到一条通知，标题/时间/教室正确；点击通知不会崩溃。记录到达时间与计划时间的差值，不截取其他通知。
5. 修改临时课程时间并回到前台，确认旧时间不再通知、新时间只通知一次；再切换提前量到 10 分钟，重复确认重排。
6. 重启手机后等待另一条临时课程提醒，确认未来通知能恢复。厂商若要求后台运行权限，只记录限制与用户选择，不代替用户开启高权限。
7. 关闭提醒，确认后续临时课程不再通知；删除临时课程。

## 验收判定

- `CONFIRMED`（2026-09-13，模拟器）：权限弹窗、系统精确闹钟状态与降级、到点通知、数据变化重排、关闭取消、重启恢复六项已在上表逐项取证；其中“精确闹钟降级”两种分支都实测过。仍未覆盖的只有厂商省电策略下的后台/到点可靠性，需真机。
- `UNVERIFIED`：仅有单元测试、APK 构建或清单读取时，不能宣称真机通知已完成。**注意本文件记过一次教训**：TASK-014 的“APK 静态校验通过”无法发现 release 资源裁剪删掉通知图标（ISSUE-017），静态检查不能替代装机运行。
- `BLOCKED`：无已授权 Android 设备，或厂商系统不允许后台/闹钟调度且用户未选择授权。
