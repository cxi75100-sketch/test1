# 2026-09-13 TASK-062「校园线路图」重做报告

Status: **代码与模拟器验证完成，等待用户视觉验收与「是否出包」的决定**
Scope: TASK-062（含 TASK-061 遗留的四处问题修正）
Evidence date: 2026-09-13
Related: `knowledge/changelog.md`、`knowledge/testing.md`、`knowledge/current_state.md`、`knowledge/tasks.md`、`knowledge/architecture.md`

---

## 摘要

用户先后否决了 `v1.0.2` 的手账卡片风格与 TASK-061 的校园编辑日历风格，要求「不局限于课表 App」。本轮先把首页重做成**校园线路图**：整周七天以线路站点概览常驻首屏、课程按节次落在站点上；方向得到用户认可后，再把同一套语言铺满全 App，并修完上一轮验收留下的四个问题。

结论：

1. `flutter analyze` 无问题，`flutter test` **140/140**。
2. Release 正式签名包经 `adb install -r` 覆盖安装到 `ncpu_api36`，冷启动 `Status: ok` / COLD / **760 ms**，保留本机数据。
3. 日间与夜间的首页、整周、课程详情、设置页、新增课程表单均以 1080×2400 真实画面复核；logcat 无致命异常、无布局溢出、无崩溃或 ANR。
4. 上一轮遗留的四处问题全部修完（见第三节对照表）。

边界：OnePlus PLC110 真机未安装本包，厂商启动器/OLED 低亮度下的观感与「视觉是否达到用户期望」仍为 `UNVERIFIED`，由 TASK-055 跟踪。

---

## 一、设计语言：一屏一「线路」

这套语言只用三种元素表达信息，任何一处的取舍都可以回到这三条：

**站点（信息落点）**

- 顶部**七日概览条**：七天各一个站点，站点下方是当天课程数；今天是实心珊瑚色并放大，当前列对应站点高亮为品牌蓝。点任一天把那一列滚到视口左侧（`_WeekRouteStrip`）。
- 每列上午/下午半区内的**节次站点**：按 1-2 / 3-4 与 5-6 / 7-8 / 9-10 分格，格心画站点、站点之间连线（`_SlotRoutePainter`）；空半区只画空心站点。
- 详情页的**十站节次线路**：一天十节各一站，课程占用的节次实心（`_SectionRoute`），十站数量直接取自既有常量 `officialSectionTimes`。

**课程色只作为低饱和的「面」与「签」**（`lib/core/theme/course_colors.dart`）

| 用法 | 实现 | 系数（日间 / 夜间） |
|---|---|---|
| 课程面 | `courseSurfaceTint(accent, base, isDark:)` | 左端 13% / 26%，右端 2.5% / 8%，混进基础表面 |
| 节次签 | `courseBadgeTint(accent)` | 课程色 18% 透明度 |

三处课程卡（今日列表、整周窄卡、详情头卡）共用上表，页面里不再各写一套透明度；`courseGradientColors()` 已删除（它只服务详情页，且属于被否决的深色高饱和语言）。

**中性表面 + 蓝色焦点**

- 正文/弱信息/边界/抬升层全部走 `ColorScheme` 语义色；`AppPalette` 只留中性纸面、夜间分层、品牌蓝与珊瑚。
- 珊瑚色只出现在 app 标题下的小标签（`PREFERENCES` / `COURSE CARD`）与设置页分组小竖条上，不再做大面积铺底。
- 设置页身份卡从「海军蓝渐变板 + 亮黄校徽 + 薄荷徽章」改为中性表面 + `primaryContainer` 校徽，抽成 `_SchoolIdentityCard`。

**背景**：一层纵向渐变 + 两条低对比线路曲线（曲线上带站点），**移除全部径向环境光斑**；不使用重复纹理、圆点阵或实时模糊。

---

## 二、本轮改动

