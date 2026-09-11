# Zcode 最近改动与 Gitee 仓库审查报告

审查时间：2026-09-11 19:54 +08:00
审查范围：`938c78c..6b321a4`（基线收尾后的 7 个提交）、当前 `master`、公开远端 `https://gitee.com/chenxihh/test_c.git`。由于仓库没有 Zcode 专属提交标记，本报告把基线收尾后的全部提交作为“昨天让 Zcode 修改”的候选范围审查。

## 结论

- 未发现 P0/P1 阻断级缺陷；当前源码可通过静态分析与现有自动测试。
- 发现 3 个 P2（应在 release 前处理）和 1 个 P3（低风险健壮性问题）。
- `CONFIRMED`：本地 `HEAD`、`origin/master` 和 `git ls-remote` 均为 `6b321a4e64efd64d79b7c5f7168fc46bbf99002c`。
- `CONFIRMED`：启发式敏感信息扫描未发现已提交的密码、私人令牌、Cookie、Session、私钥、数据库或 APK；`.zcode/` 已加入 `.gitignore`。
- `CONFIRMED`：公开 Git 提交元数据包含真实 Gmail 地址；这不是凭据泄露，但属于身份信息公开。

## Findings

### P2-1 导入预览会把“课程详情已变化”显示成“与上次导入一致”

证据：

- `lib/features/import/services/import_diff.dart:20-36` 只按 `Course.id` 判断新增/移除。
- 解析器的 id 仅覆盖教学班、星期、节次和周次，不覆盖课程名、教师、教室、备注等字段。
- `lib/features/import/widgets/import_preview_dialog.dart:141-145` 在 id 集合不变时显示“与上次导入一致，没有新增或移除”。
- `test/import_diff_test.dart:83-90` 还明确锁定了“同 id 改课程名仍无差异”。

影响：教务调整教室、教师、课程名或课程性质时，确认导入后数据库确实会被新值替换，但摘要仍告诉用户“与上次导入一致”。用户无法从差异区获知这些变动，容易误判课表没有变化。

建议：给 `ImportDiff` 增加 `changed`（旧值/新值配对），至少比较名称、教师、教室、星期、节次、周次与备注；如果暂不实现详情比较，应把文案改为“没有新增或移除；课程详情变化未比较”。

### P2-2 知识库当前状态互相矛盾，会误导接手 Agent

证据：

- `knowledge/tasks.md:13-15` 已确认小组件可添加、可渲染、点击可打开 App，仅剩溢出和跨天重算。
- `knowledge/current_state.md:17,48,86,110` 仍称添加、渲染、点击均未验证。
- `knowledge/home_widget.md:129-146` 的进度和验证状态仍把点击打开列为待完成。
- `knowledge/testing.md:107-108` 仍称完整教务导入未验收、桌面小组件全部 BLOCKED，但同文件 `91-103` 已记录对应真机验收通过。

影响：新 Agent 按项目规定先读知识库时，会重复执行已完成的真机步骤，甚至再次为了制造溢出而改写生产数据库；这与本次已经发生并回退的数据库编码事故直接相关。

建议：以 `knowledge/tasks.md:13-15` 为 TASK-019 当前事实源，以 TASK-021 的 Done 记录为导入验收事实源，一次性同步 `current_state.md`、`home_widget.md`、`testing.md`，并删除或标注过期快照。

### P2-3 公开仓库的全部提交暴露了个人 Gmail 地址

证据：`git log --all --format='%h %an <%ae>'` 显示当前 9 个提交均使用个人 Gmail 地址（本报告已脱敏）。仓库知识库已明确要求不记录个人身份数据；虽然源码文件扫描没有发现身份字段，Git 元数据仍会被公开仓库展示。

影响：邮箱可被抓取、关联身份或用于垃圾邮件。它不是密码或令牌，不构成账户直接失陷。

建议：立即把后续提交邮箱切换为 Gitee 的隐私/无回复邮箱或专用开发邮箱。是否重写既有 9 个提交历史应由用户单独决定；重写会改变全部提交哈希并需要强制推送，不应在审查任务中擅自执行。

### P3-1 `diffImportedCourses` 只过滤旧列表中的手动课程

证据：`lib/features/import/services/import_diff.dart:28-40` 对 `previous` 过滤 `CourseSource.ncpu`，但直接遍历 `next`；函数注释却承诺“只反映教务来源课程”。现有调用方传入解析器结果，当前生产路径全部为 `ncpu`，因此暂未造成用户可见错误。

影响：未来若调用方把混合来源列表传入 `next`，手动课程会被错误计为新增，API 行为与注释不一致。

建议：同时过滤 `next`，并新增“next 含 manual 时忽略”的单元测试。

## 正向确认

- 小组件布局把 RemoteViews 不支持的裸 `<View>` 换成 `<TextView>`，方向正确；Android 资源处理、原生单测构建均成功，知识库还记录了 OnePlus Android 16 真机复验。
- 导入流程在替换数据库前读取旧课表，避免差异基线被覆盖；手动课程仍由数据库替换逻辑隔离。
- HTTP 缓存清理与内存原始响应清理边界清楚；保留 Cookie/WebStorage 是已记录的用户取舍，不应误报为“已消除登录态风险”。
- 默认学期常量、学期前后提示和日期算法抽取均有自动测试覆盖。
- 第三方 WebView 补丁目录包含上游 `LICENSE`，未发现明显许可证文件缺失。

## 本轮验证

- `flutter analyze`（`R:\`）：通过，No issues found。
- `flutter test`（`R:\`）：103/103 通过。
- `gradlew :app:testDebugUnitTest`（`R:\android`）：BUILD SUCCESSFUL；任务为 UP-TO-DATE，最近记录为 13/13。
- `gradlew :app:lintDebug`：Lint 完成源码分析，报告除 6 个非阻断警告外未列出源码错误，但任务最终失败；2 个 error 均来自被 Git 忽略的本机 `android/local.properties` 路径转义格式，不属于远端仓库内容。不能把本轮 Android Lint 报告为“通过”。
- 设备状态：`adb devices -l` 为空。本轮不能独立复现真机上的小组件与教务导入结论；这些结论仅由仓库中已有的真机记录支持。
- Gitee 网页抓取未取得页面正文；远端存在性、公开 fetch 能力和提交一致性通过 `git fetch`、`git ls-remote` 实际验证。

## 推荐处理顺序

1. 先修 P2-1，避免导入摘要误导用户，并补“详情变化”测试。
2. 同步四份知识库状态，关闭已完成项，避免再次进行危险的真机数据库注入。
3. 修改后续 Git 作者邮箱；是否历史重写另行确认。
4. 顺手修 P3-1，并在可控的 ASCII 临时数据或测试数据库中覆盖小组件溢出分支；不要再直接向真机生产库注入中文 SQL。
