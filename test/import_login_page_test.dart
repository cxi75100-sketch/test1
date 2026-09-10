import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ncpu_timetable/features/import/pages/import_login_page.dart';

void main() {
  testWidgets('候选 HTTP 地址在用户确认前不会创建 WebView', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ImportLoginPage())),
    );

    expect(find.text('登录前请确认风险'), findsOneWidget);
    expect(find.text('候选地址：jwxt.ncpu.edu.cn:8088'), findsOneWidget);
    expect(find.textContaining('当前入口使用 HTTP，传输未加密'), findsOneWidget);
    expect(find.text('我已了解风险，继续打开'), findsOneWidget);
    expect(find.textContaining('学校官方页面'), findsNothing);
    expect(find.byType(InAppWebView), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    final refreshButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.refresh),
    );
    expect(refreshButton.onPressed, isNull);
  });
}
