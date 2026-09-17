import 'package:flutter/material.dart';
import 'package:mydesktop/window/window_state.dart';

/// 向面板内容区暴露窗口状态与控制接口
class WindowScope extends InheritedWidget {
  const WindowScope({
    super.key,
    required this.mode,
    required this.edge,
    required this.state,
    required this.stateLoaded,
    required this.enterFloating,
    required this.enterEdge,
    required super.child,
  });

  final WindowMode mode;
  final EdgeAnchor? edge;
  final WindowState state;
  final bool stateLoaded;
  final Future<void> Function() enterFloating;
  final Future<void> Function(EdgeAnchor anchor) enterEdge;

  bool get isEdgeMode => mode == WindowMode.edge;

  static WindowScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WindowScope>();
    assert(scope != null, 'WindowScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(WindowScope oldWidget) {
    return mode != oldWidget.mode ||
        edge != oldWidget.edge ||
        stateLoaded != oldWidget.stateLoaded ||
        state.floatingSize != oldWidget.state.floatingSize ||
        state.floatingPosition != oldWidget.state.floatingPosition ||
        state.edgeTopHeight != oldWidget.state.edgeTopHeight ||
        state.edgeLeftWidth != oldWidget.state.edgeLeftWidth ||
        state.edgeRightWidth != oldWidget.state.edgeRightWidth;
  }
}
