import 'package:flutter_test/flutter_test.dart';
import 'package:hello_china/main.dart';

void main() {
  testWidgets('App 启动测试', (WidgetTester tester) async {
    await tester.pumpWidget(const XinmeiApp());
    expect(find.text('信美分期'), findsOneWidget);
  });
}
