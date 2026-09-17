import 'dart:ui';

/// 窗口模式：浮动 / 边缘吸附
enum WindowMode { floating, edge }

/// 边缘吸附方向（仅 edge 模式有效）
enum EdgeAnchor { top, left, right }

/// 持久化的窗口状态
class WindowState {
  Size floatingSize;
  Offset? floatingPosition;

  double edgeTopHeight;
  double edgeLeftWidth;
  double edgeRightWidth;

  WindowMode lastMode;
  EdgeAnchor? lastEdge;

  WindowState({
    required this.floatingSize,
    this.floatingPosition,
    required this.edgeTopHeight,
    required this.edgeLeftWidth,
    required this.edgeRightWidth,
    this.lastMode = WindowMode.floating,
    this.lastEdge,
  });

  static WindowState get defaults => WindowState(
        floatingSize: const Size(320, 560),
        edgeTopHeight: 80,
        edgeLeftWidth: 320,
        edgeRightWidth: 320,
      );

  Map<String, dynamic> toJson() => {
        'fw': floatingSize.width,
        'fh': floatingSize.height,
        'fx': floatingPosition?.dx,
        'fy': floatingPosition?.dy,
        'th': edgeTopHeight,
        'lw': edgeLeftWidth,
        'rw': edgeRightWidth,
        'mode': lastMode.name,
        'edge': lastEdge?.name,
      };

  factory WindowState.fromJson(Map<String, dynamic> json) {
    Offset? pos;
    final fx = json['fx'];
    final fy = json['fy'];
    if (fx != null && fy != null) {
      pos = Offset((fx as num).toDouble(), (fy as num).toDouble());
    }

    var mode = WindowMode.floating;
    if (json['mode'] == WindowMode.edge.name) mode = WindowMode.edge;

    EdgeAnchor? edge;
    final edgeStr = json['edge'] as String?;
    if (edgeStr != null) {
      for (final e in EdgeAnchor.values) {
        if (e.name == edgeStr) {
          edge = e;
          break;
        }
      }
    }

    final sharedWidth = (json['sw'] as num?)?.toDouble();
    final leftWidth = (json['lw'] as num?)?.toDouble() ?? sharedWidth ?? 320;
    final rightWidth = (json['rw'] as num?)?.toDouble() ?? sharedWidth ?? 320;

    return WindowState(
      floatingSize: Size(
        (json['fw'] as num?)?.toDouble() ?? 320,
        (json['fh'] as num?)?.toDouble() ?? 560,
      ),
      floatingPosition: pos,
      edgeTopHeight: (json['th'] as num?)?.toDouble() ?? 80,
      edgeLeftWidth: leftWidth,
      edgeRightWidth: rightWidth,
      lastMode: mode,
      lastEdge: edge,
    );
  }

  String get summaryText {
    final f = floatingSize;
    final pos = floatingPosition;
    final posStr = pos != null
        ? ' @(${pos.dx.toStringAsFixed(0)},${pos.dy.toStringAsFixed(0)})'
        : '';
    return '浮动 ${f.width.toStringAsFixed(0)}×${f.height.toStringAsFixed(0)}$posStr'
        ' · 吸顶 h=${edgeTopHeight.toStringAsFixed(0)}'
        ' · 吸左 w=${edgeLeftWidth.toStringAsFixed(0)}'
        ' · 吸右 w=${edgeRightWidth.toStringAsFixed(0)}';
  }

  void saveEdgeWidth(EdgeAnchor anchor, double value) {
    switch (anchor) {
      case EdgeAnchor.top:
        edgeTopHeight = value;
      case EdgeAnchor.left:
        edgeLeftWidth = value;
      case EdgeAnchor.right:
        edgeRightWidth = value;
    }
  }
}

const String kWindowStatePrefKey = 'mydesktop_window_state_v2';
const String kWindowStatePrefKeyV1 = 'mydesktop_window_state_v1';
