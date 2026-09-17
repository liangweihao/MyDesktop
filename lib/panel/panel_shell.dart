import 'package:flutter/material.dart';
import 'package:mydesktop/panel/models/panel_tool.dart';
import 'package:mydesktop/panel/pages/clipboard_page.dart';
import 'package:mydesktop/panel/pages/notes_page.dart';
import 'package:mydesktop/panel/pages/panel_home_page.dart';
import 'package:mydesktop/panel/pages/settings_page.dart';
import 'package:mydesktop/panel/pages/snippets_page.dart';
import 'package:mydesktop/panel/pages/timer_page.dart';
import 'package:mydesktop/panel/widgets/compact_nav_bar.dart';

class PanelShell extends StatefulWidget {
  const PanelShell({super.key});

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  int _tabIndex = 0;
  PanelToolId? _openTool;

  void _openToolPage(PanelToolId id) => setState(() => _openTool = id);

  void _closeTool() => setState(() => _openTool = null);

  static const _navItems = [
    CompactNavItem(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
      label: '工具',
    ),
    CompactNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: '设置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_openTool != null) {
          return SizedBox.expand(child: _buildToolPage(_openTool!));
        }

        final ultraCompact = constraints.maxHeight < 48;
        final compactNav = constraints.maxHeight < 120;

        if (ultraCompact) {
          return _UltraCompactStrip(
            tabIndex: _tabIndex,
            onSelectTab: (i) => setState(() => _tabIndex = i),
            onOpenTool: _openToolPage,
          );
        }

        return Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  PanelHomePage(onOpenTool: _openToolPage),
                  const SettingsPage(),
                ],
              ),
            ),
            CompactNavBar(
              selectedIndex: _tabIndex,
              onSelected: (i) => setState(() => _tabIndex = i),
              items: _navItems,
              compact: compactNav,
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolPage(PanelToolId id) {
    switch (id) {
      case PanelToolId.notes:
        return NotesPage(onBack: _closeTool);
      case PanelToolId.timer:
        return TimerPage(onBack: _closeTool);
      case PanelToolId.clipboard:
        return ClipboardPage(onBack: _closeTool);
      case PanelToolId.snippets:
        return SnippetsPage(onBack: _closeTool);
    }
  }
}

/// 吸顶极矮窗口：单行图标快捷入口
class _UltraCompactStrip extends StatelessWidget {
  const _UltraCompactStrip({
    required this.tabIndex,
    required this.onSelectTab,
    required this.onOpenTool,
  });

  final int tabIndex;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<PanelToolId> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _iconBtn(
          context,
          icon: Icons.grid_view,
          selected: tabIndex == 0,
          tooltip: '工具',
          onTap: () => onSelectTab(0),
        ),
        _iconBtn(
          context,
          icon: Icons.settings,
          selected: tabIndex == 1,
          tooltip: '设置',
          onTap: () => onSelectTab(1),
        ),
        Container(width: 1, height: 20, color: scheme.outlineVariant),
        _iconBtn(
          context,
          icon: Icons.sticky_note_2_outlined,
          tooltip: '便签',
          onTap: () => onOpenTool(PanelToolId.notes),
        ),
        _iconBtn(
          context,
          icon: Icons.timer_outlined,
          tooltip: '计时',
          onTap: () => onOpenTool(PanelToolId.timer),
        ),
        Expanded(
          child: Text(
            tabIndex == 0 ? 'MyDesktop 工具栏' : '设置',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool selected = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: selected ? scheme.primary : scheme.onSurfaceVariant,
    );
  }
}
