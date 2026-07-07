import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appsort/app.dart';

void main() {
  testWidgets('AppSort 应用可以启动', (WidgetTester tester) async {
    // 初始化 SharedPreferences（测试环境需要）
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: AppSortApp(),
      ),
    );

    // 等待两帧让初始渲染完成
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 验证 AppSort 标题显示
    expect(find.text('AppSort'), findsOneWidget);

    // 验证底部导航栏有三个标签
    expect(find.text('智能分类'), findsOneWidget);
    expect(find.text('全部应用'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });
}
