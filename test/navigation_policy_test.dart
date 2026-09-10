import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/services/navigation_policy.dart';
import 'package:ncpu_timetable/models/school.dart';

void main() {
  const policy = NavigationPolicy();

  group('NavigationPolicy — 受信任域名', () {
    test('精确匹配 jwxt.ncpu.edu.cn 允许', () {
      final eval = policy.evaluate(Uri.parse('http://jwxt.ncpu.edu.cn:8088/jwglxt'));
      expect(eval.isAllowed, isTrue);
      expect(eval.reason, NavigationReason.trustedHost);
    });

    test('HTTPS 同域名允许', () {
      final eval = policy.evaluate(Uri.parse('https://jwxt.ncpu.edu.cn/'));
      expect(eval.isAllowed, isTrue);
    });

    test('受信任域名的子域名允许（与配置规则一致）', () {
      final eval = policy.evaluate(Uri.parse('https://auth.jwxt.ncpu.edu.cn/login'));
      expect(eval.isAllowed, isTrue);
      expect(eval.reason, NavigationReason.trustedHost);
    });
  });

  group('NavigationPolicy — 恶意域名拒绝', () {
    test('后缀伪造 jwxt.ncpu.edu.cn.evil.com 不能处理', () {
      final eval = policy.evaluate(Uri.parse('https://jwxt.ncpu.edu.cn.evil.com/'));
      expect(eval.isAllowed, isFalse);
      expect(eval.reason, NavigationReason.unknownHost);
    });

    test('前缀伪造 njwxt.ncpu.edu.cn 不能处理', () {
      // njwxt.ncpu.edu.cn 不是 jwxt.ncpu.edu.cn 的子域名
      // 但 endsWith('.jwxt.ncpu.edu.cn') 不匹配 → 拒绝
      final eval = policy.evaluate(Uri.parse('https://njwxt.ncpu.edu.cn/'));
      expect(eval.isAllowed, isFalse);
    });

    test('相似域名 jwxt-ncpu.edu.cn 不能处理', () {
      final eval = policy.evaluate(Uri.parse('https://jwxt-ncpu.edu.cn/'));
      expect(eval.isAllowed, isFalse);
    });

    test('完全不同的域名 baidu.com 不能处理', () {
      final eval = policy.evaluate(Uri.parse('https://www.baidu.com/'));
      expect(eval.isAllowed, isFalse);
      expect(eval.reason, NavigationReason.unknownHost);
    });
  });

  group('NavigationPolicy — scheme 拒绝', () {
    test('javascript: scheme 被拒绝', () {
      final eval = policy.evaluate(Uri.parse('javascript:alert(1)'));
      expect(eval.isAllowed, isFalse);
      expect(eval.reason, NavigationReason.disallowedScheme);
    });

    test('data: scheme 被拒绝', () {
      final eval = policy.evaluate(Uri.parse('data:text/html,<h1>hi</h1>'));
      expect(eval.isAllowed, isFalse);
      expect(eval.reason, NavigationReason.disallowedScheme);
    });

    test('file: scheme 被拒绝', () {
      final eval = policy.evaluate(Uri.parse('file:///etc/passwd'));
      expect(eval.isAllowed, isFalse);
      expect(eval.reason, NavigationReason.disallowedScheme);
    });

    test('ftp: scheme 被拒绝', () {
      final eval = policy.evaluate(Uri.parse('ftp://jwxt.ncpu.edu.cn/'));
      expect(eval.isAllowed, isFalse);
      expect(eval.reason, NavigationReason.disallowedScheme);
    });
  });

  group('NavigationPolicy — 脱敏', () {
    test('redactedHost 只返回 host', () {
      final host = policy.redactedHost(Uri.parse('https://evil.com/secret/path?q=1'));
      expect(host, 'evil.com');
    });

    test('redactedHost 包含端口', () {
      final host = policy.redactedHost(Uri.parse('http://jwxt.ncpu.edu.cn:8088/jwglxt'));
      expect(host, 'jwxt.ncpu.edu.cn:8088');
    });
  });

  group('NcpuSchoolConfig — 域名规则', () {
    test('acceptedHosts 不包含通配或空字符串', () {
      for (final host in NcpuSchoolConfig.acceptedHosts) {
        expect(host.isNotEmpty, isTrue);
        expect(host, isNot(startsWith('.')));
      }
    });

    test('allowedSchemes 仅含 http 和 https', () {
      expect(NcpuSchoolConfig.allowedSchemes, {'http', 'https'});
    });
  });
}
