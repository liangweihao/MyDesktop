import 'package:flutter/material.dart';
import 'package:mydesktop/panel/models/panel_tool.dart';
import 'package:mydesktop/panel/widgets/panel_sub_header.dart';

class ToolPlaceholderPage extends StatelessWidget {
  const ToolPlaceholderPage({
    super.key,
    required this.toolId,
    required this.onBack,
  });

  final PanelToolId toolId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tools = PanelTool.catalog(scheme);
    final tool = tools.firstWhere((t) => t.id == toolId);

    return Column(
      children: [
        PanelSubHeader(title: tool.name, onBack: onBack),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tool.icon, size: 48, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(tool.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${tool.description}功能开发中',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
