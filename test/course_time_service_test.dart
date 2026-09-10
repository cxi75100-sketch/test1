import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/models/course.dart';
import 'package:ncpu_timetable/services/course_time_service.dart';

void main() {
  const service = CourseTimeService();

  Course course({
    required String classroom,
    int startSection = 3,
    int endSection = 4,
    String? startTime,
    String? endTime,
  }) => Course(
    id: 'course',
    name: '课程',
    classroom: classroom,
    weekday: 1,
    startSection: startSection,
    endSection: endSection,
    startTime: startTime,
    endTime: endTime,
    weeks: const [1],
    semesterId: 'semester',
    colorKey: 0,
  );

  test('明志楼、明德楼、至善楼第 3-4 节使用提前作息', () {
    for (final building in ['明志楼404', '明德楼A201', '至善楼 305']) {
      expect(
        service.resolve(course(classroom: building))?.label,
        '10:15-11:45',
      );
    }
  });

  test('其他教学场所第 3-4 节使用通用作息', () {
    expect(
      service.resolve(course(classroom: '西区实训中心3-A010'))?.label,
      '10:25-11:55',
    );
  });

  test('其他节次使用教学周历统一时间', () {
    expect(
      service
          .resolve(course(classroom: '明志楼404', startSection: 1, endSection: 2))
          ?.label,
      '08:20-09:50',
    );
    expect(
      service
          .resolve(course(classroom: '其他教学楼', startSection: 9, endSection: 10))
          ?.label,
      '19:00-20:30',
    );
  });

  test('课程明确填写的时间优先于教学楼推导', () {
    expect(
      service
          .resolve(
            course(classroom: '明志楼404', startTime: '10:30', endTime: '12:00'),
          )
          ?.label,
      '10:30-12:00',
    );
  });
}
