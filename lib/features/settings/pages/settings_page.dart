import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../core/theme/theme_preference_provider.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../models/semester.dart';
import '../../notifications/models/notification_preferences.dart';
import '../../notifications/providers/notification_providers.dart';
import '../../notifications/services/notification_coordinator.dart';
import '../../timetable/providers/timetable_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semester = ref.watch(activeSemesterProvider);
    final notificationPreferences = ref.watch(notificationPreferencesProvider);
    final reminder =
        notificationPreferences.value ?? const NotificationPreferences();
    final reminderLoading = notificationPreferences.isLoading;
    final themePreference =
        ref.watch(themePreferenceProvider).value ?? ThemePreference.system;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置中心',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            Text(
              'PREFERENCES',
              style: TextStyle(
                color: AppPalette.coral,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: AmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.ink, Color(0xFF29355E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3318213D),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppPalette.sun,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppPalette.ink,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '南昌工学院',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '本地课表 · 数据只保存在此设备',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.mint,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 13,
                                color: AppPalette.ink,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '仅本机存储',
                                style: TextStyle(
                                  color: AppPalette.ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('外观'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _ThemeSelector(
                  value: themePreference,
                  onChanged: (value) => setThemePreference(ref, value),
                ),
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
            Card(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: reminder.enabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    iconColor: const Color(0xFFF09A4B),
                    title: '上课提醒',
                    subtitle: reminder.enabled
                        ? '已开启 · 提前 ${reminder.minutesBefore} 分钟'
                        : '已关闭 · 默认提前 15 分钟',
                    trailing: Switch(
                      value: reminder.enabled,
                      onChanged: reminderLoading
                          ? null
                          : (value) =>
                                _setNotificationEnabled(context, ref, value),
                    ),
                  ),
                  if (reminder.enabled) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 64),
                      child: Divider(),
                    ),
                    _SettingsTile(
                      icon: Icons.schedule_rounded,
                      iconColor: const Color(0xFF4967D8),
                      title: '提醒时间',
                      subtitle: '课程开始前',
                      trailing: DropdownButton<int>(
                        value: reminder.minutesBefore,
                        underline: const SizedBox.shrink(),
                        items: notificationMinuteOptions
                            .map(
                              (minutes) => DropdownMenuItem(
                                value: minutes,
                                child: Text('$minutes 分钟'),
                              ),
                            )
                            .toList(),
                        onChanged: reminderLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  _setNotificationMinutes(ref, value);
                                }
                              },
                      ),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(left: 64),
                    child: Divider(),
                  ),
                  const _SettingsTile(
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
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _setNotificationEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final result = await ref
        .read(notificationCoordinatorProvider)
        .setEnabled(enabled);
    if (!context.mounted) return;
    if (!enabled) {
      if (result == NotificationEnableResult.failed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('提醒已关闭，但系统排程清理失败，请重试')));
      }
      return;
    }
    final message = switch (result) {
      NotificationEnableResult.enabled => '上课提醒已开启',
      NotificationEnableResult.enabledInexact => '已开启；精确闹钟未授权，系统可能延迟提醒',
      NotificationEnableResult.permissionDenied => '未获得通知权限，提醒保持关闭',
      NotificationEnableResult.failed => '开启失败，请稍后重试',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setNotificationMinutes(WidgetRef ref, int minutes) =>
      ref.read(notificationCoordinatorProvider).setMinutesBefore(minutes);

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
    child: Row(
      children: [
        Container(
          width: 7,
          height: 18,
          decoration: BoxDecoration(
            color: AppPalette.coral,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemePreference value;
  final ValueChanged<ThemePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: ThemePreference.values.map((preference) {
        final selected = preference == value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: preference == ThemePreference.dark ? 0 : 6,
            ),
            child: Semantics(
              selected: selected,
              button: true,
              label: '${preference.label}主题',
              child: InkWell(
                key: ValueKey('theme-${preference.storageValue}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () => onChanged(preference),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.55)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        preference.icon,
                        size: 21,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preference.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final Widget? trailing;

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
    trailing:
        trailing ??
        (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
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
