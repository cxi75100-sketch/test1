class Semester {
  const Semester({
    required this.id,
    required this.name,
    required this.firstWeekMonday,
    required this.totalWeeks,
  });

  final String id;
  final String name;
  final DateTime firstWeekMonday;
  final int totalWeeks;
}
