import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/semester.dart';
import '../../timetable/providers/timetable_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semester = ref.watch(activeSemesterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF405FD0), Color(0xFF6C63DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '南昌工学院',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '本地课表 · 数据只保存在此设备',
                        style: TextStyle(
                          color: Color(0xFFDCE2FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('课表'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.cloud_download_outlined,
                  iconColor: const Color(0xFF4967D8),
                  title: '教务导入',
                  subtitle: '打开候选教务地址（首次进入会提示风险）',
                  onTap: () => context.push('/import/login'),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 64),
                  child: Divider(),
                ),
                _SettingsTile(
                  icon: Icons.calendar_month_outlined,
                  iconColor: const Color(0xFF28A184),
                  title: '学期设置',
                  subtitle: semester == null
                      ? '正在初始化…'
                      : '${semester.name} · ${semester.totalWeeks} 周\n开学周一 ${_date(semester.firstWeekMonday)}',
                  onTap: semester == null
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (context) => _SemesterDialog(
                            initial: semester,
                            onSave: ref.read(databaseProvider).upsertSemester,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('偏好与隐私'),
          const Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: Color(0xFFF09A4B),
                  title: '上课提醒',
                  subtitle: '将在教务导入稳定后开放',
                ),
                Padding(padding: EdgeInsets.only(left: 64), child: Divider()),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  iconColor: Color(0xFF7A67C7),
                  title: '隐私说明',
                  subtitle: '不保存教务密码，课程数据仅存本机',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('数据管理'),
          Card(
            child: _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: Theme.of(context).colorScheme.error,
              title: '清空当前学期课程',
              subtitle: '同时删除手动与教务导入的课程',
              titleColor: Theme.of(context).colorScheme.error,
              onTap: semester == null
                  ? null
                  : () => _clearSemester(context, ref, semester),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _clearSemester(
    BuildContext context,
    WidgetRef ref,
    Semester semester,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('清空当前学期课程？'),
            content: const Text('该操作会删除当前学期的手动课程和导入课程，且无法在 App 内撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认清空'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await ref.read(databaseProvider).clearSemester(semester.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('当前学期课程已清空')));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
    child: Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 21),
    ),
    title: Text(
      title,
      style: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(subtitle, style: const TextStyle(height: 1.35)),
    ),
    trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _SemesterDialog extends StatefulWidget {
  const _SemesterDialog({required this.initial, required this.onSave});
  final Semester initial;
  final Future<void> Function(Semester semester) onSave;

  @override
  State<_SemesterDialog> createState() => _SemesterDialogState();
}

class _SemesterDialogState extends State<_SemesterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _weeks;
  late DateTime _firstMonday;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.name);
    _weeks = TextEditingController(text: '${widget.initial.totalWeeks}');
    _firstMonday = widget.initial.firstWeekMonday;
  }

  @override
  void dispose() {
    _name.dispose();
    _weeks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('学期设置'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '学期名称'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请输入学期名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weeks,
              decoration: const InputDecoration(labelText: '总教学周'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                return parsed == null || parsed < 1 || parsed > 30
                    ? '请输入 1-30'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('第一周周一'),
              subtitle: Text(SettingsPage._date(_firstMonday)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? '保存中…' : '保存'),
      ),
    ],
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstMonday,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: '选择第一周周一',
    );
    if (picked == null) return;
    setState(() {
      _firstMonday = picked.subtract(Duration(days: picked.weekday - 1));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSave(
      Semester(
        id: widget.initial.id,
        name: _name.text.trim(),
        firstWeekMonday: _firstMonday,
        totalWeeks: int.parse(_weeks.text),
      ),
    );
    if (mounted) Navigator.pop(context);
  }
}
