# Android Toolchain Setup

Status: Completed (TASK-015, 2026-09-10 00:01 +08:00)

## Purpose

供负责配置 Android 开发环境的 Agent 使用。该任务只负责工具链安装、配置和构建验证，不扩大到教务导入或业务功能开发。

## Current Facts

- `CONFIRMED` Flutter SDK：`D:\Tools\flutter`
- `CONFIRMED` Flutter：3.47.2 stable
- `CONFIRMED` Dart：3.13.2
- `CONFIRMED` 项目路径：`D:\桌面\课程表`
- `CONFIRMED` Android SDK：`D:\Tools\android-sdk`，SDK/Platform/Build-Tools 36，Platform-Tools 37.0.1，NDK 28.2.13676358。
- `CONFIRMED` JDK：`D:\Tools\jdk-17`，Eclipse Temurin 17.0.20.1+1。
- `CONFIRMED` `flutter doctor -v` Android toolchain 全绿，Android licenses 全部接受。
- `CONFIRMED` Android 工程使用 Flutter 管理的 `compileSdk`、`targetSdk`、`minSdk` 和 `ndkVersion`，Java/Kotlin 目标为 17。
- `CONFIRMED` Windows 桌面工具链缺少 Visual Studio，但它不是本项目 Android V1 的前置条件。
- `CONFIRMED` 未安装 Android Studio；采用官方 command-line tools 完成 Android 工具链。
- `CONFIRMED` 用户级 `JAVA_HOME`、`ANDROID_HOME`、`ANDROID_SDK_ROOT` 和 PATH 已持久化。当前已运行的 Codex 宿主进程可能仍继承旧 PATH，新启动终端后生效。

## Completion Evidence

1. `CONFIRMED` 官方 Android command-line tools 和必需 SDK 组件安装完成。
2. `CONFIRMED` `flutter config` 已指向实际 SDK/JDK 路径。
3. `CONFIRMED` `flutter analyze` 无问题；`flutter test` 17/17 通过。
4. `CONFIRMED` Debug APK：`D:\桌面\课程表\build\app\outputs\flutter-apk\app-debug.apk`，170,936,973 B。
5. `CONFIRMED` APK SHA256：`1daf867fc31a15f053c1ef17f69f109110bcd061f1e85a6e1ccd632c1222aa06`。
6. `CONFIRMED` 2026-09-10 复核 `apksigner`：v2 签名通过，Signer `CN=Android Debug`，RSA 2048。
7. `CONFIRMED` 2026-09-10 复核 `aapt2`：compileSdk/targetSdk 36、minSdk 24、应用名“南工课表”，仅声明 INTERNET 与动态广播接收器内部权限。
8. `BLOCKED`（2026-09-10 当时快照，后续已解除）`adb devices -l` 为空、Flutter 无 Android 设备；真机/模拟器运行属于 TASK-016，当时尚未通过。TASK-016 已由同日晚间真机验收完成，见 `knowledge/testing.md`。

外部交接报告：`C:\Users\ninan\.qoderworkcn\workspace\mtu9gimj8t6a7xm4\outputs\南工课表_Android工具链交接报告_20260910.md`。

## Path Workaround

Flutter 3.47.2 在本机中文工作区直接运行部分命令会触发 analysis server JSON 截断或 build_runner AOT 写入问题。可使用：

```powershell
subst R: "D:\桌面\课程表"
Set-Location R:\
```

Drift 代码生成使用：

```powershell
& 'D:\Tools\flutter\bin\dart.bat' run build_runner build --force-jit
```

## Verification Commands

```powershell
& 'D:\Tools\flutter\bin\flutter.bat' doctor -v
& 'D:\Tools\flutter\bin\flutter.bat' pub get
& 'D:\Tools\flutter\bin\flutter.bat' analyze
& 'D:\Tools\flutter\bin\flutter.bat' test
& 'D:\Tools\flutter\bin\flutter.bat' build apk --debug
& 'D:\Tools\flutter\bin\flutter.bat' devices
```

## Constraints

- 先检查现有安装和路径，避免重复安装。
- 不为 Android V1 安装 Visual Studio C++ 工作负载。
- 不修改教务系统接口、不添加登录绕过、不接触用户凭证。
- 仅在构建确有需要时小范围修改 Android 配置，并记录原因与验证证据。
- 结束前更新 `knowledge/current_state.md`、`knowledge/tasks.md`、`knowledge/issues.md`、`knowledge/testing.md`、`knowledge/changelog.md`。
- 同步更新 Obsidian 项目页：`D:\桌面\数模\mcm2026\docs\数模知识库\项目\南工课表.md`。
