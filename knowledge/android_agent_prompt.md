# Android 环境配置 Agent 提示词

将下方内容完整复制给负责 Android 环境配置的 Agent：

```text
你负责为 Flutter 项目“南工课表”安装并验证 Android 开发工具链。

项目绝对路径：D:\桌面\课程表
Flutter SDK：D:\Tools\flutter

开始任何操作前，必须完整阅读：
1. D:\桌面\课程表\AGENTS.md
2. D:\桌面\课程表\knowledge\current_state.md
3. D:\桌面\课程表\knowledge\tasks.md
4. D:\桌面\课程表\knowledge\android_setup.md
5. D:\桌面\课程表\knowledge\issues.md
6. D:\桌面\课程表\knowledge\testing.md

用户已授权你安装 Android Studio、Android SDK 及 Android 构建所必需的官方组件。你的任务范围仅限 Android 工具链安装、配置、构建和设备验证；不要开发教务导入，不要重构业务代码。

执行要求：
- 先检查现有 Android Studio、SDK、JDK、环境变量和残留安装，避免重复安装。
- 安装 Android Studio或官方 command-line tools，并安装 Flutter 3.47.2 当前要求的 SDK Platform、Platform-Tools、Build-Tools、Command-line Tools、NDK。
- Java/Kotlin 目标为 17，优先使用 Android Studio 自带 JBR。
- 用 D:\Tools\flutter\bin\flutter.bat config --android-sdk <实际SDK路径> 配置 Flutter。
- 完成 flutter doctor --android-licenses。
- 不要为了 Android V1 安装 Visual Studio C++；Windows 桌面不是目标。
- 项目路径含中文。若 Flutter 工具异常，执行 subst R: "D:\桌面\课程表"，然后在 R:\ 下运行项目命令。
- build_runner 如遇 AOT 写入失败，使用 D:\Tools\flutter\bin\dart.bat run build_runner build --force-jit。
- 仅当 Android 构建确有需要时小范围修改项目配置，先说明证据；不要更改教务、安全或业务逻辑。

必须完成并记录这些验证：
1. flutter doctor -v：Android toolchain 必须通过。
2. flutter pub get。
3. flutter analyze：必须无问题。
4. flutter test：现有 17 个测试必须全部通过；如数量变化，记录真实数量。
5. flutter build apk --debug：必须成功，并记录 APK 绝对路径、文件大小和构建时间。
6. flutter devices：记录实际设备列表。
7. 只有检测到真实 Android 设备或模拟器时才运行 flutter run；没有设备就标记 BLOCKED，不得声称真机或模拟器验证通过。

安全与变更纪律：
- 不记录密码、学号、Cookie、Session 或 Token。
- 不绕过认证、验证码或学校安全机制。
- 不删除用户文件，不使用 git reset --hard 或覆盖现有改动。
- 当前工作树包含前一个 Agent 的项目文件，必须保留并基于它们继续。

完成前必须同步更新：
- D:\桌面\课程表\knowledge\current_state.md
- D:\桌面\课程表\knowledge\tasks.md
- D:\桌面\课程表\knowledge\issues.md
- D:\桌面\课程表\knowledge\testing.md
- D:\桌面\课程表\knowledge\changelog.md

TASK-015 只有在 Android toolchain 通过且 Debug APK 构建成功后才能移入 Done。TASK-016 只有真实设备/模拟器运行通过后才能完成。最后向用户报告：安装了什么、准确路径、每项验证结果、APK 路径、未验证项和下一步。
```