| 文件 | 改动 |
|---|---|
| `lib/core/theme/course_colors.dart` | 新增 `courseSurfaceTint()` / `courseBadgeTint()`；删除 `courseGradientColors()` |
| `lib/features/timetable/widgets/course_card.dart` | 今日列表卡重做为整周窄卡的宽版：低饱和课程面 + 淡色节次签 + 右对齐时间 + 教室/教师图标；圆角 20 → 16（与 `cardTheme` 一致）；去掉海军蓝药丸与实心亮黄章 |
| `lib/features/timetable/pages/course_detail_page.dart` | 头卡改为同源课程面 + 淡色节次签 + 语义文字色；新增 `_SectionRoute` 十站线路；新增 `_CourseHero` |
| `lib/features/settings/pages/settings_page.dart` | 身份卡改为中性表面 + 蓝色焦点；抽成 `_SchoolIdentityCard` 并加 `settings-identity-card` key |
| `lib/core/widgets/ambient_background.dart` | 移除两处径向光斑；`_OrbitPainter` → `_RouteWatermarkPainter`，画两条曲线与落在曲线上的站点 |
| `lib/features/timetable/pages/timetable_page.dart` | 空日列不再画整列卡片；「沿线无课」移到线路上端；窄卡改用共享 tint；切换按钮固定 48dp |
| `lib/core/theme/app_palette.dart` | 文档修正：`ink` 是日间正文色（等于 `onSurface`），不再是品牌深蓝 |
| `test/timetable_page_test.dart` | 新增 4 项回归（见第四节） |
| `test/theme_preference_test.dart` | 新增身份卡断言（无渐变、取 `surface`、有描边） |

整周课表的列宽、首屏两天半、当前周从今天开始循环排列、其他周按周一至周日、列内无纵向滚动等既有行为均未改动。

---

## 三、上一轮遗留问题对照

| 上一轮发现 | 现状 | 证据 |
|---|---|---|
| 视觉语言只换了一半：今日列表卡与详情页仍是海军蓝药丸 + 亮黄节次章 | 已迁移；App 内不再出现该组合 | 实画（今日卡日间/夜间、详情头卡日间/夜间）+ 测试断言节次签为低透明度淡色 |
| 任务书要求移除的径向环境光斑仍在 | 已移除，只留渐变与线路水印 | 实画（背景无块状氛围光） |
| 空日列是占满整列的空白大卡 | 改为无填充、无圆角，只留两条极淡列轨；标签贴在线路上端 | 实画 + 测试断言 `color`/`borderRadius` 为 null 且标签距列顶 < 35% 高度 |
| 「今日/整周」切换按钮触控高度约 41dp | 固定 48dp | 测试断言 ≥48；真机语义树 bounds 126 px ÷ 2.625 ≈ 48 dp |

附带修正的两处一致性问题：`CourseCard` 硬编码圆角 20（与主题 16 不一致）；`AppPalette.ink` 已变为与 `onSurface` 同值，文档未说明。

---

## 四、验证证据

**自动化**

