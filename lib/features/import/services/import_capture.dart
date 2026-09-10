import 'dart:convert';

/// 被替换掉的敏感值占位符。
const String maskedValue = '<已脱敏>';

/// 脱敏后的单条教务请求记录。
class ImportCaptureEntry {
  const ImportCaptureEntry({
    required this.method,
    required this.path,
    required this.query,
    required this.requestBody,
    required this.status,
    required this.contentType,
    required this.responseShape,
    required this.capturedAt,
  });

  final String method;
  final String path;
  final Map<String, String> query;
  final String? requestBody;
  final int? status;
  final String? contentType;
  final String? responseShape;
  final DateTime capturedAt;

  Map<String, Object?> toJson() => {
    'method': method,
    'path': path,
    'query': query,
    'requestBody': requestBody,
    'status': status,
    'contentType': contentType,
    'responseShape': responseShape,
    'capturedAt': capturedAt.toIso8601String(),
  };
}

/// 把教务页面产生的请求/响应转换成不含身份信息的结构化记录。
///
/// 安全边界（对应 AGENTS.md「安全边界」一节）：
/// - 只记录请求方法、路径、参数名与（必要时脱敏的）值；
/// - 学号、姓名、密码、Cookie、Session、Token、CSRF 等一律替换为 [maskedValue]；
/// - 响应体**不做原文保存**，只保留字段名、类型与截断后的样例值，供编写 parser 使用；
/// - 采集只在 Debug 模式启用，由调用方负责保证。
class ImportCaptureSanitizer {
  const ImportCaptureSanitizer({
    this.maxSampleLength = 40,
    this.maxShapeKeys = 200,
    this.maxDepth = 6,
    this.maxTextPreview = 300,
    this.maxDigestEntries = 40,
  });

  final int maxSampleLength;
  final int maxShapeKeys;
  final int maxDepth;
  final int maxTextPreview;

  /// 数组摘要最多列出多少条，用于核对"服务端返回 N 条、本地解析出 M 条"的差异。
  final int maxDigestEntries;

  /// 生成数组摘要时优先展示的字段（存在即用），覆盖课表与通用列表接口。
  static const List<String> digestKeyCandidates = [
    'kcmc',
    'xqj',
    'jcs',
    'jc',
    'zcd',
    'cdmc',
    'jxb_id',
    'ZDM',
    'ZDMC',
    'SFXS',
  ];

  /// 键名命中即脱敏（小写精确匹配）。
  static const Set<String> sensitiveKeys = {
    'su', // 正方教务中 su 为加密后的学号
    'yhm', // 用户名
    'mm', // 密码
    'pwd',
    'password',
    'passwd',
    'csrftoken',
    'csrf',
    'token',
    'session',
    'sessionid',
    'jsessionid',
    'sid',
    'ticket',
    'auth',
    'authorization',
    'cookie',
    'openid',
    'unionid',
    'uuid',
    'sign',
    'signature',
    'xh', // 学号
    'xm', // 姓名
    'name',
    'sfzh',
    'sfz',
    'mobile',
    'sjh',
  };

  ImportCaptureEntry sanitize({
    required String method,
    required String url,
    String? requestBody,
    int? status,
    String? contentType,
    String? responseBody,
    DateTime? capturedAt,
  }) {
    final uri = Uri.tryParse(url);
    return ImportCaptureEntry(
      method: method.toUpperCase(),
      path: uri?.path ?? url,
      query: {
        if (uri != null)
          for (final entry in uri.queryParameters.entries)
            entry.key: _sanitizeQueryValue(entry.key, entry.value),
      },
      requestBody: _sanitizeRequestBody(requestBody),
      status: status,
      contentType: contentType,
      responseShape: _describeResponse(responseBody),
      capturedAt: capturedAt ?? DateTime.now(),
    );
  }

  String _sanitizeQueryValue(String key, String value) {
    if (isSensitiveKey(key)) return maskedValue;
    if (value.length > 24) return '$maskedValue(len=${value.length})';
    return value;
  }

  bool isSensitiveKey(String key) => sensitiveKeys.contains(key.trim().toLowerCase());

