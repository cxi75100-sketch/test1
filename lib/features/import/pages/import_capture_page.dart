import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/import_capture_providers.dart';
import '../services/import_capture.dart';
import '../services/import_capture_file.dart';

/// 脱敏接口采集结果的查看页（仅 Debug 模式入口可见）。
///
/// 页面里显示的、复制出去的、写进文件的都已经是脱敏后的内容：
/// 不含学号、姓名、密码、Cookie、Session 或 Token。
class ImportCapturePage extends ConsumerWidget {
  const ImportCapturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(importCaptureProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('接口采集（Debug）'),
        actions: [
          IconButton(
            tooltip: '复制脱敏报告',
            icon: const Icon(Icons.copy_all),
            onPressed: entries.isEmpty
                ? null
                : () => _copyReport(context, entries),
          ),
          IconButton(
            tooltip: '保存到文件',
            icon: const Icon(Icons.save_alt),
            onPressed: entries.isEmpty
                ? null
                : () => _saveReport(context, entries),
          ),
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.delete_outline),
            onPressed: entries.isEmpty
                ? null
                : () => ref.read(importCaptureProvider.notifier).clear(),
          ),
        ],
      ),
      body: entries.isEmpty ? const _EmptyHint() : _EntryList(entries: entries),
    );
  }

  Future<void> _copyReport(
    BuildContext context,
    List<ImportCaptureEntry> entries,
  ) async {
    final report = buildImportCaptureReport(entries);
    await Clipboard.setData(ClipboardData(text: report));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制脱敏报告')));
  }

  Future<void> _saveReport(
    BuildContext context,
    List<ImportCaptureEntry> entries,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await const ImportCaptureFile().save(entries);
    messenger.showSnackBar(
      SnackBar(
        content: Text(path == null ? '保存失败' : '已保存：$path', maxLines: 3),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(
      child: Text(
        '还没有采集到请求。\n\n'
        '请在下方教务页面登录，并进入「信息查询 / 学生课表查询」等页面，\n'
        '页面发出的同源请求会被自动脱敏记录在这里。\n\n'
        '记录只包含请求路径、参数名与响应字段结构，不含账号、密码、Cookie 或 Session。',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.entries});

  final List<ImportCaptureEntry> entries;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: entries.length,
    itemBuilder: (context, index) => _EntryCard(
      index: index + 1,
      entry: entries[index],
    ),
  );
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.index, required this.entry});

  final int index;
  final ImportCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          '$index. ${entry.method} ${entry.path}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'status=${entry.status ?? '?'} · ${entry.capturedAt.toLocal().toString().split('.').first}',
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (entry.query.isNotEmpty)
            _Section(title: 'query', body: _formatQuery(entry.query)),
          if (entry.requestBody != null)
            _Section(title: '请求体（脱敏）', body: entry.requestBody!),
          if (entry.responseShape != null)
            _Section(title: '响应结构（脱敏）', body: entry.responseShape!),
        ],
      ),
    );
  }

  String _formatQuery(Map<String, String> query) =>
      query.entries.map((e) => '${e.key}=${e.value}').join('\n');
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          body,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}
