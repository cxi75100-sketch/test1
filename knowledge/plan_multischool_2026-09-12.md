# 多校接入与校历适配计划书

Status: **待用户决策**（本文件只做设计，不含代码改动）
Date: 2026-09-12
Scope: 让「南工课表」从单校硬编码演进为可接入多所学校的架构，并解决各校校历/作息时间不同的问题。

---

## 1. 目标与非目标

### 目标

1. 接入第二所、第三所学校时，**不需要修改领域模型和课表 UI**，只新增配置与解析逻辑。
2. 各校校历（学期起止、教学周数）与作息（节次数、每节时间、上下午划分）**可配置、可被用户校正**。
3. 校历数据出错时，App **必须显式暴露不确定性**，而不是静默按错误周次显示、发错提醒。

### 非目标（本计划不做）

- 不做后端、账号或云同步（延续 DEC-002）。
- 不自动抓取教务系统的校历（接口未知、格式各异、随时变更，无法可靠）。
- 不改变安全边界：凭证仍然只在官方 WebView 输入，App 不接触 Cookie/Ticket（DEC-003、DEC-008）。
- 不做 iOS 桌面小组件。
- 不做「一个设备同时激活多所学校」之外的多租户能力（见 [D1](#d1-单校激活还是多校共存)）。

---

## 2. 现状盘点：单校假设清单

以下全部为读代码得到的 `CONFIRMED` 事实。**这张表就是本计划要拆掉的债务**。

| # | 位置 | 现状 | 多校下的问题 |
| --- | --- | --- | --- |
| 1 | `lib/models/school.dart` | `NcpuSchoolConfig` 的 `schoolName` / `loginUrl` / `acceptedHosts` / `allowedSchemes` 全是 `static const` | 新增学校必须改源码并重新打包 |
| 2 | `lib/features/import/providers/import_providers.dart:8` | `schoolAdapterProvider` 硬编码 `const NcpuAdapter()` | 没有注册表，无从选择 |
| 3 | `lib/features/import/adapters/ncpu_adapter.dart` | 依赖正方教务 `/jwglxt/kbcx/...` 与 `kbList` | 教务系统类型不同则完全不可用 |
| 4 | `lib/features/import/parsers/ncpu_timetable_parser.dart` | 按 `kcmc` / `xqj` / `jcs` / `zcd` / `cdmc` / `xm` 等 key 取值 | 字段名按系统而异 |
| 5 | `lib/features/import/parsers/week_parser.dart` | 解析正方周次文本（范围、单双周、离散、中英文括号） | 语法差异不大，**可复用**，但需按校校验 |
| 6 | `lib/services/course_time_service.dart:8` | `officialSectionTimes` 硬编码 10 节 | 各校节次数与每节时间都不同 |
| 7 | `lib/services/course_time_service.dart:33` | `_earlyBuildings = ['明志楼','明德楼','至善楼']`，并硬编码第 3/4 节的提前作息 | 这是「按教室选择作息变体」的特例，需泛化 |
| 8 | `lib/services/semester_service.dart:9,15` | `officialFirstWeekMonday = 2026-08-31`、`defaultTotalWeeks = 20` | 各校、各学期都不同 |
| 9 | `lib/core/database/app_database.dart:87` | `ensureDefaults()` **每次启动**用 `officialSectionTimes` 覆盖 `section_times` 全表；学期 id 硬编码 `default-semester` | **最危险的一条**：会把学校作息与用户修改冲掉 |
| 10 | `lib/models/course.dart:1` | `enum CourseSource { manual, ncpu }` | 学校名进了领域模型 |
| 11 | `lib/core/database/app_database.dart:47` + `replaceImportedCourses` | 靠 `source == 'ncpu'` 判等决定替换范围 | 换学校后无法区分来源，可能误删 |
| 12 | `lib/features/timetable/pages/timetable_page.dart` | 上午判定 `startSection <= 4`，格位断点 `[2,4]` / `[6,8,10]` | 12 节制或不同上下午划分的学校会错位 |
| 13 | `android/app/src/main/res/xml/network_security_config.xml` | 只放行 `jwxt.ncpu.edu.cn` | **构建期静态文件**，新增 HTTP 学校必须改 XML 重新打包 |
| 14 | `ios/Runner/Info.plist:73` | ATS 例外同样只有 `jwxt.ncpu.edu.cn` | 同上 |
| 15 | `lib/features/notifications/services/notification_scheduler.dart` | 时区固定 `Asia/Shanghai` | 跨时区用户/学校的提醒时间错误 |
| 16 | `android/.../WidgetScheduleCalculator.kt` | 原生侧第二套周次/日期实现（DEC-009 已记录双实现风险） | 校历模型一改，Dart 与 Kotlin 必须同步，否则小组件与 App 不一致 |

小结：**「哪些课」和「什么时候上」被混在了一起**。前者是教务系统差异（表 1–5、10、11），后者是校历与作息差异（表 6–9、12、15、16）。两类问题必须分开解。

---

## 3. 问题拆解：三个彼此独立的维度

| 维度 | 内容 | 是否需要新增模型 |
| --- | --- | --- |
| **A. 数据获取与解析** | 教务系统类型、登录入口、受信域名、课表接口、响应字段、身份校验方式 | 需要适配器注册表 + 每系统一个解析器 |
| **B. 校历语义** | 学期起止、第一周周一、总教学周数、周次定义、调休/停课 | 需要 `TermCalendar` |
| **C. 作息表** | 节次数量、每节起止时间、上午/下午/晚间划分、按教学楼或校区的差异 | 需要 `BellSchedule` |

**这三个维度完全正交。** 换学校通常只变 A 或只变 B/C；把它们耦合在一个 `NcpuXxx` 命名空间下，是当前无法扩展的根因。

---

## 4. 目标架构

### 4.1 领域模型（新增，均为纯 Dart 可单测）

```dart
/// 一所学校的完整档案：身份 + 网络策略 + 校历 + 作息。
class SchoolProfile {
  final String id;              // 'ncpu'，用于 source 判等与学期归属
  final String displayName;     // '南昌工学院'
  final NetworkPolicy network;  // loginUrl + acceptedHosts + allowedSchemes
  final TermCalendar term;      // 默认校历（可被用户/学期覆盖）
  final BellSchedule bell;      // 默认作息（可被用户覆盖）
  final String adapterId;       // 指向解析器实现
}

/// 学期时间语义。
class TermCalendar {
  final DateTime defaultFirstWeekMonday;
  final int defaultTotalWeeks;
  final WeekNumbering numbering;      // teaching | natural
  final List<CalendarException> exceptions; // 调休/停课/补课，阶段 3 起启用
}

class CalendarException {
  final DateTimeRange range;
  final ExceptionKind kind; // holiday | suspended | makeup
  final String note;
}

/// 作息表：节次 + 分组 + 变体。
class BellSchedule {
  final List<SectionSpec> sections;   // index, start, end, group
  final List<ScheduleVariant> variants;// 按教室/校区覆盖部分节次
}

class SectionSpec {
  final int index;
  final String start;
  final String end;
  final SectionGroup group;  // morning | afternoon | evening
}

class ScheduleVariant {
  final String id;                    // 'ncpu.mingzhi'
  final MatchRule match;              // classroomContains: [...]
  final Map<int, (String, String)> overrides; // 节次 → (起, 止)
}
```

关键点：`SectionGroup` 是**数据**而不是 UI 里的 `startSection <= 4`。课表格位、上下午标题、小组件分组全部从它派生。

### 4.2 数据优先级链（本计划的核心原则）

```
用户显式修改  >  学期记录（Semester 表）  >  学校档案默认值  >  应用兜底
```

配套的硬性规则：

1. **默认值只播种一次**，不得在每次启动时覆盖用户值。`ensureDefaults()` 现在的「每次启动全表 `insertOrReplace`」必须改成「仅在缺失时插入」或「仅在值等于上一版内置默认值时更新」。
2. **不允许用启发式猜校历**。TASK-028 已经证伪「按安装当天所在周的周一推断第一周」：它让第 2 周及以后安装的设备全部少算一周。宁可显示「校历未确认，请核对」。
3. 凡是被用户改过的字段，UI 上要能看出「已自定义」并支持一键恢复默认。

### 4.3 适配器注册与选择

```dart
final schoolProfileProvider = Provider<SchoolProfile>(...); // 由设置项选中的学校决定
final schoolAdapterProvider = Provider<SchoolAdapter>(
  (ref) => adapterRegistry.lookup(ref.watch(schoolProfileProvider).adapterId),
);
```

- `AdapterRegistry`：`adapterId → SchoolAdapter` 的映射，纯 Dart。
- `SchoolAdapter` 接口**保持不变**（`schoolName` / `loginUrl` / `canHandle` / `parseTimetable`），只把取值来源从 `static const` 改为注入的 `SchoolProfile`。这样现有 `NcpuAdapter` 与其测试改动最小。
- 解析器按教务系统归类复用：`kbList` 解析器服务所有正方学校，字段差异用 `FieldMapping` 配置而不是复制代码。

### 4.4 持久化改造

| 改动 | 说明 |
| --- | --- |
| `Semesters` 增加 `schoolId` | 一个学期属于一所学校；激活学校切换时不会串数据 |
| `CourseEntries` 增加 `schoolId` | 与 `source` 一起构成来源标识 |
| `CourseSource` 改为 `{ manual, imported }` | 学校身份移到 `schoolId`，领域模型不再含校名 |
| `replaceImportedCourses` | 从 `source == 'ncpu'` 改为 `source == imported && schoolId == 当前校` |
| `SectionTimeEntries` 增加 `variantId` 或 `schoolId` | 支持一个学校多套作息变体 |
| `Settings` | 新增 `active_school_id`、`school_profile_overrides`（用户覆盖的 JSON） |

迁移策略：Drift `MigrationStrategy` 升 schema 版本，老数据一律回填 `schoolId = 'ncpu'`、`source: ncpu → imported`。**必须在真机生产库副本上验证迁移**，并先备份（`knowledge/incident_2026-09-11_db_injection.md` 的教训）。

### 4.5 展示层去硬编码

- 时间轴格位：由 `BellSchedule.sections` 的 `group` 生成半区与格位，替换 `[2,4]` / `[6,8,10]` 与 `startSection <= 4`。
- 上下午标题：由 `SectionGroup` 驱动（8 节制学校可能只有上午/下午）。
- 超长作息（12–13 节）：需要考虑列内再次分屏或缩放兜底，不能假设「满课五张卡一屏可见」。

### 4.6 小组件、通知与安全配置

- **小组件**：载荷 `schemaVersion` 升到 2，增加 `sections[].group` 与 `schoolId`。Dart 与 Kotlin 双实现必须同步改并两侧都加测试（DEC-009 的既有风险）。首选方案是把周次算法**只在 Dart 侧算好、原生只做展示**，以消除双实现；但这会牺牲「App 未运行也正确」，需评估。→ 见 [D6](#d6-小组件是否继续保留原生周次计算)。
- **通知**：时区从固定 `Asia/Shanghai` 改为按 `SchoolProfile` / 设备时区；跨时区时提醒语义按「课程所在地墙上时间」定义并在文档写明。
- **安全配置（构建期硬约束）**：Android `network_security_config.xml` 与 iOS ATS 例外都是**打包时静态文件**，无法运行期新增。因此：
  - 若新学校是 HTTPS，可直接运行期接入，无需改包。
  - 若新学校只有 HTTP，**必须把域名加进两个配置文件并重新发版**。这批白名单应随 `SchoolProfile` 一起维护，并加一个测试断言「每个 HTTP 学校的域名都在 XML 里」，防止漏配导致用户装了也连不上。
  - 不引入 `usesCleartextTraffic="true"` 全局开关（DEC-007）。

---

## 5. 「其他校历上的不同时间」具体怎么处理

这是本次最核心的问题，逐项给结论。

### 5.1 第一周周一不同

- **处理**：`SchoolProfile.term.defaultFirstWeekMonday` 提供默认值；`Semester` 表按学期存实际值；设置页可改（已有）。新增「校历核对」入口，把校方来源（公告/PDF）与确认日期记在知识库。
- **风险**：这是所有周次、单双周、提醒的**唯一锚点**，错一天全错。因此新校接入时它是验收必查项，不允许沿用别校常量。

### 5.2 总教学周数不同（18 / 20 / 21 周）

- **处理**：已是 `Semester.totalWeeks` 字段，只需把默认值移入 `SchoolProfile`。设置在 1–30 的既有校验范围内。

### 5.3 节次数量与每节时间不同

- **处理**：`BellSchedule.sections` 数据化。
- **数据来源**：只能来自校方公布的作息表（PDF、教务处公告）。**不做自动抓取**——接口未知且格式各异，抓错了会静默产生错误提醒。
- **多套作息**：把南工「明志楼/明德楼/至善楼提前作息」抽象为 `ScheduleVariant`，用教室文本匹配。同一学校多校区、研究生/本科生不同作息都能落进同一模型。

### 5.4 上午/下午/晚间划分不同

- **处理**：划分是 `SectionSpec.group`，不是 UI 常量。课表半区、格位、时间轴标题全部由它派生。
- **验证**：新增一个与南工划分不同的测试档案（如 12 节、上午 1–5、下午 6–9、晚间 10–12），断言渲染与分组正确。

### 5.5 非线性差异：调休、停课、考试周（最难，需分级）

现状模型假设「第 N 周 = 从第一周周一算起的连续 7 天」，因此国庆调休、校运会停课、期中考试周都会算错。分级处理：

| 级别 | 做法 | 代价 | 建议阶段 |
| --- | --- | --- | --- |
| L1 | 不处理，但**显式声明**「本校调休未支持，课表按教学周显示」，不做静默错误 | 无 | 阶段 2 |
| L2 | 用户可编辑例外表（`CalendarException`），作用于课表显示与通知排程 | 用户要手动录入，每年几次 | 阶段 3 |
| L3 | 由配置源下发官方校历例外 | 需引入网络配置源（见 D2），回到「谁来维护、怎么校验」的问题 | 阶段 4，需决策 |

明确不做：从教务系统自动抓校历。理由同 5.3。

### 5.6 单双周从第几周起算

- **结论：不需要额外模型**。解析出的周次是**绝对周号**（`zcd` → `weeks`），单双周在第 1 周是单还是双，完全由 `firstWeekMonday` 决定。只要 5.1 正确，单双周就正确。这一点容易误解为独立难题，实际是 5.1 的推论。

### 5.7 时区

- **处理**：`SchoolProfile` 带时区；提醒时间定义为「课程所在地的墙上时间」。同一时区（国内绝大多数）行为不变。

### 5.8 学期中断（寒假/暑假）与跨学期

- **处理**：一校一学期一条 `Semester` 记录，跨学期靠新增记录 + 激活切换。学期外的显示与提醒由既有 `TermStatus` 提示条承接，不新增机制。

---

## 6. 新增一所学校的接入流程（runbook）

严格遵守「不得盲猜教务系统行为」，每一步都要有证据：

1. **登记**：用户在知识库提供学校全名与教务入口地址；未验证的域名**不得**先加进白名单（`school.dart` 现有注释已明确此纪律）。
2. **脱敏采集**：Debug 构建内用既有采集页，在真机/模拟器上由**用户本人**登录，得到脱敏的接口形状报告（端点、菜单号、字段名）。原始响应的身份字段不得落盘。
3. **确认接口**：确定课表端点与字段映射，写成 `FieldMapping` + 解析器；字段不明确的字段不得臆测。
4. **确认校历与作息**：取得校方作息表与教学周历，确定第一周周一、总周数、节次时间与分组。
5. **落档 + 端到端验收**：新学校档案写入 `knowledge/schools/<schoolId>.md`；在设备上走完「登录 → 预览 → 确认写入 → 替换等价（id 指纹不变）→ 手动课程保留」四项，与 TASK-021 的验收口径一致。
6. **回归**：全量 `flutter analyze`、`flutter test`；涉及小组件/通知的改动额外跑 Android JVM 单测与真机冒烟。

---

## 7. 分期实施计划

| 阶段 | 内容 | 交付物 | 验证方式 | 预估 |
| --- | --- | --- | --- | --- |
| **0. 抽象准备（不改行为）** | 引入 `SchoolProfile` / `TermCalendar` / `BellSchedule`；把 NCPU 常量搬进档案；`ensureDefaults()` 停止覆盖作息 | 纯 Dart 模型 + 单测；现有行为不变 | 132 测试全绿；真机对照课表与提醒无变化 | 中 |
| **1. 存储与展示去硬编码** | `schoolId` 迁移；`CourseSource` 泛化；格位由 `group` 驱动 | schema 迁移 + UI 改造 + 迁移测试 | 新增「12 节制」测试档案渲染正确；老库迁移后数据不丢 | 中 |
| **2. 用户可校正** | 设置页新增「作息与校历」编辑；支持导入校历 JSON 文件；未确认时展示提示条 | 设置 UI + 导入 + 文档 | 用户改节次时间后，课表/小组件/通知三处一致 | 中小 |
| **3. 第二所学校真实接入** | 按第 6 节 runbook 走完一所真实学校；L2 级例外表 | 新适配器 + 学校档案 + 验收记录 | 第 6 节四项端到端验收 | 大（依赖外部条件） |
| **4. 调休与配置源（可选）** | L3 例外下发；配置源选型落地 | 需先做 [D2](#d2-校历与作息数据从哪来)、见风险 | 官方调休周显示与提醒正确 | 大，需决策 |

**建议顺序不变**：阶段 0–1 是纯重构，风险可控且能立刻降低后续成本；阶段 3 必须有一所真实学校才能验收，否则无法证明架构真的通用。

---

## 8. 风险与约束

| 风险 | 影响 | 对策 |
| --- | --- | --- |
| 校历数据本身拿不到或年年变化 | 用户看到错周次、收到错提醒 | 默认值 + 用户覆盖 + 显式「未确认」提示；不猜 |
| `ensureDefaults()` 覆盖作息（现状） | 学校作息/用户修改被静默冲掉 | 阶段 0 必修，改「仅播种不覆盖」 |
| 构建期 cleartext 白名单 | HTTP 学校要重新发版才能用 | 白名单进档案并加一致性测试；优先支持 HTTPS 学校 |
| 双实现不同步（Dart / Kotlin 周次算法） | 小组件与 App 显示不一致 | 校历模型变更时两侧同步 + 各自测试；或按 D6 收敛为单实现 |
| 老用户数据迁移 | 迁移失败等于丢课表 | 迁移前备份、schema 版本化、在真机库副本上验证 |
| 接入流程依赖用户配合采集 | 进度不可控 | 阶段 3 才能验收，不预先假设某校接口 |

---

## 9. 需要你决策的问题

### D1 单校激活还是多校共存

- **推荐：单校激活**（一次安装只激活一所学校，切校时保留数据但只显示当前校）。理由：与「本地单机、不做账号」的定位一致，避免凭证与数据混淆；schema 预留 `schoolId` 为将来共存留门。
- 备选：多校共存（一个设备同时显示多校课表），复杂度显著上升（学期、提醒、小组件都要带校维度）。

### D2 校历与作息数据从哪来

- **A. 仅内置**：随 App 发版更新。简单、无网络，但每年开学要发新版。
- **B. 内置 + 用户可导入 JSON**（推荐折中）：用户能从学校公告手工生成/导入配置，不发版也能修。
- **C. 内置 + 远端可更新配置源**：最省事，但引入一个网络依赖与「谁来维护、怎么防止投毒」的新问题，需要 HTTPS 配置源与签名校验。
- **推荐：阶段 2 做 B，阶段 4 再评估 C。**

### D3 是否接受「新增 HTTP 学校需要重新发版」

Android/iOS 的明文放行是构建期配置，无法运行期新增。若不能接受，就只能接入 HTTPS 学校。→ 影响阶段 3 选校。

### D4 第二所学校选谁

阶段 3 必须有**真实可验收**的学校（能拿到账号、能配合采集）。没有的话，阶段 3 只能停留在合成数据，架构通用性无法证明。

### D5 调休/停课要不要提前到阶段 2

若目标学校调休频繁（国庆、校运会），L1（仅提示不支持）会导致课表和提醒肉眼可见地错。→ 是否把 L2 用户例外表提前。

### D6 小组件是否继续保留原生周次计算

保留：App 未运行也正确，但永久双实现。收敛到 Dart：消除不一致风险，但小组件必须等 App 至少启动一次/推送一次。→ 与本次校历改动一起定。

---

## 10. 验收标准

阶段 0–1（重构）通过的标准：

- [ ] `flutter analyze` 无问题，`flutter test` 全绿；**且新增一个与南工划分不同的合成学校档案，课表渲染正确**。
- [ ] 老库迁移后：课程数、学期记录、`source`/`schoolId` 正确，`integrity_check=ok`。
- [ ] 用户改过的作息与校历不再被启动流程覆盖（现有 `ensureDefaults()` 行为被测试锁定）。
- [ ] 南工现有用户升级后，课表、小组件、提醒三处与升级前一致。

阶段 3（真实学校）通过的标准：

- [ ] 走完 runbook 六步，且四项端到端验收（登录→预览→写入→替换等价；手动课程保留）有真机记录。
- [ ] 该校校历（第一周周一、总周数）与作息（每节时间、上下午划分）有可追溯来源，不依赖猜测。
- [ ] 该校的 HTTP 域名（若有）已在 Android/iOS 安全配置中，并有测试断言防漏配。

---

## 附：为什么不能「先支持十所学校再验证」

架构通用性只能被**第二所真实学校**证明。合成配置能验证代码路径，不能验证「另一个教务系统真的长这样」。因此本计划的顺序是：先拆架构（阶段 0–1，行为不变）→ 再做用户校正（阶段 2）→ 然后用一所真实学校逼出所有遗留假设（阶段 3）。任何跳过阶段 3 的「已完成」都是 `UNVERIFIED`。
