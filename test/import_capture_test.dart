import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncpu_timetable/features/import/services/import_capture.dart';

void main() {
  const sanitizer = ImportCaptureSanitizer();

  group('sanitize', () {
    test('保留路径与非敏感参数，脱敏敏感键与超长值', () {
      final entry = sanitizer.sanitize(
        method: 'post',
        url:
            'http://jwxt.ncpu.edu.cn:8088/jwglxt/kbcx/xskbcx_cxXsKb.html'
            '?gnmkdm=N2151&su=MTIzNDU2Nzg5MA%3D%3D&xnm=2026&t=1757488800000'
            '&sig=${'a' * 40}',
      );

      expect(entry.method, 'POST');
      expect(entry.path, '/jwglxt/kbcx/xskbcx_cxXsKb.html');
      expect(entry.query['gnmkdm'], 'N2151');
      expect(entry.query['xnm'], '2026');
      expect(entry.query['t'], '1757488800000');
      expect(entry.query['su'], maskedValue);
      expect(entry.query['sig'], '$maskedValue(len=40)');
    });

    test('表单请求体按字段脱敏', () {
      final entry = sanitizer.sanitize(
        method: 'POST',
        url: 'http://jwxt.ncpu.edu.cn:8088/jwglxt/kbcx/xskbcx_cxXsKb.html',
        requestBody: 'yhm=20230101001&mm=secret&xnm=2026&xqm=3',
      );

      expect(
        entry.requestBody,
        'yhm=$maskedValue&mm=$maskedValue&xnm=2026&xqm=3',
      );
    });

    test('JSON 响应只保留字段结构与样例，学号姓名被掩码', () {
      final entry = sanitizer.sanitize(
        method: 'POST',
        url: 'http://jwxt.ncpu.edu.cn:8088/jwglxt/kbcx/xskbcx_cxXsKb.html',
        status: 200,
        contentType: 'application/json;charset=UTF-8',
        responseBody: jsonEncode({
          'kbList': [
            {
              'kcmc': '高等数学A',
              'xqj': '1',
              'jcs': '1-2',
              'zcd': '1-16周',
              'cdmc': '一号教学楼A101',
              'xh': '20230101001',
              'xm': '张三',
            },
          ],
          'xsxx': {'xh': '20230101001', 'xm': '张三'},
        }),
      );

      final shape = entry.responseShape!;
      expect(shape, contains('kbList: array[1] of object'));
      expect(shape, contains('kcmc: "高等数学A"'));
      expect(shape, contains('zcd: "1-16周"'));
      expect(shape, contains('cdmc: "一号教学楼A101"'));
      expect(shape, contains(maskedValue));
      expect(shape, isNot(contains('20230101001')));
      expect(shape, isNot(contains('张三')));
    });

    test('非敏感键下的纯数字长串同样被掩码', () {
      final entry = sanitizer.sanitize(
        method: 'POST',
        url: 'http://jwxt.ncpu.edu.cn:8088/jwglxt/x',
        responseBody: jsonEncode({'someId': '20230101001'}),
      );

      expect(entry.responseShape, isNot(contains('20230101001')));
    });

    test('对象数组输出每条摘要，便于核对返回条数与解析条数', () {
      final entry = sanitizer.sanitize(
        method: 'POST',
        url: 'http://jwxt.ncpu.edu.cn:8088/jwglxt/kbcx/xskbcx_cxXsgrkb.html',
        responseBody: jsonEncode({
          'kbList': [
            {
              'kcmc': '工程力学',
              'xqj': '1',
              'jcs': '3-4',
              'zcd': '1-16周',
              'cdmc': '明志楼223',
            },
            {
              'kcmc': '大学英语Ⅲ',
              'xqj': '2',
              'jcs': '1-2',
              'zcd': '1-16周',
              'cdmc': '敏行楼B505-1',
            },
          ],
        }),
      );

      final shape = entry.responseShape!;
      expect(shape, contains('array[2] of object'));
      expect(shape, contains('[1] kcmc="工程力学"'));
      expect(shape, contains('[2] kcmc="大学英语Ⅲ"'));
    });

    test('非 JSON 响应截断并掩码长 token 与长数字', () {
      final entry = sanitizer.sanitize(
        method: 'GET',
        url: 'http://jwxt.ncpu.edu.cn:8088/jwglxt/',
        responseBody:
            '<html><body>token abcdefghijklmnopqrstuvwxyz0123456789 '
            'and 20230101001</body></html>',
      );

      final shape = entry.responseShape!;
      expect(shape, isNot(contains('abcdefghijklmnopqrstuvwxyz0123456789')));
      expect(shape, isNot(contains('20230101001')));
      expect(shape, contains(maskedValue));
    });

    test('空响应体不产生结构', () {
      final entry = sanitizer.sanitize(
        method: 'GET',
        url: 'http://jwxt.ncpu.edu.cn:8088/jwglxt/',
        responseBody: '   ',
      );

      expect(entry.responseShape, isNull);
      expect(entry.requestBody, isNull);
    });

    test('畸形 URL 不抛异常', () {
      // Uri 会把非 ASCII 路径百分号编码；真实教务 URL 路径均为 ASCII。
      final entry = sanitizer.sanitize(method: 'GET', url: '不是 URL');

      expect(entry.path, isNotEmpty);
      expect(entry.query, isEmpty);
    });
  });

  test('报告包含路径与字段名，且不含敏感原文', () {
    final report = buildImportCaptureReport([
      sanitizer.sanitize(
        method: 'POST',
        url:
            'http://jwxt.ncpu.edu.cn:8088/jwglxt/kbcx/xskbcx_cxXsKb.html'
            '?gnmkdm=N2151&su=MTIzNDU2Nzg5MA%3D%3D',
        requestBody: 'xnm=2026',
        status: 200,
        contentType: 'application/json',
        responseBody: jsonEncode({
          'kbList': [
            {'kcmc': '高等数学A', 'xh': '20230101001', 'xm': '张三'},
          ],
        }),
      ),
    ]);

    expect(report, contains('/jwglxt/kbcx/xskbcx_cxXsKb.html'));
    expect(report, contains('gnmkdm=N2151'));
    expect(report, contains('kcmc'));
    expect(report, isNot(contains('20230101001')));
    expect(report, isNot(contains('MTIzNDU2Nzg5MA')));
    expect(report, isNot(contains('张三')));
  });
}
