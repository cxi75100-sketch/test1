import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/adapters/ncpu_adapter.dart';
import 'package:ncpu_timetable/features/import/adapters/school_adapter.dart';
import 'package:ncpu_timetable/models/school.dart';

void main() {
  const adapter = NcpuAdapter();

  group('NcpuAdapter — canHandle', () {
    test('学校 host 可以处理', () {
      expect(
        adapter.canHandle(Uri.parse('http://jwxt.ncpu.edu.cn:8088/jwglxt')),
        isTrue,
      );
    });

    test('学校 host 子域名可以处理（与配置规则一致）', () {
      expect(
        adapter.canHandle(Uri.parse('https://sub.jwxt.ncpu.edu.cn/')),
        isTrue,
      );
    });

    test('恶意域名不能处理', () {
      expect(
        adapter.canHandle(Uri.parse('https://jwxt.ncpu.edu.cn.evil.com/')),
        isFalse,
      );
    });

    test('受信任 host 搭配危险 scheme 也不能处理', () {
      expect(
        adapter.canHandle(Uri.parse('javascript://jwxt.ncpu.edu.cn/alert')),
        isFalse,
      );
    });

    test('外部域名不能处理', () {
      expect(adapter.canHandle(Uri.parse('https://www.baidu.com/')), isFalse);
    });
  });

  group('NcpuAdapter — parseTimetable', () {
    test('没有数据时不返回伪造课程', () {
      final result = adapter.parseTimetable('', semesterId: 's1');
      expect(result, isA<ImportInterfaceNotYetDiscovered>());
      expect(result, isNot(isA<ImportSuccess>()));
    });

    test('提示引导用户先打开课表查询页', () {
      final result = adapter.parseTimetable('   ', semesterId: 's1');
      final notDiscovered = result as ImportInterfaceNotYetDiscovered;
      expect(notDiscovered.hint, contains('学生课表查询'));
    });

    test('结构异常时返回 ImportError 而不是抛异常', () {
      final result = adapter.parseTimetable('{"foo":1}', semesterId: 's1');
      expect(result, isA<ImportError>());
    });

    test('合法响应解析为课程列表', () {
      final result = adapter.parseTimetable(
        '{"kbList":[{"kcmc":"工程力学","xqj":"1","jcs":"3-4","zcd":"1-16周",'
        '"cdmc":"明志楼223","xm":"张老师","xf":"4.0","jxb_id":"J1"}]}',
        semesterId: 's1',
      );
      final success = result as ImportSuccess;
      expect(success.courses, hasLength(1));
      expect(success.courses.single.name, '工程力学');
      expect(success.courses.single.semesterId, 's1');
    });
  });

  group('NcpuAdapter — 元数据', () {
    test('schoolName 来自 NcpuSchoolConfig', () {
      expect(adapter.schoolName, NcpuSchoolConfig.schoolName);
      expect(adapter.schoolName, '南昌工学院');
    });

    test('loginUrl 来自 NcpuSchoolConfig', () {
      expect(adapter.loginUrl, NcpuSchoolConfig.loginUrl);
      expect(adapter.loginUrl, contains('jwxt.ncpu.edu.cn'));
    });
  });
}
