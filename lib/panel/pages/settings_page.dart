import 'package:flutter/material.dart';
import 'package:mydesktop/window/window_scope.dart';
import 'package:mydesktop/window/window_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scope = WindowScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      children: [
        Text('窗口', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _InfoCard(
          title: '当前模式',
          value: _modeLabel(scope.mode, scope.edge),
        ),
        if (scope.stateLoaded) ...[
          const SizedBox(height: 8),
          _InfoCard(title: '尺寸记忆', value: scope.state.summaryText),
        ],
        const SizedBox(height: 16),
        Text('切换模式', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: scope.isEdgeMode ? scope.enterFloating : null,
              child: const Text('浮动'),
            ),
            OutlinedButton(
              onPressed: () => scope.enterEdge(EdgeAnchor.top),
              child: const Text('吸顶'),
            ),
            OutlinedButton(
              onPressed: () => scope.enterEdge(EdgeAnchor.left),
              child: const Text('吸左'),
            ),
            OutlinedButton(
              onPressed: () => scope.enterEdge(EdgeAnchor.right),
              child: const Text('吸右'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('关于', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          'MyDesktop 桌面面板 · 窗口尺寸与位置会自动保存',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _modeLabel(WindowMode mode, EdgeAnchor? edge) {
    if (mode == WindowMode.floating) return '浮动';
    switch (edge) {
      case EdgeAnchor.top:
        return '边缘 · 顶';
      case EdgeAnchor.left:
        return '边缘 · 左';
      case EdgeAnchor.right:
        return '边缘 · 右';
      case null:
        return '边缘';
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
