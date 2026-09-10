import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/semester.dart';
import '../adapters/school_adapter.dart';
import '../providers/import_capture_providers.dart';
import '../providers/import_providers.dart';
import '../services/import_capture.dart';
import '../services/import_capture_script.dart';
import '../services/import_diff.dart';
import '../services/import_session_cleaner.dart';
import '../services/navigation_policy.dart';
import '../widgets/import_preview_dialog.dart';
import '../../timetable/providers/timetable_providers.dart';

/// 教务登录 WebView 页面。
///
/// 安全约束：
/// - 候选入口未经真机验证，且当前使用 HTTP；加载前必须由用户确认风险。
/// - 不创建账号密码输入框；用户只在候选教务页面输入凭证。
/// - 不保存、不上传、不打印账号或密码。
/// - 不输出 Cookie / Session ID / 完整 Token。
/// - 导航白名单由 [NavigationPolicy] 控制；未知域名阻止并展示脱敏域名。
/// - 接口采集仅在 Debug 模式启用：只记录 XHR/fetch 的路径、参数名与
///   响应字段结构，表单提交（账号密码）天然不在采集范围内，且记录会先
///   经过 [ImportCaptureSanitizer] 脱敏后才进入内存。
class ImportLoginPage extends ConsumerStatefulWidget {
  const ImportLoginPage({super.key});

  @override
  ConsumerState<ImportLoginPage> createState() => _ImportLoginPageState();
}

class _ImportLoginPageState extends ConsumerState<ImportLoginPage> {
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _isLoading = false;
  String? _blockedHost;
  bool _isImporting = false;
  bool _pageLoaded = false;
  bool _riskAccepted = false;
  String? _loadError;

  static const _policy = NavigationPolicy();

  /// dispose() 里不能再碰 ref（Riverpod 在 unmount 时会抛错），
  /// 因此把离开页面时要清理的对象提前取好。
  late final ImportRawTimetable _rawTimetable;
  late final ImportSessionCleaner _sessionCleaner;

  @override
  void initState() {
    super.initState();
    _rawTimetable = ref.read(importRawTimetableProvider.notifier);
    _sessionCleaner = ref.read(importSessionCleanerProvider);
  }

