import 'package:flutter/material.dart';
import 'package:mydesktop/panel/models/panel_tool.dart';
import 'package:mydesktop/panel/widgets/tool_card.dart';

class PanelHomePage extends StatelessWidget {
  const PanelHomePage({super.key, required this.onOpenTool});

  final ValueChanged<PanelToolId> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tools = PanelTool.catalog(theme.colorScheme);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      children: [
        Text('工具', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          '选择下方工具开始使用',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final tool = tools[index];
            return ToolCard(
              tool: tool,
              onTap: () => onOpenTool(tool.id),
            );
          },
        ),
      ],
    );
  }
}
