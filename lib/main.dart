import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

const String _kPrefKey = 'mydesktop_window_state_v1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(320, 560),
    minimumSize: Size(240, 80),
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Color(0x00000000),
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDesktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PanelWindow(),
    );
  }
}

/// 窗口吸附模式
enum SnapMode { floating, top, right, left }

/// 持久化的窗口状态
/// - floatingSize: 浮动状态下的窗口大小
/// - topSnapHeight: 吸顶时的高度(宽度固定为屏宽)
/// - rightSnapWidth: 吸右时的宽度(高度固定为屏高)
/// - leftSnapWidth: 吸左时的宽度(高度固定为屏高)
class WindowState {
  Size floatingSize;
  double? topSnapHeight;
  double? rightSnapWidth;
  double? leftSnapWidth;

  WindowState({
    required this.floatingSize,
    this.topSnapHeight,
    this.rightSnapWidth,
    this.leftSnapWidth,
  });

  static WindowState get defaults => WindowState(
        floatingSize: const Size(320, 560),
        topSnapHeight: 80,
        rightSnapWidth: 320,
        leftSnapWidth: 320,
      );

  Map<String, dynamic> toJson() => {
        'fw': floatingSize.width,
        'fh': floatingSize.height,
        'th': topSnapHeight,
        'rw': rightSnapWidth,
        'lw': leftSnapWidth,
      };

  factory WindowState.fromJson(Map<String, dynamic> json) {
    double? d(Object? v) => v == null ? null : (v as num).toDouble();
    return WindowState(
      floatingSize: Size(
        (json['fw'] as num?)?.toDouble() ?? 320,
        (json['fh'] as num?)?.toDouble() ?? 560,
      ),
      topSnapHeight: d(json['th']),
      rightSnapWidth: d(json['rw']),
      leftSnapWidth: d(json['lw']),
    );
  }
}

class PanelWindow extends StatefulWidget {
  const PanelWindow({super.key});

  @override
  State<PanelWindow> createState() => _PanelWindowState();
}

class _PanelWindowState extends State<PanelWindow> with WindowListener {
  /// 持久化状态
  late WindowState _state;
  bool _stateLoaded = false;

  /// 运行时状态
  SnapMode _snapMode = SnapMode.floating;
  bool _isSnapped = false;

  /// 程序调用 setSize/setPosition 时设为 true,以抑制 onWindowResized /
  /// onWindowMoved 引发的副作用
  bool _isProgrammaticChange = false;

  /// 拖拽结束检测防抖
  Timer? _dragEndDebounce;

  /// 进入吸附区域的阈值(逻辑像素)
  static const _snapThreshold = 20.0;

  /// 拖拽结束后判定延时(无 onWindowMoved 持续该时长即视为松手)
  static const _dragEndDelay = Duration(milliseconds: 300);

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

