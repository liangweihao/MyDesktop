import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mydesktop/panel/panel_shell.dart';
import 'package:mydesktop/window/window_scope.dart';
import 'package:mydesktop/window/window_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class PanelWindow extends StatefulWidget {
  const PanelWindow({super.key});

  @override
  State<PanelWindow> createState() => _PanelWindowState();
}

class _PanelWindowState extends State<PanelWindow> with WindowListener {
  WindowState _state = WindowState.defaults;
  bool _stateLoaded = false;

  WindowMode _mode = WindowMode.floating;
  EdgeAnchor? _edge;

  bool _isProgrammaticChange = false;
  Timer? _dragEndDebounce;

  static const _snapThreshold = 20.0;
  static const _dragEndDelay = Duration(milliseconds: 300);

  bool get _isEdgeMode => _mode == WindowMode.edge;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadState();
  }

  @override
  void dispose() {
    _dragEndDebounce?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(kWindowStatePrefKey) ??
        prefs.getString(kWindowStatePrefKeyV1);
    if (str != null) {
      try {
        _state = WindowState.fromJson(jsonDecode(str) as Map<String, dynamic>);
      } catch (_) {
        _state = WindowState.defaults;
      }
    }
    _stateLoaded = true;
    if (mounted) setState(() {});

    if (_state.lastMode == WindowMode.edge && _state.lastEdge != null) {
      await _enterEdge(_state.lastEdge!, persistMode: false);
    } else {
      await _enterFloating(persistMode: false);
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kWindowStatePrefKey, jsonEncode(_state.toJson()));
  }

  Size? _getPrimaryScreenSize() {
    final displays = WidgetsBinding.instance.platformDispatcher.displays;
    if (displays.isEmpty) return null;
    final d = displays.first;
    final dpr = d.devicePixelRatio == 0 ? 1.0 : d.devicePixelRatio;
    return Size(d.size.width / dpr, d.size.height / dpr);
  }

  Size _edgeSize(EdgeAnchor anchor, Size screen) {
    switch (anchor) {
      case EdgeAnchor.top:
        return Size(screen.width, _state.edgeTopHeight);
      case EdgeAnchor.left:
        return Size(_state.edgeLeftWidth, screen.height);
      case EdgeAnchor.right:
        return Size(_state.edgeRightWidth, screen.height);
    }
  }

  Offset _edgePosition(EdgeAnchor anchor, Size size, Size screen) {
    switch (anchor) {
      case EdgeAnchor.top:
      case EdgeAnchor.left:
        return Offset.zero;
      case EdgeAnchor.right:
        return Offset(screen.width - size.width, 0);
    }
  }

  List<ResizeEdge>? _resizeEdges() {
    if (!_isEdgeMode || _edge == null) return null;
    switch (_edge!) {
      case EdgeAnchor.top:
        return const [
          ResizeEdge.bottom,
          ResizeEdge.bottomLeft,
          ResizeEdge.bottomRight,
        ];
      case EdgeAnchor.left:
        return const [
          ResizeEdge.right,
          ResizeEdge.topRight,
          ResizeEdge.bottomRight,
        ];
      case EdgeAnchor.right:
        return const [
          ResizeEdge.left,
          ResizeEdge.topLeft,
          ResizeEdge.bottomLeft,
        ];
    }
  }

  Future<void> _applyWindowGeometry(Size size, Offset? position) async {
    _isProgrammaticChange = true;
    await windowManager.setSize(size);
    if (position != null) {
      await windowManager.setPosition(position);
    }
    _dragEndDebounce?.cancel();
    _isProgrammaticChange = false;
  }

  Future<void> _enterFloating({bool persistMode = true}) async {
    if (persistMode) {
      _state.lastMode = WindowMode.floating;
      _state.lastEdge = null;
      await _saveState();
    }

    await _applyWindowGeometry(_state.floatingSize, _state.floatingPosition);

    if (mounted) {
      setState(() {
        _mode = WindowMode.floating;
        _edge = null;
      });
    }
  }

  Future<void> _enterEdge(EdgeAnchor anchor, {bool persistMode = true}) async {
    final screen = _getPrimaryScreenSize();
    if (screen == null) return;

    if (persistMode) {
      _state.lastMode = WindowMode.edge;
      _state.lastEdge = anchor;
      await _saveState();
    }

    final size = _edgeSize(anchor, screen);
    final pos = _edgePosition(anchor, size, screen);
    await _applyWindowGeometry(size, pos);

    if (mounted) {
      setState(() {
        _mode = WindowMode.edge;
        _edge = anchor;
      });
    }
  }

  Future<void> _saveCurrentGeometry(Size size, {Offset? position}) async {
    if (_mode == WindowMode.floating) {
      _state.floatingSize = size;
      if (position != null) _state.floatingPosition = position;
    } else if (_edge != null) {
      switch (_edge!) {
        case EdgeAnchor.top:
          _state.edgeTopHeight = size.height;
        case EdgeAnchor.left:
          _state.edgeLeftWidth = size.width;
        case EdgeAnchor.right:
          _state.edgeRightWidth = size.width;
      }
    }
    await _saveState();
  }

  @override
  void onWindowMove() {
    _dragEndDebounce?.cancel();
    if (_isEdgeMode && !_isProgrammaticChange) {
      _enterFloating();
    }
  }

  @override
  void onWindowMoved() {
    if (_isProgrammaticChange) return;
    _dragEndDebounce?.cancel();
    _dragEndDebounce = Timer(_dragEndDelay, _onDragEnd);
  }

  Future<void> _onDragEnd() async {
    if (_isProgrammaticChange || _isEdgeMode || !_stateLoaded) return;

    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();
    final screen = _getPrimaryScreenSize();
    if (screen == null) return;

    EdgeAnchor? target;
    if (pos.dy.abs() <= _snapThreshold) {
      target = EdgeAnchor.top;
    } else if ((screen.width - (pos.dx + size.width)).abs() <= _snapThreshold) {
      target = EdgeAnchor.right;
    } else if (pos.dx.abs() <= _snapThreshold) {
      target = EdgeAnchor.left;
    }

    if (target != null) {
      await _enterEdge(target);
    } else {
      await _saveCurrentGeometry(size, position: pos);
      if (mounted) setState(() {});
    }
  }

  @override
  Future<void> onWindowResized() async {
    if (_isProgrammaticChange || !_stateLoaded) return;
    final size = await windowManager.getSize();
    await _saveCurrentGeometry(size);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            GestureDetector(
              onDoubleTap: () {
                if (_isEdgeMode) _enterFloating();
              },
              child: DragToMoveArea(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _stateLoaded
                              ? 'MyDesktop · $_modeLabel'
                              : 'MyDesktop',
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () async => windowManager.close(),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.close,
                              size: 16, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: WindowScope(
                mode: _mode,
                edge: _edge,
                state: _state,
                stateLoaded: _stateLoaded,
                enterFloating: _enterFloating,
                enterEdge: _enterEdge,
                child: const PanelShell(),
              ),
            ),
          ],
        ),
      ),
    );

    // DragToResizeArea 的 Stack 子组件需撑满
    return DragToResizeArea(
      enableResizeEdges: _resizeEdges(),
      child: SizedBox.expand(child: content),
    );
  }

  String get _modeLabel {
    if (_mode == WindowMode.floating) return '浮动';
    switch (_edge) {
      case EdgeAnchor.top:
        return '边缘·顶';
      case EdgeAnchor.left:
        return '边缘·左';
      case EdgeAnchor.right:
        return '边缘·右';
      case null:
        return '边缘';
    }
  }
}
