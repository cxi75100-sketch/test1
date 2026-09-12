# 南工课表

面向南昌工学院的 Flutter 本地课表 App。当前完成：本地课表闭环、安全受限的正方教务导入主链路和 Android 桌面小组件代码。

## 已实现

- Drift + SQLite：学期、课程、节次时间、设置表
- Riverpod 数据层与 GoRouter 导航
- 手动新增、编辑、删除课程
- 移动端纵向周日程、七天日期概览、周切换、当前周计算、单双周过滤
- 依据学校教学周历显示官方上课时间，第 3/4 节自动适配明志楼、明德楼、至善楼与其他教学场所
- `manual` / `ncpu` 来源隔离和重新导入替换策略
- 周次解析、数据库与完整新增流程测试
- 教务导入：域名白名单、HTTP 风险确认门、受限 WebView、Debug 脱敏接口采集
- 真机采集确认的正方教务课表接口；按 key 解析 `kbList`，预览确认后写入本地
- 原始课表响应只在内存中用于本次导入；解析忽略姓名、学号、班级等身份字段
- **Android 桌面小组件**：主屏显示「第 N 周 · 周X」与今天课程（时间 / 课名 / 教室 / 颜色），App 未运行时也能按设备日期自行计算，点击打开 App

项目不会收集或保存密码；登录只发生在受限 WebView。当前仍需真机完成教务导入端到端验收和小组件主屏验收。

## 本机运行

Flutter SDK 当前位于 `D:\Tools\flutter`。因 Flutter 3.47 分析服务器在本机中文项目路径下存在异常，命令行验证可先映射临时盘符：

```powershell
subst R: "D:\桌面\课程表"
Set-Location R:\
& 'D:\Tools\flutter\bin\flutter.bat' pub get
& 'D:\Tools\flutter\bin\dart.bat' run build_runner build --force-jit
& 'D:\Tools\flutter\bin\flutter.bat' analyze
& 'D:\Tools\flutter\bin\flutter.bat' test
```

原生小组件的纯 Kotlin 单元测试（无设备也能跑）：

```powershell
Set-Location R:\android
.\gradlew :app:testDebugUnitTest
```

Android 工具链已配置完成。2026-09-10 最新验证为 `flutter analyze` 无问题、`flutter test` 83/83、Android JVM 测试 13/13，最新版已在 vivo V1981A 真机安装和冷启动验证。交接状态见 [knowledge/current_state.md](knowledge/current_state.md)，教学周历见 [knowledge/teaching_calendar.md](knowledge/teaching_calendar.md)，教务事实见 [knowledge/ncpu_import.md](knowledge/ncpu_import.md)，桌面小组件验收见 [knowledge/home_widget.md](knowledge/home_widget.md)。
