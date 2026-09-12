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

`CONFIRMED`（2026-09-12，v1.0.1 修复版，耗时 104.0 s）：

| 产物 | 大小 | versionCode | SHA-256 |
| --- | --- | --- | --- |
| `app-arm64-v8a-release.apk` | 22,184,832 B（21.2 MB） | 2002 | `5f9bbdb081609adc9ed407f2cea2684354f7921163c7d4fe2b73385394089c6d` |
| `app-armeabi-v7a-release.apk` | 19,610,312 B（18.7 MB） | 1002 | `a170a2de24d601ac96d7716ed0f2348a143550668f3bc0ca2f30cde26b05b313` |
| `app-x86_64-release.apk` | 23,636,564 B（22.5 MB） | 4002 | `a75f647969f3343f973930655b347be1429e9844a66272b7a7c8f8a72934b6f4` |

对照：Debug fat APK 为 207,598,993 B。

> ⚠️ **v1.0.0 的产物已作废，不得分发。** 那一版缺 `INTERNET` 权限，教务导入完全不可用，详见 ISSUE-015。tag `v1.0.0` 保留作为问题标记，实际发布用 `v1.0.1`。

说明：

- **分发用 `arm64-v8a`（现代真机）与 `armeabi-v7a`（老设备）；`x86_64` 仅供模拟器**，不需要上网盘。
- 不额外写 Gradle `splits {}`：Flutter CLI 已按 ABI 分包并自动加 `versionCode` 偏移（见 `build.gradle.kts` 内注释），两套机制并存会冲突。
- **未开启 `minifyEnabled` / `shrinkResources`**：`third_party/flutter_inappwebview_android` 的兼容补丁与 AGP 9 已移除的默认 ProGuard 文件相关（见 DEC-008 / ISSUE-006），开混淆需单独验证，本轮不做。

### 面向测试者的通用包（发给别人时用这个）

分 ABI 包要求测试者自己选对架构，容易装错。发给他人测试时改用**同时含 arm64 与 32 位**的单个 APK：

```bash
flutter build apk --release --target-platform android-arm,android-arm64
```

`CONFIRMED`（2026-09-12，耗时 74.0 s）：产出 `app-release.apk`，38.6 MB（40,476,186 B），`versionName=1.0.1` / `versionCode=2`，正式证书（`2e8ac142…`），含 `INTERNET` / `POST_NOTIFICATIONS` / `SCHEDULE_EXACT_ALARM`。内部实测 arm64-v8a 19.7 MB + armeabi-v7a 17.3 MB 均为真实原生库（`libflutter.so` 两者都有），x86_64 仅 0.1 MB 存根 —— 真机都是 arm，无影响，但**因此这个包无法在 x86_64 模拟器上运行**。

分发副本命名为 `ncpu-timetable-1.0.1-universal.apk`，SHA-256 `0b674d3b070ae50cb614a29d897f3db96faa314c2b0a8cc4b19e1fc81f242694`。

注意：
- 通用包与分 ABI 包的 `versionCode` 不可比（分包会加 ABI 偏移，arm64 为 2002 而通用包为 2）。**同一批测试者只用一种**，否则会出现"版本更高却被判为降级"的困惑。
- 分 ABI 包与通用包签名相同，可互相覆盖（除上述 versionCode 方向问题外）。
- **绝不要把 debug 证书签名的对照包**（`app-*-debugkey.apk`）发给任何人：debug 证书是公开的，任何人都能签一个同包名的更新把它顶掉。

## 验证

### 必查清单（每次出 release 包都要走一遍）

只验证"能启动、界面正常、日志干净"是**不够的** —— v1.0.0 就是这样漏掉了 `INTERNET` 权限缺失（ISSUE-015）。固定检查项：

1. `aapt2 dump permissions <apk>` —— 确认 `INTERNET` 存在；新增任何权限都按需核对。
2. `apksigner verify --print-certs` —— 确认是正式证书而不是 debug 证书。
3. `dumpsys package` —— 确认 `flags=0x0`（非 debuggable）、版本号正确。
4. 冷启动 + 语义树 —— 确认主界面渲染。
5. **依赖网络的功能必须实测**：教务导入页能真正打开登录页（这是 v1.0.0 漏掉的一项）。
6. 通知与小组件 —— 在 release 包上各走一遍（分组权限、cleartext 白名单、receiver 都只在 release 才暴露问题）。

### v1.0.0 已验证项（AVD `ncpu_api36` / API 36 / x86_64，2026-09-12）

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

`CONFIRMED`（2026-09-12）：**v1.0.1 测试版已发布到 Gitee 发行版。**

- 发行版页面：<https://gitee.com/chenxihh/test_c/releases/tag/v1.0.1>（标记为预发布）
- release id `1140075`，tag `v1.0.1` → 提交 `cbc0f20`

> **该 tag 与发行版曾重建过一次。** 原因：仓库公开文档中曾写入不应公开的项目归属表述，虽已从工作区移除，但发行版附带的源码压缩包（`v1.0.1.zip` / `.tar.gz`）是 tag 的快照，仍会带上旧文本。处理方式为删除旧发行版 `1140059`、删除并重建 tag 到清理后的提交 `cbc0f20`、重新创建发行版并重传附件。**tag 名称与下载地址保持不变。** 提交历史本身仍保留旧文本（见 `git log -S`），彻底清除需要重写历史，未执行。