  @override
  void dispose() {
    // 先清 HTTP 缓存再销毁控制器：静态调用不依赖 controller 实例。
    // 按用户选择保留 Cookie 与 WebStorage，下次导入免登录（见 decisions.md）。
    if (_controller != null) {
      unawaited(_sessionCleaner.clearHttpCache());
    }
    _controller?.dispose();
    // 课表原始响应含身份字段，页面销毁后不应继续驻留内存。
    _rawTimetable.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adapter = ref.watch(schoolAdapterProvider);
    final captureCount = ref.watch(importCaptureProvider).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${adapter.schoolName}教务登录'),
        actions: [
          IconButton(
            tooltip: '返回',
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _riskAccepted ? _reload : null,
          ),
          if (kDebugMode)
            IconButton(
              tooltip: '接口采集（Debug）',
              icon: Badge(
                isLabelVisible: captureCount > 0,
                label: Text('$captureCount'),
                child: const Icon(Icons.science_outlined),
              ),
              onPressed: () => context.push('/import/capture'),
            ),
        ],
      ),
      body: _riskAccepted
          ? Column(
              children: [
                _buildSecurityBanner(adapter),
                if (_isLoading)
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                  ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(adapter.loginUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      clearCache: false,
                    ),
                    // 取数脚本所有构建都注入；脱敏采集上报只在 Debug 打开。
                    initialUserScripts: UnmodifiableListView<UserScript>([
                      UserScript(
                        source: importUserScript,
                        injectionTime:
                            UserScriptInjectionTime.AT_DOCUMENT_START,
                      ),
                      if (kDebugMode)
                        UserScript(
                          source: importCaptureEnableScript,
                          injectionTime:
                              UserScriptInjectionTime.AT_DOCUMENT_START,
                        ),
                    ]),
                    onWebViewCreated: _onWebViewCreated,
                    onProgressChanged: (c, progress) {
                      setState(() => _progress = progress / 100);
                    },
                    onLoadStart: (c, url) {
                      setState(() {
                        _isLoading = true;
                        _blockedHost = null;
                        _loadError = null;
                      });
                    },
                    onReceivedError: (c, request, error) {
                      // 只关心主框架失败；子资源失败不改变整页状态。
                      if (!mounted || request.isForMainFrame == false) return;
                      setState(() {
                        _isLoading = false;
                        _loadError = error.description;
                      });
                    },
                    onReceivedHttpError: (c, request, errorResponse) {
                      if (!mounted || request.isForMainFrame == false) return;
                      final status = errorResponse.statusCode ?? 0;
                      if (status >= 400) {
                        setState(() {
                          _isLoading = false;
                          _loadError = 'HTTP $status';
                        });
                      }
                    },
                    onLoadStop: (c, url) {
                      setState(() {
                        _isLoading = false;
                        _pageLoaded = true;
                      });
                    },
                    shouldOverrideUrlLoading: (c, action) async {
                      final uri = action.request.url;
                      if (uri == null) return NavigationActionPolicy.CANCEL;
                      final eval = _policy.evaluate(uri);
                      if (!eval.isAllowed && mounted) {
                        setState(() {
                          _blockedHost = _policy.redactedHost(uri);
                        });
                      }
                      return eval.isAllowed
                          ? NavigationActionPolicy.ALLOW
                          : NavigationActionPolicy.CANCEL;
                    },
                  ),
                ),
                _buildBottomBar(adapter),
              ],
            )
          : _buildRiskGate(adapter),
    );
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    controller.addJavaScriptHandler(
      handlerName: importTimetableHandlerName,
      callback: _handleTimetableData,
    );
    if (!kDebugMode) return;
    controller.addJavaScriptHandler(
      handlerName: importCaptureHandlerName,
      callback: _handleCapturedRequest,
    );
  }

  /// 课表原始响应只留在内存，供本次导入解析；不写文件、不写日志。
  Object? _handleTimetableData(List<dynamic> args) {
    if (args.isEmpty) return null;
    final raw = args.first;
    if (raw is! String || raw.isEmpty) return null;
    ref.read(importRawTimetableProvider.notifier).store(raw);
    return null;
  }

  /// 接收注入脚本上报的请求，先脱敏再进入内存列表。
  Object? _handleCapturedRequest(List<dynamic> args) {
    if (args.isEmpty) return null;
    final data = args.first;
    if (data is! Map) return null;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) return null;
    final entry = ref
        .read(importCaptureSanitizerProvider)
        .sanitize(
          method: (data['method'] as String?) ?? 'GET',
          url: url,
          requestBody: data['requestBody'] as String?,
          status: (data['status'] as num?)?.toInt(),
          contentType: data['contentType'] as String?,
          responseBody: data['responseBody'] as String?,
        );
    ref.read(importCaptureProvider.notifier).add(entry);
    return null;
  }

  Widget _buildRiskGate(SchoolAdapter adapter) {
    final uri = Uri.parse(adapter.loginUrl);
    final displayHost = _policy.redactedHost(uri);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '登录前请确认风险',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('候选地址：$displayHost'),
                    const SizedBox(height: 10),
                    const Text('该地址来自项目候选配置，尚未经过真机核验，不能据此认定为学校当前官方教务地址。'),
                    const SizedBox(height: 10),
                    const Text(
                      '当前入口使用 HTTP，传输未加密。账号、密码和登录会话可能被同一网络中的第三方截获。',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    const Text('仅在你能自行确认该域名属于学校且愿意承担 HTTP 风险时继续。'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _riskAccepted = true;
                            _isLoading = true;
                          });
                        },
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('我已了解风险，继续打开'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBanner(SchoolAdapter adapter) {
    if (_loadError != null) return _buildErrorBanner();
    if (_blockedHost != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.shade100,
        child: Row(
          children: [
            const Icon(Icons.block, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '已阻止跳转到 $_blockedHost（域名未验证）',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.shade50,
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '正在加载候选地址 ${_policy.redactedHost(Uri.parse(adapter.loginUrl))} · HTTP 未加密',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    if (_pageLoaded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.shade50,
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '候选教务页面 · 域名未真机核验 · HTTP 未加密',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// 把 WebView 的原始错误映射成用户能照着做的提示。
  String _failureHint(String description) {
    final text = description.toUpperCase();
    if (text.contains('NAME_NOT_RESOLVED') ||
        text.contains('HOST_LOOKUP') ||
        text.contains('INTERNET_DISCONNECTED') ||
        text.contains('DNS')) {
      return '网络不通：请确认手机已连接 WiFi 或移动数据，然后点重试。';
    }
    if (text.contains('TIMEOUT') || text.contains('CONNECT')) {
      return '无法连接服务器：可能需要在校园网内访问，或服务器暂时不可用。';
    }
    if (text.contains('CLEARTEXT')) {
      return '系统拦截了明文 HTTP 请求，需要调整网络安全配置。';
    }
    return '可以点重试；若持续失败，请把上面的错误码发给我。';
  }

  Widget _buildErrorBanner() {
    final description = _loadError!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      color: Colors.red.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '页面加载失败：$description',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_failureHint(description), style: const TextStyle(fontSize: 12)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(SchoolAdapter adapter) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isImporting ? null : () => _tryImport(adapter),
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isImporting ? '导入中…' : '尝试导入课表'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              kDebugMode
                  ? '先在页面里打开「信息查询 → 学生课表查询」，再点上方按钮导入（Debug 采集已开启）'
                  : '先在页面里打开「信息查询 → 学生课表查询」，再点上方按钮导入',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goBack() async {
    final c = _controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _reload() async {
    await _controller?.reload();
  }

  /// 可靠地取得当前学期。
  ///
  /// 不用 `ref.read(activeSemesterProvider)`：数据流尚未发出首个事件时会读到 null，
  /// 从而误报"还没有学期"。这里等待数据就绪，并在流不可用时直接查库兜底。
  Future<Semester?> _resolveSemester() async {
    final database = ref.read(databaseProvider);
    try {
      await ref.read(databaseReadyProvider.future);
      final semesters = await ref.read(semestersProvider.future);
      if (semesters.isNotEmpty) return semesters.first;
    } on Exception {
      // 落到直接查库。
    }
    return database.currentSemester();
  }

  Future<void> _tryImport(SchoolAdapter adapter) async {
    setState(() => _isImporting = true);
    try {
      final semester = await _resolveSemester();
      if (!mounted) return;
      if (semester == null) {
        await _showMessage(
          '导入课表',
          '本地还没有学期，请先在「设置 → 学期设置」里保存一次学期信息，再回来导入。',
        );
        return;
      }
      final result = adapter.parseTimetable(
        ref.read(importRawTimetableProvider) ?? '',
        semesterId: semester.id,
      );
      if (!mounted) return;
      switch (result) {
        case ImportSuccess(:final courses):
          final database = ref.read(databaseProvider);
          // 必须在替换前取旧列表：replaceImportedCourses 会删掉上一次导入的记录。
          final previous = await database.watchCourses(semester.id).first;
          if (!mounted) return;
          final confirmed = await ImportPreviewDialog.show(
            context,
            schoolName: adapter.schoolName,
            courses: courses,
            diff: diffImportedCourses(previous: previous, next: courses),
          );
          if (!confirmed || !mounted) return;
          await database.replaceImportedCourses(semester.id, courses);
          if (!mounted) return;
          await _showMessage(
            '导入完成',
            '已导入 ${courses.length} 条课程安排，手动添加的课程保持不变。\n\n'
            '若周次显示不对，请在「设置 → 学期设置」里确认开学第一周的周一。',
          );
        case ImportInterfaceNotYetDiscovered(:final hint):
          await _showMessage('导入课表', hint);
        case ImportError(:final message):
          await _showMessage('导入失败', message);
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _showMessage(String title, String content) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(content)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
