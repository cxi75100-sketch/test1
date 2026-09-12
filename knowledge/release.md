# Release 签名与分发

本文件记录里程碑 4（release 签名与分 ABI 打包）的配置、验证与分发步骤。

## 签名配置

`android/app/build.gradle.kts` 从 `android/key.properties` 读取签名材料：

- 文件存在 → 使用 `signingConfigs.release`（正式签名）。
- 文件缺失 → 回退 `signingConfigs.debug`，保证任何机器上 `flutter run --release` 仍可构建，不阻塞开发。

| 项 | 值 |
| --- | --- |
| keystore 路径 | `D:\Tools\android-keys\ncpu-timetable-release.keystore`（**仓库外**） |
| 类型 / 算法 | PKCS12 / RSA 2048，有效期 10000 天 |
| alias | `ncpu` |
| 证书 DN | `CN=NCPU Timetable Release, OU=Android, O=NCPU Timetable, L=Nanchang, ST=Jiangxi, C=CN`（不含个人信息） |
| 证书 SHA-256 | `2e8ac142d9c68df3ebc45a77269b8c9d98ad313c4763ab704ba68087a8b58799` |
| 证书 SHA-1 | `bd92829c8fb0642afb80f9866afb34058cf6e061` |

`CONFIRMED`（2026-09-12）：keystore 与 `android/key.properties` 均不入库；`.gitignore` 已加 `android/key.properties`、`**/*.jks`、`**/*.keystore` 作兜底。密码只写在本机 `android/key.properties`，不写入知识库、不进入提交。

## 构建

在 `R:\`（`subst R: "D:\桌面\课程表"`）执行：

```bash
flutter build apk --release --split-per-abi
```

`CONFIRMED`（2026-09-12，耗时 172.8 s）：

| 产物 | 大小 | SHA-256 |
| --- | --- | --- |
| `app-arm64-v8a-release.apk` | 22,184,816 B（21.2 MB） | `aba6f19ea6c048541f041a018caaad52db6354c9e2edfa981418726ce8c7b4b4` |
| `app-armeabi-v7a-release.apk` | 19,610,292 B（18.7 MB） | `a5c5e7fdbd9426054d542c94c2d12aa5e209c1fbbef3d860eb59dca65db4daa1` |
| `app-x86_64-release.apk` | 23,636,548 B（22.5 MB） | `8ef7b6fd6cb3f578d233bfaa47e61f0fd2ed5e4335087f33e8b92ddcad35bf0f` |

对照：Debug fat APK 为 207,598,993 B。

说明：

- **分发用 `arm64-v8a`（现代真机）与 `armeabi-v7a`（老设备）；`x86_64` 仅供模拟器**，不需要上网盘。
- 不额外写 Gradle `splits {}`：Flutter CLI 已按 ABI 分包并自动加 `versionCode` 偏移（见 `build.gradle.kts` 内注释），两套机制并存会冲突。
- **未开启 `minifyEnabled` / `shrinkResources`**：`third_party/flutter_inappwebview_android` 的兼容补丁与 AGP 9 已移除的默认 ProGuard 文件相关（见 DEC-008 / ISSUE-006），开混淆需单独验证，本轮不做。

## 验证

`CONFIRMED`（2026-09-12，AVD `ncpu_api36` / API 36 / x86_64）：

- `apksigner verify --print-certs`：三个 APK 证书 DN 与 SHA-256 一致，均为正式证书，非 debug 证书。
- 安装：换签名**必须先卸载**（`INSTALL_FAILED_UPDATE_INCOMPATIBLE`），`adb uninstall` 后 `adb install` 成功。
- 冷启动：`Status: ok` / `LAUNCH_STATE_COLD` / 937 ms（release AOT 明显快于 debug 的 2.4–3.7 s）。
- `dumpsys package`：`flags=0x0`（无 `DEBUGGABLE`），`primaryCpuAbi=x86_64`，`versionName=1.0.0`。
- `run-as` 报 `package not debuggable` —— 与上一条互为佐证。
- logcat 无 `FATAL` / `AndroidRuntime` / `MissingPluginException` / `E/flutter`；**按 App pid 过滤后无 Cookie、Session、Token、password、账号或 `jwglxt` 字段**，符合「Release 模式不得输出登录会话信息」。
- uiautomator 语义树确认界面渲染：「我的课表 / 当前学期 / 新增课程 / 设置」「今日 / 整周」「今天 · 周六」「第 2 周 · 0 门课程」「今日课程 0 门」。
- `dumpsys appwidget` 确认 `TimetableWidgetProvider` 已注册 —— 该载荷由 Flutter 读库后推送，间接证明 **release 模式下 x86_64 原生 SQLite 正常**。

`UNVERIFIED`：arm64-v8a release APK 未在 arm64 真机验证；真机安装需先卸载，会丢本机课表与登录态，故必须排在 TASK-019 / TASK-039 验收之后。

## 分发

1. 打 tag 并推送：`git tag -a v1.0.0 -m "..."` → `git push origin v1.0.0`。
2. 在 Gitee 仓库的「发行版」页面创建发行版，选择 `v1.0.0`，上传 `app-arm64-v8a-release.apk`（可选 `app-armeabi-v7a-release.apk`），并把上表 SHA-256 贴进说明。
3. `UNVERIFIED`：GitHub/Gitee 的 release 附件 API 需要 `access_token`，本轮未执行上传，发行版仍需在网页端创建。

## 约束与风险

- **换签名必须卸载**：正式签名与 debug 签名不兼容，切换时本机课表与登录态会丢。真机切换只能在 TASK-019 / TASK-039 验收关闭之后进行。
- **keystore + 密码是本 App 的长期身份**：丢失后无法用同一签名发布更新（设备会拒绝覆盖安装）。必须离线备份 keystore 文件与 `android/key.properties` 两样东西。
- **绝不入库**：仓库是公开的。keystore 放在 `D:\Tools\android-keys\`，`key.properties` 已被 gitignore。
- **不要删除 `D:\Tools\android-keys\`**，也不要把 keystore 移入项目目录。
- Play Store 上传需要 AAB（`flutter build appbundle`）与 v3 签名，本轮不做。
