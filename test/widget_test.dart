import 'package:flutter_test/flutter_test.dart';

import 'package:mydesktop/main.dart';

void main() {
  testWidgets('App shows panel home', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('便签'), findsOneWidget);
    expect(find.text('选择下方工具开始使用'), findsOneWidget);
    expect(find.textContaining('MyDesktop'), findsOneWidget);
  });
}