  // ===== 持久化 =====

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kPrefKey);
    if (str != null) {
      try {
        _state = WindowState.fromJson(jsonDecode(str) as Map<String, dynamic>);
      } catch (_) {
        _state = WindowState.defaults;
      }
    } else {
      _state = WindowState.defaults;
    }
    _stateLoaded = true;
    if (mounted) setState(() {});

    // 应用加载到的浮动尺寸
    _isProgrammaticChange = true;
    await windowManager.setSize(_state.floatingSize);
    _isProgrammaticChange = false;
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, jsonEncode(_state.toJson()));
  }

  // ===== 屏幕 =====

  /// 取主屏的逻辑尺寸(物理尺寸 / DPR)
  Size? _getPrimaryScreenSize() {
    final displays = WidgetsBinding.instance.platformDispatcher.displays;
    if (displays.isEmpty) return null;
    final d = displays.first;
    final dpr = d.devicePixelRatio == 0 ? 1.0 : d.devicePixelRatio;
    return Size(d.size.width / dpr, d.size.height / dpr);
  }

  // ===== 吸附 / 解除 =====

  Size _computeSnapSize(SnapMode mode, Size screen) {
    switch (mode) {
      case SnapMode.top:
        return Size(screen.width, _state.topSnapHeight ?? 80);
      case SnapMode.right:
        return Size(_state.rightSnapWidth ?? 320, screen.height);
      case SnapMode.left:
        return Size(_state.leftSnapWidth ?? 320, screen.height);
      case SnapMode.floating:
        return _state.floatingSize;
    }
  }

  Offset _computeSnapPos(SnapMode mode, Size snapSize, Size screen) {
    switch (mode) {
      case SnapMode.top:
      case SnapMode.left:
        return Offset.zero;
      case SnapMode.right:
        return Offset(screen.width - snapSize.width, 0);
      case SnapMode.floating:
        return Offset.zero;
    }
  }

  Future<void> _snapTo(SnapMode mode) async {
    final screen = _getPrimaryScreenSize();
    if (screen == null) return;

    final snapSize = _computeSnapSize(mode, screen);
    final snapPos = _computeSnapPos(mode, snapSize, screen);

    _isProgrammaticChange = true;
    await windowManager.setSize(snapSize);
    await windowManager.setPosition(snapPos);
    _dragEndDebounce?.cancel();
    _isProgrammaticChange = false;

    setState(() {
      _snapMode = mode;
      _isSnapped = true;
    });
  }

  Future<void> _unsnap() async {
    _isProgrammaticChange = true;
    await windowManager.setSize(_state.floatingSize);
    _dragEndDebounce?.cancel();
    _isProgrammaticChange = false;

    setState(() {
      _snapMode = SnapMode.floating;
      _isSnapped = false;
    });
  }

  // ===== 事件回调 =====

  /// windowWillMove:用户开始拖拽(仅触发一次)
  /// 已吸附的窗口被拖动 → 立即恢复浮动尺寸(setSize 默认保持顶部固定)
  @override
  void onWindowMove() {
    _dragEndDebounce?.cancel();
    if (_isSnapped && !_isProgrammaticChange) {
      _unsnap();
    }
  }

  /// windowDidMove:拖拽中(高频)
  @override
  void onWindowMoved() {
    if (_isProgrammaticChange) return;
    _dragEndDebounce?.cancel();
    _dragEndDebounce = Timer(_dragEndDelay, _onDragEnd);
  }

  /// 拖拽结束(防抖):若靠近屏幕边缘则吸附
  Future<void> _onDragEnd() async {
    if (_isProgrammaticChange || _isSnapped) return;

    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();
    final screen = _getPrimaryScreenSize();
    if (screen == null) return;

    SnapMode? target;
    if (pos.dy.abs() <= _snapThreshold) {
      target = SnapMode.top;
    } else if ((screen.width - (pos.dx + size.width)).abs() <=
        _snapThreshold) {
      target = SnapMode.right;
    } else if (pos.dx.abs() <= _snapThreshold) {
      target = SnapMode.left;
    }

    if (target != null) {
      await _snapTo(target);
    }
  }

  /// windowDidEndLiveResize:用户调整窗口大小结束(仅用户操作,程序调用不触发)
  /// 根据当前模式保存对应尺寸:
  ///   - 浮动:保存完整 size
  ///   - 吸顶:只保存 height(width 恒为屏宽)
  ///   - 吸右/吸左:只保存 width(height 恒为屏高)
  @override
  Future<void> onWindowResized() async {
    if (_isProgrammaticChange) return;
    final size = await windowManager.getSize();

    if (_isSnapped) {
      switch (_snapMode) {
        case SnapMode.top:
          _state.topSnapHeight = size.height;
          break;
        case SnapMode.right:
          _state.rightSnapWidth = size.width;
          break;
        case SnapMode.left:
          _state.leftSnapWidth = size.width;
          break;
        case SnapMode.floating:
          _state.floatingSize = size;
          break;
      }
    } else {
      _state.floatingSize = size;
    }

    await _saveState();
    if (mounted) setState(() {});
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            // ===== 自定义标题栏(可拖拽)=====
            GestureDetector(
              onDoubleTap: () {
                if (_isSnapped) _unsnap();
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
                              ? 'MyDesktop · $_snapModeLabel'
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

            // ===== 面板内容(空壳)=====
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dashboard_customize,
                          size: 48, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      Text('Panel Tool', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        '拖到屏幕边缘松手 → 自动吸附\n'
                        '拖离屏幕边缘 → 恢复浮动尺寸\n'
                        '窗口大小可调,自动记忆',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sizeInfoText,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 16),
                      if (_isSnapped)
                        FilledButton.tonalIcon(
                          onPressed: _unsnap,
                          icon: const Icon(Icons.open_in_full, size: 16),
                          label: const Text('解除吸附'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _snapModeLabel {
    switch (_snapMode) {
      case SnapMode.floating:
        return '浮动';
      case SnapMode.top:
        return '吸顶';
      case SnapMode.right:
        return '吸右';
      case SnapMode.left:
        return '吸左';
    }
  }

  String get _sizeInfoText {
    if (!_stateLoaded) return '';
    final f = _state.floatingSize;
    final t = _state.topSnapHeight?.toStringAsFixed(0) ?? '80';
    final r = _state.rightSnapWidth?.toStringAsFixed(0) ?? '320';
    final l = _state.leftSnapWidth?.toStringAsFixed(0) ?? '320';
    return '浮动 ${f.width.toStringAsFixed(0)}×${f.height.toStringAsFixed(0)}'
        ' · 吸顶 h=$t · 吸右 w=$r · 吸左 w=$l';
  }
}