| 附件 | 体积 | 下载地址 |
| --- | --- | --- |
| `ncpu-timetable-1.0.1-universal.apk` | 40,476,186 B | `https://gitee.com/chenxihh/test_c/releases/download/v1.0.1/ncpu-timetable-1.0.1-universal.apk` |
| `app-arm64-v8a-release.apk` | 22,184,832 B | `https://gitee.com/chenxihh/test_c/releases/download/v1.0.1/app-arm64-v8a-release.apk` |

`CONFIRMED` 验证方式：用公开接口读回发行版确认两个附件可见；再从下载地址实际下载通用包，得到 40,476,186 B / 耗时 41.3 s，SHA-256 `0b674d3b…f242694` 与本地构建产物**完全一致**。重建后另行下载 tag 的源码包（`v1.0.1.zip`，686,693 B / 500 个文件）逐文件搜索，确认**不再包含**该表述。临时下载文件已删除。

### 发布步骤（可复现）

1. `git tag -a v1.0.1 -m "..."` → `git push origin v1.0.1`。
2. 创建发行版（**必须带 `target_commitish`，否则接口报 `target_commitish is missing`**）：

   ```bash
   curl -s -X POST "https://gitee.com/api/v5/repos/chenxihh/test_c/releases" \
     -d "access_token=$TOKEN" -d "tag_name=v1.0.1" -d "name=v1.0.1 测试版" \
     -d "target_commitish=$(git rev-list -n1 v1.0.1)" -d "prerelease=true" \
     --data-urlencode "body=$BODY"
   ```

3. 上传附件（**multipart，`access_token` 也作为表单字段**），`{release_id}` 取上一步返回的 `id`：

   ```bash
   curl -s -X POST "https://gitee.com/api/v5/repos/chenxihh/test_c/releases/{release_id}/attach_files" \
     -F "access_token=$TOKEN" -F "file=@R:/build/app/outputs/flutter-apk/ncpu-timetable-1.0.1-universal.apk"
   ```

4. 读回校验：`GET /releases/{release_id}` 确认附件存在，再下载一次比对 SHA-256。

### ⚠️ Windows 下传中文给 API 的编码陷阱（2026-09-12 踩到）

**不要把非 ASCII 文本直接写在命令行里传给 `curl`。** 首次发布时标题与说明里的中文被逐字节替换成 U+FFFD（替换字符），Gitee 页面上显示成一串 `?`；而 ASCII 部分（Tag、SHA-256）完好。原因是 Git Bash 把命令行参数交给 Windows 原生 `curl.exe` 时的编码转换破坏了字节。

正确做法是让文本**不经过命令行**：

- 用 Write 之类的方式落成 UTF-8 文件，再用 `--data-urlencode "body@文件路径"`；或
- 直接用 Python 读 UTF-8 文件发请求（本次采用）：

```python
payload = urllib.parse.urlencode(
    {'access_token': TOKEN, 'tag_name': 'v1.0.1', 'name': title, 'body': body}
).encode('utf-8')
req = urllib.request.Request(API + '/releases/' + RID, data=payload, method='PATCH')
```

修复已有发行版用 `PATCH /releases/{id}`，**必须同时带 `tag_name`**（否则报 `tag_name is missing`），`name` / `body` 会整体替换。

**验证写操作时不要只看问号**：`?` 可能只是控制台的渲染结果，真正的损坏是 **U+FFFD**。判据应为「中文字符数 > 0 且 U+FFFD 数 == 0」，并与本地期望字符串**逐字比较**。本轮曾因只数 `?` 而误判为"显示问题"，实际数据已损坏。

（本地 `git commit` / `git tag` 的中文不受影响：抽查线上提交 `645b890` 正文 86 个汉字、0 个 U+FFFD，完好。）

`CONFIRMED` 接口事实：`GET /releases` 与 `GET /releases/{id}` 公开可读；`POST /releases`、`POST /releases/{id}/attach_files` 不带令牌返回 `HTTP 401` + `{"message":"登录失效，无权限访问该资源","code":40001}`，必须携带 `access_token`。令牌权限勾 `projects` 即可。

安全：令牌只在本机命令行内使用，未写入任何文件（已扫描确认仓库内无令牌痕迹）。**发布完成后应立即到 Gitee 撤销该令牌**，尤其是曾把令牌贴进聊天记录的场合。

## 约束与风险

- **换签名必须卸载**：正式签名与 debug 签名不兼容，切换时本机课表与登录态会丢。真机切换只能在 TASK-019 / TASK-039 验收关闭之后进行。
- **keystore + 密码是本 App 的长期身份**：丢失后无法用同一签名发布更新（设备会拒绝覆盖安装）。必须离线备份 keystore 文件与 `android/key.properties` 两样东西。
- **绝不入库**：仓库是公开的。keystore 放在 `D:\Tools\android-keys\`，`key.properties` 已被 gitignore。
- **不要删除 `D:\Tools\android-keys\`**，也不要把 keystore 移入项目目录。
- Play Store 上传需要 AAB（`flutter build appbundle`）与 v3 签名，本轮不做。
