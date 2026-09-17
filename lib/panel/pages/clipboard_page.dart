import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mydesktop/panel/clipboard_reader.dart';
import 'package:mydesktop/panel/clipboard_store.dart';
import 'package:mydesktop/panel/widgets/panel_sub_header.dart';

class ClipboardPage extends StatefulWidget {
  const ClipboardPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final _reader = SystemClipboardReader();
  ClipboardStore? _store;
  Timer? _pollTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final store = await ClipboardStore.load();
    await store.poll(_reader);
    if (!mounted) return;
    setState(() {
      _store = store;
      _loading = false;
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  Future<void> _poll() async {
    final store = _store;
    if (store == null) return;
    final added = await store.poll(_reader);
    if (added && mounted) setState(() {});
  }

  Future<void> _copyEntry(String text) async {
    await _reader.writeText(text);
    _store?.markWritten(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _refreshNow() async {
    await _poll();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        PanelSubHeader(
          title: '剪贴板',
          onBack: widget.onBack,
          actions: [
            IconButton(
              onPressed: _loading ? null : _refreshNow,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: '立即刷新',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (!_loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              '后台每秒检测系统剪贴板 · 共 ${_store!.entries.length} 条',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _store!.entries.isEmpty
                  ? Center(
                      child: Text(
                        '暂无记录\n复制任意文本后会出现在这里',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _store!.entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = _store!.entries[index];
                        return _ClipboardTile(
                          entry: entry,
                          onCopy: () => _copyEntry(entry.text),
                          onDelete: () async {
                            await _store!.delete(entry.id);
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ClipboardTile extends StatelessWidget {
  const _ClipboardTile({
    required this.entry,
    required this.onCopy,
    required this.onDelete,
  });

  final ClipboardEntry entry;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(entry.copiedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: '删除',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '${time.month}/${time.day} $h:$m';
  }
}
