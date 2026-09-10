enum CourseSource { manual, ncpu }

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weeks,
    required this.semesterId,
    required this.colorKey,
    this.teacher = '',
    this.classroom = '',
    this.startTime,
    this.endTime,
    this.note = '',
    this.source = CourseSource.manual,
  });

  final String id;
  final String name;
  final String teacher;
  final String classroom;
  final int weekday;
  final int startSection;
  final int endSection;
  final String? startTime;
  final String? endTime;
  final List<int> weeks;
  final String semesterId;
  final int colorKey;
  final String note;
  final CourseSource source;

  Course copyWith({
    String? id,
    String? name,
    String? teacher,
    String? classroom,
    int? weekday,
    int? startSection,
    int? endSection,
    String? startTime,
    String? endTime,
    List<int>? weeks,
    String? semesterId,
    int? colorKey,
    String? note,
    CourseSource? source,
  }) => Course(
    id: id ?? this.id,
    name: name ?? this.name,
    teacher: teacher ?? this.teacher,
    classroom: classroom ?? this.classroom,
    weekday: weekday ?? this.weekday,
    startSection: startSection ?? this.startSection,
    endSection: endSection ?? this.endSection,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    weeks: weeks ?? this.weeks,
    semesterId: semesterId ?? this.semesterId,
    colorKey: colorKey ?? this.colorKey,
    note: note ?? this.note,
    source: source ?? this.source,
  );
}
