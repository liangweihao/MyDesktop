import 'package:flutter/material.dart';

class PanelSubHeader extends StatelessWidget {
  const PanelSubHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.actions = const [],
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: '返回',
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(title, style: theme.textTheme.titleSmall),
          ),
          ...actions,
        ],
      ),
    );
  }
}
