import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/course_colors.dart';
import '../../../models/course.dart';
import '../../import/parsers/week_parser.dart';
import '../providers/timetable_providers.dart';

class CourseFormPage extends ConsumerStatefulWidget {
  const CourseFormPage({this.courseId, super.key});
  final String? courseId;

  @override
  ConsumerState<CourseFormPage> createState() => _CourseFormPageState();
}

class _CourseFormPageState extends ConsumerState<CourseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _teacher = TextEditingController();
  final _classroom = TextEditingController();
  final _weeks = TextEditingController(text: '1-20周');
  final _note = TextEditingController();
  int _weekday = 1;
  int _startSection = 1;
  int _endSection = 2;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _teacher.dispose();
    _classroom.dispose();
    _weeks.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.courseId == null
        ? const AsyncData<Course?>(null)
        : ref.watch(courseProvider(widget.courseId!));
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseId == null ? '新增课程' : '编辑课程')),
      body: existing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (course) {
          if (!_initialized) {
            _initialized = true;
            if (course != null) _load(course);
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: '课程名 *'),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入课程名' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _teacher,
                        decoration: const InputDecoration(labelText: '教师'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _classroom,
                        decoration: const InputDecoration(labelText: '教室'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _weekday,
                  decoration: const InputDecoration(labelText: '星期 *'),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        '周${const ['一', '二', '三', '四', '五', '六', '日'][i]}',
                      ),
                    ),
                  ),
                  onChanged: (value) => setState(() => _weekday = value!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _startSection,
                        decoration: const InputDecoration(labelText: '开始节次'),
                        items: _sections(),
                        onChanged: (value) => setState(() {
                          _startSection = value!;
                          if (_endSection < value) _endSection = value;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _endSection,
                        decoration: const InputDecoration(labelText: '结束节次'),
                        items: _sections(),
                        onChanged: (value) =>
                            setState(() => _endSection = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weeks,
                  decoration: const InputDecoration(
                    labelText: '上课周次 *',
                    hintText: '如 1-16周(单)',
                  ),
                  validator: (value) {
                    try {
                      parseWeeks(value ?? '');
                      return null;
                    } on FormatException catch (error) {
                      return error.message;
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: '备注'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(course),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? '保存中…' : '保存课程'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<int>> _sections() => List.generate(
    12,
    (i) => DropdownMenuItem(value: i + 1, child: Text('第 ${i + 1} 节')),
  );

  void _load(Course course) {
    _name.text = course.name;
    _teacher.text = course.teacher;
    _classroom.text = course.classroom;
    _weeks.text = formatWeeks(course.weeks);
    _note.text = course.note;
    _weekday = course.weekday;
    _startSection = course.startSection;
    _endSection = course.endSection;
  }

  Future<void> _save(Course? existing) async {
    if (!_formKey.currentState!.validate()) return;
    if (_endSection < _startSection) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('结束节次不能早于开始节次')));
      return;
    }
    final semester = ref.read(activeSemesterProvider);
    if (semester == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('学期尚未初始化，请稍后重试')));
      return;
    }
    setState(() => _saving = true);
    final name = _name.text.trim();
    final course = Course(
      id: existing?.id ?? 'manual-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      teacher: _teacher.text.trim(),
      classroom: _classroom.text.trim(),
      weekday: _weekday,
      startSection: _startSection,
      endSection: _endSection,
      weeks: parseWeeks(_weeks.text),
      semesterId: semester.id,
      colorKey: existing?.colorKey ?? courseColorKeyForName(name),
      note: _note.text.trim(),
      source: existing?.source ?? CourseSource.manual,
    );
    await ref.read(databaseProvider).upsertCourse(course);
    ref.invalidate(courseProvider(course.id));
    if (mounted) context.pop();
  }
}
