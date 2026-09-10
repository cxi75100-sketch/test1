/// 学校适配器抽象层。
///
/// 每所学校一个 [SchoolAdapter] 实现；学校原始字段不得泄漏到
/// UI 或通用 [Course] 模型之外的模块。
library;

import '../../../models/course.dart';

/// 导入结果。
///
/// 只有 [ImportSuccess] 携带真实课程列表；[ImportInterfaceNotYetDiscovered]
/// 表示尚未取得可解析的课表数据（例如用户还没打开课表页），不得伪造数据。
sealed class ImportResult {
  const ImportResult();
}

/// 导入成功，携带解析后的通用课程列表。
class ImportSuccess extends ImportResult {
  const ImportSuccess(this.courses);
  final List<Course> courses;
}

/// 尚未取得可解析的课表数据。
///
/// [hint] 用于向用户展示脱敏提示（例如"请先在官方页面打开课表查询"）。
class ImportInterfaceNotYetDiscovered extends ImportResult {
  const ImportInterfaceNotYetDiscovered(this.hint);
  final String hint;
}

/// 导入过程中出现错误。
class ImportError extends ImportResult {
  const ImportError(this.message);
  final String message;
}

/// 学校适配器接口。
///
/// - [schoolName] 用于 UI 展示。
/// - [canHandle] 判断给定 URI 是否属于该学校的受信任域名。
/// - [parseTimetable] 把教务系统返回的课表数据解析成通用课程列表。
///
/// 真实数据由受限 WebView 在教务会话内取得后传入；适配器**不接收也不接触**
/// Cookie、Session 或 Token。
abstract class SchoolAdapter {
  const SchoolAdapter();

  /// 学校显示名称。
  String get schoolName;

  /// 登录入口 URL，供 WebView 加载。
  String get loginUrl;

  /// 判断 [uri] 是否属于当前学校适配器的受信任域名。
  bool canHandle(Uri uri);

  /// 解析课表数据。
  ///
  /// [rawResponse] 为空串表示尚未取到数据，实现必须返回
  /// [ImportInterfaceNotYetDiscovered]，不得伪造课程。
  ImportResult parseTimetable(String rawResponse, {required String semesterId});
}
