import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydesktop/window/window_state.dart';

void main() {
  group('WindowState', () {
    test('defaults have expected values', () {
      final s = WindowState.defaults;
      expect(s.floatingSize, const Size(320, 560));
      expect(s.edgeTopHeight, 80);
      expect(s.edgeLeftWidth, 320);
      expect(s.edgeRightWidth, 320);
      expect(s.lastMode, WindowMode.floating);
      expect(s.lastEdge, isNull);
    });

    test('round-trips through json', () {
      final original = WindowState(
        floatingSize: const Size(400, 500),
        floatingPosition: const Offset(120, 80),
        edgeTopHeight: 96,
        edgeLeftWidth: 280,
        edgeRightWidth: 360,
        lastMode: WindowMode.edge,
        lastEdge: EdgeAnchor.right,
      );

      final restored = WindowState.fromJson(original.toJson());
      expect(restored.floatingSize, original.floatingSize);
      expect(restored.floatingPosition, original.floatingPosition);
      expect(restored.edgeTopHeight, original.edgeTopHeight);
      expect(restored.edgeLeftWidth, original.edgeLeftWidth);
      expect(restored.edgeRightWidth, original.edgeRightWidth);
      expect(restored.lastMode, WindowMode.edge);
      expect(restored.lastEdge, EdgeAnchor.right);
    });

    test('migrates v1 json with separate left/right widths', () {
      final restored = WindowState.fromJson({
        'fw': 300,
        'fh': 400,
        'th': 72,
        'lw': 250,
        'rw': 350,
      });

      expect(restored.floatingSize, const Size(300, 400));
      expect(restored.edgeTopHeight, 72);
      expect(restored.edgeLeftWidth, 250);
      expect(restored.edgeRightWidth, 350);
    });

    test('migrates shared edgeSideWidth field', () {
      final restored = WindowState.fromJson({
        'fw': 320,
        'fh': 560,
        'sw': 300,
      });

      expect(restored.edgeLeftWidth, 300);
      expect(restored.edgeRightWidth, 300);
    });

    test('saveEdgeWidth updates correct field', () {
      final s = WindowState.defaults;
      s.saveEdgeWidth(EdgeAnchor.top, 100);
      s.saveEdgeWidth(EdgeAnchor.left, 200);
      s.saveEdgeWidth(EdgeAnchor.right, 240);

      expect(s.edgeTopHeight, 100);
      expect(s.edgeLeftWidth, 200);
      expect(s.edgeRightWidth, 240);
    });
  });
}
