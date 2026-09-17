import 'package:flutter/material.dart';

enum PanelToolId { notes, clipboard, timer, snippets }

class PanelTool {
  const PanelTool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.available = true,
  });

  final PanelToolId id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool available;

  static List<PanelTool> catalog(ColorScheme scheme) => [
        PanelTool(
          id: PanelToolId.notes,
          name: '便签',
          description: '快速记录想法',
          icon: Icons.sticky_note_2_outlined,
          color: scheme.tertiary,
        ),
        PanelTool(
          id: PanelToolId.clipboard,
          name: '剪贴板',
          description: '历史记录',
          icon: Icons.content_paste_outlined,
          color: scheme.primary,
        ),
        PanelTool(
          id: PanelToolId.timer,
          name: '计时',
          description: '番茄钟',
          icon: Icons.timer_outlined,
          color: scheme.secondary,
        ),
        PanelTool(
          id: PanelToolId.snippets,
          name: '片段',
          description: '常用文本',
          icon: Icons.text_snippet_outlined,
          color: scheme.error,
        ),
      ];
}
