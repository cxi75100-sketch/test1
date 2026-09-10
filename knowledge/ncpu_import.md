# NCPU Import Knowledge

## Confirmed

- `CONFIRMED`（2026-09-10 20:20 +08:00，公网 curl 实测，未使用任何账号）：
  - 域名 `jwxt.ncpu.edu.cn` 公网可解析（`218.204.129.252` + 两个 IPv6 地址），无需校园网。
  - `http://jwxt.ncpu.edu.cn:8088/jwglxt` 返回 `302` → `Location: /jwglxt/`，并下发 `JSESSIONID`（Path=/jwglxt）、`route`、`TS01*` 三类 Cookie。
  - 最终跳转登录页：`http://jwxt.ncpu.edu.cn:8088/jwglxt/xtgl/login_slogin.html`，`<title>教学管理信息服务平台</title>`。
  - 页面特征字符串：`zfsoft`、`正方`、`jQuery`、`csrftoken`，登录表单 `action="/jwglxt/xtgl/login_slogin.html"`，字段含 `yhm`(用户名)、`mm`(密码)、`csrftoken`(CSRF)、`language`、`ydType` 等。
  - 结论：**系统类型为正方教务系统（ZFSoft）教学管理信息服务平台**。
  - 安全说明：本次记录只保留 Cookie 与字段**名称**，未保存任何 Cookie 值、Session ID 或 Token。
- 后续真机复采已取得完整 `kbList` 字段；首版“60 字段上限导致 `xqj`/`zcd` 缺失”的问题已通过提高上限解决。

## Confirmed（真机采集，TASK-012，2026-09-10）

用户在自己手机上通过 App 内 Debug 采集工具登录教务并打开课表页，得到 28 条同源 XHR（原始报告不入库，以下仅为接口形状；学号、姓名、密码、Cookie 均在采集阶段被替换）。

### 课表数据接口（核心）

- `POST /jwglxt/kbcx/xskbcx_cxXsgrkb.html?gnmkdm=N253508`
  - 请求体（form-urlencoded）：`xnm=2026&xqm=3&kzlx=ck&xsdm=&kclbdm=&kclxdm=`
  - 响应：`application/json;charset=UTF-8`，顶层 19 个字段：`qsxqj`、`xsxx{}`、`sjkList[]`、`xqjmcMap{}`、`kbList[]`、`rqazcList[]`、`djdzList[]`、`jxhjkcList[]`、`xkkg`、`sfxsd`、`zckbsfxssj` 等。
  - **`gnmkdm=N253508` 是本校菜单号，与网上流传的通用值 `N2151` 不同，必须用采集值，不能沿用通用常量。**
- `xqjmcMap`：`{1:"星期一" … 7:"星期日"}`。
- `xsxx{}`：学生身份信息（姓名/学号/班级/专业/年级/学期码等）→ **解析器必须忽略这些字段**。
- `kbList[]`：每条 **78 个字段**（完整字段名已确认）。关键字段：
  - 星期：`xqj` 数值（`"1"`…`"7"`，1=周一）、`xqjmc` 中文名
  - 周次：`zcd` 周次段（形如 `"1-16周"`，可直接交给现有 `parseWeeks`）
    - ⚠️ **`zcmc` 不是周次名称，而是职称名称**（实测值为 `"副教授"`）；按名字推测会踩坑。
  - 节次：`jcs`（`"3-4"`）、`jc`（`"3-4节"`）、`jcor`（`"3-4"`）
  - 课程：`kcmc` 名称、`kch`/`kch_id` 课程号、`jxbmc` 教学班名称、`jxbzc` 教学班组成、`kcbj`（`"主修"`）
  - 场地：`cdmc`（`"明志楼223"`）、`lh` 楼名、`cdlbmc` 场地类别、`cd_id`/`cdbh` 场地 ID
  - 学时学分：`xf` 学分、`zxs`/`kczxs` 总学时、`zhxs` 周学时、`kcxz` 课程性质、`kclb` 课程类别
  - 考核：`khfsmc`（`"考试"`）、`ksfsmc`（`"闭卷考试"`）、`skfsmc` 授课方式
  - 教师：`xm` 教师姓名、`jgh_id` 教职工号、`zfjmc` 主讲标记
  - 排课：`pkbj`、`px`（排序）、`sxbj`、`cxbj`、`xkrs` 选课人数、`zzrl` 总人数
  - 通用噪声字段（与课程无关，解析时忽略）：`date*`、`day/month/year`、`listnav`、`localeKey`、`jgpxzd`、`pageTotal`、`pageable`、`queryModel{}`、`rangeable`、`totalResult`、`userModel{}`、`rsdzjs`、`sfkckkb`、`xqh1`、`xqdm`、`xsdm`、`xslxbj`
  - ⚠️ **字段顺序不固定**（服务端 HashMap 顺序），必须按 key 取值，不能按下标。
  - `kbList` 条目数（27）大于课程门数（`xsxx.KCMS`=15）：**同一门课每周多次上课会拆成多条**，每条对应一个「星期 + 节次」组合。

### 节次时间与作息（可直接用于填充节次表）

