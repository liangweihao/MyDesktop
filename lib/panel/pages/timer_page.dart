import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mydesktop/panel/pomodoro_settings_store.dart';
import 'package:mydesktop/panel/pomodoro_timer.dart';
import 'package:mydesktop/panel/widgets/panel_sub_header.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  PomodoroTimer? _timer;
  PomodoroSettingsStore? _settingsStore;
  Timer? _ticker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final store = await PomodoroSettingsStore.load();
    final timer = PomodoroTimer(
      focusMinutes: store.settings.focusMinutes,
      breakMinutes: store.settings.breakMinutes,
    );
    if (!mounted) return;
    setState(() {
      _settingsStore = store;
      _timer = timer;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onFocusCompleted() {
    final store = _settingsStore;
    if (store == null) return;
    store.recordFocusCompleted();
    if (store.settings.soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('专注完成！今日第 ${store.todayCompletedFocus} 个番茄'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  void _start() {
    final timer = _timer;
    if (timer == null || timer.running) return;
    setState(() => timer.running = true);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _timer == null) return;
      final completedFocus = _timer!.tick();
      if (completedFocus) _onFocusCompleted();
      setState(() {});
    });
  }

  void _pause() {
    _ticker?.cancel();
    if (_timer != null) setState(() => _timer!.running = false);
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _timer?.running = false;
      _timer?.resetPhase();
    });
  }

  void _skipPhase() {
    _ticker?.cancel();
    setState(() {
      _timer?.running = false;
      _timer?.togglePhase();
    });
  }

  Future<void> _openSettings() async {
    final store = _settingsStore;
    final timer = _timer;
    if (store == null || timer == null) return;

    var focus = store.settings.focusMinutes.toDouble();
    var breakMin = store.settings.breakMinutes.toDouble();
    var sound = store.settings.soundEnabled;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('番茄钟设置', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text('专注 ${focus.round()} 分钟'),
                  Slider(
                    value: focus,
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${focus.round()}',
                    onChanged: (v) => setSheetState(() => focus = v),
                  ),
                  Text('休息 ${breakMin.round()} 分钟'),
                  Slider(
                    value: breakMin,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '${breakMin.round()}',
                    onChanged: (v) => setSheetState(() => breakMin = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('阶段完成提示音'),
                    value: sound,
                    onChanged: (v) => setSheetState(() => sound = v),
                  ),
                  FilledButton(
                    onPressed: () async {
                      store.settings.focusMinutes = focus.round();
                      store.settings.breakMinutes = breakMin.round();
                      store.settings.soundEnabled = sound;
                      await store.saveSettings();
                      timer.applyDurations(
                        store.settings.focusMinutes,
                        store.settings.breakMinutes,
                      );
                      if (context.mounted) {
                        setState(() {});
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timer = _timer;
    final store = _settingsStore;

    if (_loading || timer == null || store == null) {
      return Column(
        children: [
          PanelSubHeader(title: '番茄钟', onBack: widget.onBack),
          const Expanded(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      );
    }

    final isFocus = timer.phase == PomodoroPhase.focus;
    final accent = isFocus ? scheme.primary : scheme.tertiary;

    return Column(
      children: [
        PanelSubHeader(
          title: '番茄钟',
          onBack: widget.onBack,
          actions: [
            IconButton(
              onPressed: _openSettings,
              icon: const Icon(Icons.tune, size: 20),
              tooltip: '设置',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ringSize = (constraints.maxWidth * 0.48)
                  .clamp(96.0, 160.0)
                  .toDouble();
              final compact = constraints.maxHeight < 320;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, compact ? 8 : 16, 16, 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          timer.phaseLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: accent,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 20),
                      SizedBox(
                        width: ringSize,
                        height: ringSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: timer.progress,
                              strokeWidth: compact ? 6 : 8,
                              color: accent,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                            Text(
                              formatPomodoroTime(timer.remainingSeconds),
                              style: (compact
                                      ? theme.textTheme.titleLarge
                                      : theme.textTheme.headlineMedium)
                                  ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${timer.focusMinutes} 分钟专注 · ${timer.breakMinutes} 分钟休息',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '今日完成 ${store.todayCompletedFocus} 个番茄',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (timer.running)
                            FilledButton.icon(
                              onPressed: _pause,
                              icon: const Icon(Icons.pause, size: 18),
                              label: const Text('暂停'),
                            )
                          else
                            FilledButton.icon(
                              onPressed: _start,
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('开始'),
                            ),
                          OutlinedButton(
                            onPressed: _reset,
                            child: const Text('重置'),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _skipPhase,
                        child: Text(isFocus ? '跳过，开始休息' : '跳过，开始专注'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