  String? _sanitizeRequestBody(String? body) {
    if (body == null || body.trim().isEmpty) return null;
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return _describeValue(jsonDecode(trimmed), 0);
      } on FormatException {
        // 不是合法 JSON，退回文本处理。
      }
    }
    final pairs = _parseFormBody(trimmed);
    if (pairs.isNotEmpty) {
      return pairs.entries
          .map((e) => '${e.key}=${_sanitizeQueryValue(e.key, e.value)}')
          .join('&');
    }
    return _maskLongTokens(trimmed);
  }

  /// 手工解析 `a=1&b=2`，避免对畸形输入抛异常。
  Map<String, String> _parseFormBody(String body) {
    final pairs = <String, String>{};
    try {
      for (final part in body.split('&')) {
        if (part.isEmpty) continue;
        final index = part.indexOf('=');
        if (index <= 0) continue;
        pairs[Uri.decodeQueryComponent(part.substring(0, index))] =
            Uri.decodeQueryComponent(part.substring(index + 1));
      }
    } on ArgumentError {
      return const {};
    } on FormatException {
      return const {};
    }
    return pairs;
  }

  String? _describeResponse(String? body) {
    if (body == null || body.trim().isEmpty) return null;
    final trimmed = body.trim();
    try {
      return _describeValue(jsonDecode(trimmed), 0);
    } on FormatException {
      final masked = _maskLongTokens(trimmed);
      return masked.length > maxTextPreview
          ? '${masked.substring(0, maxTextPreview)}…(共 ${masked.length} 字符)'
          : masked;
    }
  }

  /// 把疑似高熵串（长 token / base64）与长数字串替换掉。
  String _maskLongTokens(String text) => text
      .replaceAll(RegExp(r'[A-Za-z0-9_\-]{24,}'), maskedValue)
      .replaceAll(RegExp(r'\d{8,}'), maskedValue);

  String _describeValue(Object? value, int depth, {String? keyHint, String indent = ''}) {
    if (depth > maxDepth) return '…';
    if (value == null) return 'null';
    if (value is Map) {
      if (value.isEmpty) return 'object{}';
      final keys = value.keys.take(maxShapeKeys).toList();
      final buffer = StringBuffer('object{${value.length}} {\n');
      for (final key in keys) {
        buffer.writeln(
          '$indent  $key: '
          '${_describeValue(value[key], depth + 1, keyHint: '$key', indent: '$indent  ')}',
        );
      }
      if (value.length > keys.length) {
        buffer.writeln('$indent  …省略 ${value.length - keys.length} 个字段');
      }
      buffer.write('$indent}');
      return buffer.toString();
    }
    if (value is List) {
      if (value.isEmpty) return 'array[0]';
      final first = value.first;
      if (first is Map) {
        final buffer = StringBuffer('array[${value.length}] of ')
          ..write(_describeValue(first, depth + 1, keyHint: keyHint, indent: indent));
        final digestKeys = digestKeyCandidates
            .where(first.containsKey)
            .toList();
        if (digestKeys.isNotEmpty) {
          final limit = value.length < maxDigestEntries
              ? value.length
              : maxDigestEntries;
          buffer.write('\n$indent每条摘要：');
          for (var i = 0; i < limit; i++) {
            final element = value[i];
            if (element is! Map) continue;
            final parts = digestKeys
                .where(element.containsKey)
                .map((key) => '$key=${_describeScalar(element[key], key)}')
                .join(' ');
            buffer.write('\n$indent  [${i + 1}] $parts');
          }
          if (value.length > limit) {
            buffer.write('\n$indent  …其余 ${value.length - limit} 条省略');
          }
        }
        return buffer.toString();
      }
      if (first is List) {
        return 'array[${value.length}] of '
            '${_describeValue(first, depth + 1, keyHint: keyHint, indent: indent)}';
      }
      final samples = value.take(4).map((e) => _describeScalar(e, keyHint)).join(', ');
      return 'array[${value.length}] [$samples${value.length > 4 ? ', …' : ''}]';
    }
    return _describeScalar(value, keyHint);
  }

  String _describeScalar(Object? value, String? keyHint) {
    if (value == null) return 'null';
    if (value is num || value is bool) return '$value';
    final text = value.toString();
    if (keyHint != null && isSensitiveKey(keyHint)) {
      return '"$maskedValue(len=${text.length})"';
    }
    if (RegExp(r'^\d{8,}$').hasMatch(text)) {
      return '"$maskedValue(len=${text.length})"';
    }
    if (text.length > maxSampleLength) {
      return '"${text.substring(0, maxSampleLength)}…"(len=${text.length})';
    }
    return '"$text"';
  }
}

/// 生成便于阅读与转发的脱敏报告文本。
String buildImportCaptureReport(
  List<ImportCaptureEntry> entries, {
  DateTime? generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('# 教务接口脱敏采集报告')
    ..writeln()
    ..writeln('生成时间：${(generatedAt ?? DateTime.now()).toIso8601String()}')
    ..writeln('条目数：${entries.length}')
    ..writeln()
    ..writeln('说明：仅包含请求方法、路径、参数名与结构骨架；')
    ..writeln('学号、姓名、密码、Cookie、Session、Token 已替换为 $maskedValue。')
    ..writeln();

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    buffer
      ..writeln('## [${i + 1}] ${entry.method} ${entry.path}')
      ..writeln('时间：${entry.capturedAt.toIso8601String()}');
    if (entry.query.isNotEmpty) {
      buffer.writeln(
        'query：${entry.query.entries.map((e) => '${e.key}=${e.value}').join('&')}',
      );
    }
    if (entry.status != null || entry.contentType != null) {
      buffer.writeln('响应：status=${entry.status ?? '?'} content-type=${entry.contentType ?? '?'}');
    }
    if (entry.requestBody != null) {
      buffer
        ..writeln('请求体：')
        ..writeln('```')
        ..writeln(entry.requestBody)
        ..writeln('```');
    }
    if (entry.responseShape != null) {
      buffer
        ..writeln('响应结构：')
        ..writeln('```')
        ..writeln(entry.responseShape)
        ..writeln('```');
    }
    buffer.writeln();
  }
  return buffer.toString();
}
