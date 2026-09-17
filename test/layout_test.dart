import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mydesktop/main.dart';

void main() {
  testWidgets('no overflow at default panel size', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at minimum panel size', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(240, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow in edge-top height', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
