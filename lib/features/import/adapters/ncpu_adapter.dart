import '../../../models/school.dart';
import '../parsers/ncpu_timetable_parser.dart';
import 'school_adapter.dart';

/// 南昌工学院适配器（正方教务系统）。
///
/// 课表数据来自受限 WebView 在教务会话内取到的
/// `/jwglxt/kbcx/xskbcx_cxXsgrkb.html` 响应；接口形状经真机脱敏采集确认，
/// 详见 `knowledge/ncpu_import.md`。适配器不接触 Cookie、Session 或 Token。
class NcpuAdapter extends SchoolAdapter {
  const NcpuAdapter();

  static const NcpuTimetableParser _parser = NcpuTimetableParser();

  @override
  String get schoolName => NcpuSchoolConfig.schoolName;

  @override
  String get loginUrl => NcpuSchoolConfig.loginUrl;

  @override
  bool canHandle(Uri uri) => NcpuSchoolConfig.accepts(uri);

  @override
  ImportResult parseTimetable(
    String rawResponse, {
    required String semesterId,
  }) {
    if (rawResponse.trim().isEmpty) {
      return const ImportInterfaceNotYetDiscovered(
        '还没有取到课表数据。\n\n'
        '请先在教务页面打开「信息查询 → 学生课表查询」，等课表显示出来后再点导入。',
      );
    }
    try {
      return ImportSuccess(
        _parser.parse(rawResponse, semesterId: semesterId),
      );
    } on TimetableParseException catch (error) {
      return ImportError(error.message);
    }
  }
}
