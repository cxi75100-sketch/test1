import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/core/theme/course_colors.dart';
import 'package:ncpu_timetable/features/import/parsers/ncpu_timetable_parser.dart';
import 'package:ncpu_timetable/models/course.dart';

void main() {
  const parser = NcpuTimetableParser();

  /// 单条 kbList 记录；字段顺序与真实响应一致地不保证。
  Map<String, dynamic> entry({
    String kcmc = '工程力学',
    String xqj = '1',
    String jcs = '3-4',
    String zcd = '1-16周',
    String cdmc = '明志楼223',
    String xm = '张老师',
    String xf = '4.0',
    String kcxz = '基础必修',
    String jxbId = 'J1',
  }) => {
    'kcmc': kcmc,
    'xqj': xqj,
    'jcs': jcs,
    'zcd': zcd,
    'cdmc': cdmc,
    'xm': xm,
    'xf': xf,
    'kcxz': kcxz,
    'jxb_id': jxbId,
    'kch': '06A24004',
    // 响应里携带的身份字段与噪声字段：解析器必须忽略。
    'xsxx': {'XM': '某同学', 'XH': '20230101001', 'BJMC': '某班'},
    'date': '二○二六年九月十日',
    'queryModel': {'currentPage': 1},
  };

  String response(List<Map<String, dynamic>> entries) => jsonEncode({
    'qsxqj': '1',
    'xsxx': {'XM': '某同学', 'XH': '20230101001', 'KCMS': entries.length},
    'xqjmcMap': {'1': '星期一', '2': '星期二'},
    'kbList': entries,
  });

  test('解析课程名、星期、节次、周次、教室与教师', () {
    final courses = parser.parse(response([entry()]), semesterId: 's1');

    final course = courses.single;
    expect(course.name, '工程力学');
    expect(course.weekday, 1);
    expect(course.startSection, 3);
    expect(course.endSection, 4);
    expect(course.weeks, List.generate(16, (i) => i + 1));
    expect(course.classroom, '明志楼223');
    expect(course.teacher, '张老师');
    expect(course.note, '学分 4.0 · 基础必修');
    expect(course.semesterId, 's1');
    expect(course.source, CourseSource.ncpu);
  });

  test('不把 xsxx 里的身份信息带进课程', () {
    final course = parser.parse(response([entry()]), semesterId: 's1').single;

    final dump = [
      course.id,
      course.name,
      course.teacher,
      course.classroom,
      course.note,
    ].join('|');
    expect(dump, isNot(contains('20230101001')));
    expect(dump, isNot(contains('某同学')));
    expect(dump, isNot(contains('某班')));
  });

  test('字段顺序不同不影响解析', () {
    final shuffled = Map<String, dynamic>.fromEntries(
      entry().entries.toList().reversed,
    );
    final course = parser
        .parse(response([shuffled]), semesterId: 's1')
        .single;

    expect(course.name, '工程力学');
    expect(course.startSection, 3);
  });

  test('同一门课不同星期拆成多条且 id 唯一', () {
    final courses = parser.parse(
      response([
        entry(kcmc: '工程力学', xqj: '1', jcs: '3-4'),
        entry(kcmc: '工程力学', xqj: '3', jcs: '1-2'),
      ]),
      semesterId: 's1',
    );

    expect(courses, hasLength(2));
    expect(courses.map((c) => c.id).toSet(), hasLength(2));
    expect(courses.map((c) => c.weekday), [1, 3]);
  });

  test('离散周次被正确解析', () {
    final course = parser
        .parse(response([entry(zcd: '1-4周,6周')]), semesterId: 's1')
        .single;

    expect(course.weeks, [1, 2, 3, 4, 6]);
  });

  test('jcs 缺失时退回 jc 字段', () {
    final raw = entry();
    raw.remove('jcs');
    raw['jc'] = '5-6节';

    final course = parser.parse(response([raw]), semesterId: 's1').single;
    expect(course.startSection, 5);
    expect(course.endSection, 6);
  });

  test('缺少星期或周次的条目被跳过', () {
    final courses = parser.parse(
      response([
        entry(kcmc: '有效课程'),
        entry(kcmc: '缺星期', xqj: ''),
        entry(kcmc: '周次非法', zcd: '待定'),
      ]),
      semesterId: 's1',
    );

    expect(courses.map((c) => c.name), ['有效课程']);
  });

  test('结果按星期与起始节次排序', () {
    final courses = parser.parse(
      response([
        entry(kcmc: '周三', xqj: '3', jcs: '1-2'),
        entry(kcmc: '周一后两节', xqj: '1', jcs: '5-6'),
        entry(kcmc: '周一前两节', xqj: '1', jcs: '1-2'),
      ]),
      semesterId: 's1',
    );

    expect(courses.map((c) => c.name), ['周一前两节', '周一后两节', '周三']);
  });

  test('颜色键与手动建课使用同一规则', () {
    final course = parser
        .parse(response([entry(kcmc: '工程力学')]), semesterId: 's1')
        .single;

    expect(course.colorKey, courseColorKeyForName('工程力学'));
  });

  test('kbList 为空时抛出可读异常', () {
    expect(
      () => parser.parse(response([]), semesterId: 's1'),
      throwsA(
        isA<TimetableParseException>().having(
          (e) => e.message,
          'message',
          contains('尚未排课'),
        ),
      ),
    );
  });

  test('缺少 kbList 时抛出可读异常', () {
    expect(
      () => parser.parse('{"foo":1}', semesterId: 's1'),
      throwsA(isA<TimetableParseException>()),
    );
  });

  test('非 JSON 响应抛出可读异常', () {
    expect(
      () => parser.parse('<html>登录已失效</html>', semesterId: 's1'),
      throwsA(
        isA<TimetableParseException>().having(
          (e) => e.message,
          'message',
          contains('JSON'),
        ),
      ),
    );
  });
}
