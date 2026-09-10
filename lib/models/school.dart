/// 南昌工学院适配器配置。
///
/// 所有字段均为 `UNVERIFIED`——候选入口 `http://jwxt.ncpu.edu.cn:8088/jwglxt`
/// 尚未由用户在真机 WebView 中登录确认。在真机验证前，不得据此断言真实接口。
class NcpuSchoolConfig {
  const NcpuSchoolConfig._();

  /// 学校显示名称。
  static const schoolName = '南昌工学院';

  /// 候选登录入口（UNVERIFIED）。
  static const loginUrl = 'http://jwxt.ncpu.edu.cn:8088/jwglxt';

  /// 受信任域名白名单。仅精确匹配或子域名；不会匹配
  /// `jwxt.ncpu.edu.cn.evil.com` 等后缀伪造域名。
  ///
  /// 如遇经真机验证的统一认证跳转域名，须在此处显式追加，
  /// 不得提前加入未经验证的域名。
  static const acceptedHosts = <String>{'jwxt.ncpu.edu.cn'};

  /// 允许的 URI scheme。仅 http / https；拒绝 javascript / data / file / ftp 等。
  static const allowedSchemes = <String>{'http', 'https'};

  /// 判断 [uri] 的 scheme 与域名是否同时属于允许列表。
  static bool accepts(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    return allowedSchemes.contains(scheme) &&
        acceptedHosts.any(
          (acceptedHost) =>
              host == acceptedHost || host.endsWith('.$acceptedHost'),
        );
  }
}