- `flutter analyze`（`R:\`）：`No issues found`。
- `flutter test`：**140/140**。本轮新增 4 项：
  1. 今日列表卡与整周卡共用 `courseSurfaceTint`（圆角 16），节次签等于 `courseBadgeTint` 且透明度 < 0.3；
  2. 「今日/整周」切换按钮高度 ≥ 48dp；
  3. 空日列无填充色与圆角，「沿线无课」距列顶 < 35% 高度；
  4. 详情页十个节次站点齐全，课程占用节次为实心、未占用为透明描边。

**构建与安装**

- `flutter build apk --release --target-platform android-x64`：33.1 s，正式证书（SHA-256 `2e8ac142…`）。
- `adb install -r` 覆盖安装：保留本机 13 条课程与学期设置（版本号未变，无需卸载）；冷启动 `Status: ok` / `LaunchState: COLD` / 760 ms。

**模拟器实画清单**（`ncpu_api36` / API 36 / x86_64 / 1080×2400 / density 2.625）

- 日间：今日（空态、含课列表卡）、整周（首屏、上一周、路线图定位、横滑至周六）、课程详情、新增课程表单、设置页。
- 夜间：整周、课程详情、设置页、今日（空态、含课列表卡）。
- 交互：今日/整周切换、路线图点击定位、上一周/本周/下一周、课程卡进详情、新增与删除课程、编辑课程（补教室与教师）、三档外观切换。

**日志与数据边界**

- logcat 无 `FATAL EXCEPTION`、`RenderFlex overflowed`、`MissingPluginException`，无崩溃或 ANR；按 App pid 过滤 `cookie|session|token|password|JSESSIONID` 命中 0。
- 验证用临时课（含教室/教师）在每次验证后都从 App 内删除，课程数回到 13。
- 验证结束后：外观恢复「跟随系统」、系统夜间开关恢复 `no`、设备端无残留录屏文件、模拟器保持运行。

**演示素材**

共 22 张（13 张整屏 + 9 张 2 倍局部放大图），保存在**仓库外**：公开仓库不放含真实课程名、教室与教师名的截图。报告中不记录具体课程与教师信息。

---

## 五、决策与实施要点

1. **系数提到 `course_colors.dart` 而不是留在页面里**：这是「视觉语言只换一半」的根因——三处课程卡各自写透明度，改一处就会漏两处。现在页面只能拿到两个函数。
2. **十站取自 `officialSectionTimes`**：不为「十节」新增常量，作息表本身就是唯一事实来源，作息改了站点数自动跟着改。
3. **空日列保留列轨、不删列**：直接删掉会让网格错位、七天不再完整、横滑长度跳变。改为去掉卡片外形与标签居中，保留结构。
4. **详情页文字改用语义色**：原实现把白字压在深色渐变上，改成浅色课程面后白字必然不可读；这是换底色时必须一起改的地方，不是顺手优化。
5. **数据边界**：本轮把一处写进知识库的真实课程名改为泛指（`knowledge/testing.md`）。**遗留发现**：`knowledge/ncpu_import.md` 中 `cdmc` 字段的格式示例仍是真实教室串（早于本轮提交、已公开），它是字段格式说明的实测样例，删改会降低文档保真度，建议用户单独决定是否泛指化。
6. **`dart format` 存量差异**：`dart format --set-exit-if-changed lib test` 会改写 11 个与本轮无关的既有文件（`lib/features/import/` 下 7 个 + 4 个测试），判断为格式化器版本升级带来的差异。已把这 11 个文件恢复原状，**没有**把格式化混进功能改动。若要统一格式，应作为独立提交一次性完成。

---

## 六、证据边界与未验证项

- `UNVERIFIED`：OnePlus PLC110 真机安装本包；厂商启动器与 OLED 低亮度下的实际观感；长时间使用的视觉疲劳。
- `UNVERIFIED`：教务导入风险门与导入预览页的夜间视觉（本轮未改动这两页，也未逐页复核）。
- 未做：出包与发行版、`v1.0.2` 之后的版本号递增、真机安装。本轮改动随本报告一并入库，**尚未出包**。
- 视觉是否达到用户期望由用户判断；个人判断不能替代验收，TASK-055 不提前关闭。

---

## 七、后续建议

1. **先做视觉验收**：在模拟器或真机上过一遍日间/夜间的主流程；若方向确认，再谈出包。
2. **出包（若验收通过）**：沿用同一 keystore，`versionCode +1`（`1.0.3+4`），可直接覆盖安装；发布前仍走 `INTERNET` 权限、正式证书、模拟器装 release、冷启动与日志无会话字段这几项检查（`knowledge/release.md`）。
3. **真机落地顺序不变**：换正式签名必须卸载、会丢本机课表与登录态，因此必须在 TASK-019 / TASK-039 的真机验收之后。
4. **格式统一单独提交**：把第五节第 6 条的 11 个文件作为一次纯格式化提交，与功能改动分开，便于 review 与回滚。
5. **多校接入（TASK-047）继续顺延**，等视觉收口与 D1–D6 决策。