- `POST /jwglxt/kbcx/xskbcx_cxRjc.html?gnmkdm=N253508`，体 `xnm=2026&xqm=3&xqh_id=1`：`array[10]`，含 `jcmc` 节次、`qssj` 起始时间（`"08:20"`）、`jssj` 结束时间（`"09:00"`）。
- `POST /jwglxt/kbcx/xskbcx_cxRsd.html?gnmkdm=N253508`，体同上：`array[3]` 上午/下午/晚上，含 `rsdmc`、`rsdzjs` 节数。

### 其他已确认

- 登录：`GET /jwglxt/xtgl/login_getPublicKey.html` 返回 `{modulus, exponent}` RSA 公钥，密码在页面内加密后表单提交（**App 不实现该流程**，用户始终在 WebView 内登录）。
- `POST /jwglxt/xtgl/yhgl_cxXxqrCheck.html`（体含 `yhm`）用户名校验；`POST /jwglxt/xtgl/login_logoutAccount.html` 注销。
- 首页会请求 `xtgl/index_cx*` 系列；`jssygl/sykbcx_cxKfxSykbcxIndex.html`（教师课表）对学生身份返回 `"没有访问权限!"`。
- 采集边界：只记录 XHR/fetch；登录表单 POST 不在采集范围内，密码不会进入报告。

## Adapter 与解析器实现（2026-09-10 就位）

- `SchoolAdapter` 抽象类：`lib/features/import/adapters/school_adapter.dart`
  - `schoolName` / `loginUrl` / `canHandle(Uri)`
  - `ImportResult parseTimetable(String rawResponse, {required String semesterId})`
- `sealed ImportResult`：`ImportSuccess` / `ImportInterfaceNotYetDiscovered` / `ImportError`
- `NcpuAdapter`：空响应返回 `ImportInterfaceNotYetDiscovered`；合法响应交给 `NcpuTimetableParser`；解析异常转换为 `ImportError`。
- `NcpuTimetableParser`：`lib/features/import/parsers/ncpu_timetable_parser.dart`
  - 按 key 读取课程名、星期、节次、周次、教室、教师、学分和课程性质，不依赖字段顺序。
  - 只使用通用课程字段，忽略顶层 `xsxx` 及身份/分页噪声字段。
  - `jcs` 缺失时依次回退 `jcor`、`jc`；非法或不完整条目跳过。
  - 同一教学班同星期同节次但周次段不同的记录，以周次指纹区分 ID，避免覆盖。
- `NavigationPolicy`：`lib/features/import/services/navigation_policy.dart`，纯 Dart 域名白名单校验，11 个单元测试通过。
- `NcpuSchoolConfig`：`lib/models/school.dart`，`acceptedHosts = {'jwxt.ncpu.edu.cn'}`，`allowedSchemes = {'http', 'https'}`。
- `NcpuSchoolConfig.accepts(Uri)` 同时校验 scheme 与 host，避免 adapter 与导航策略结论不一致。
- `SchoolAdapter` 不接收 Cookie、Session 或 Token 参数；真实响应由 WebView 会话内同源脚本取得。

## WebView Login Page（2026-09-10 就位）

- `ImportLoginPage`：`lib/features/import/pages/import_login_page.dart`
- flutter_inappwebview 6.1.5 + `InAppWebView`
- `shouldOverrideUrlLoading` 通过 `NavigationPolicy` 拦截非白名单域名
- 首次进入先显示阻断式风险确认页，明确 HTTP 未加密；用户确认后才创建 WebView
- 加载阶段持续显示 HTTP 警告，不把白名单等同于 TLS 或站点身份验证
- 导航警告横幅 + 加载进度条 + 返回/刷新按钮
- 同源 XHR/fetch 钩子识别 `xskbcx_cxXsgrkb`：原始响应只经 `timetableData` 桥进入内存；Debug 脱敏报告经 `importCapture` 桥进入采集页并自动保存
- “尝试导入课表”读取当前学期，解析后展示 `ImportPreviewDialog`；用户确认才调用 `replaceImportedCourses`，保留 `manual` 课程
- `BLOCKED`：当前版本的完整登录、预览、确认写入与重启持久化尚未完成真机端到端验收（TASK-021）

## Validation Status

- `CONFIRMED`：真实系统、登录入口、核心课表端点、`gnmkdm=N253508`、学年学期参数及 `kbList` 关键字段来自用户真机脱敏采集。
- `CONFIRMED`：`NcpuTimetableParser` 与 `NcpuAdapter` 单元测试覆盖合法响应、字段乱序、同课多安排、周次/节次回退、身份字段忽略和异常响应。
- `CONFIRMED`：2026-09-10 全量 `flutter test` 77/77 通过，`flutter analyze` 无问题。
- `BLOCKED`：当前版本尚未在真机完成“登录 → 打开学生课表查询 → 预览 → 确认写入 → 重启验证”的完整验收。

## Parser Notes

- 通用周次解析器已覆盖范围、单双周、离散周与中英文括号。
- 当前只导入课程安排；`cxRjc` 的真实节次时间已确认，但尚未接入导入写库流程。默认 10 节时间继续由本地默认值提供。

## Known Risks

- 校方升级、验证码、统一身份认证和页面脚本变化可能导致适配失效。
- 任何调试记录必须移除身份信息、Cookie、Session 和完整 Token。
- flutter_inappwebview Android 稳定版子包的 AGP 9.1.0 兼容修复已固化在项目 `third_party/`，不依赖 Pub Cache（详见 ISSUE-006 / DEC-008）。
