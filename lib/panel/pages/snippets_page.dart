import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mydesktop/panel/snippets_store.dart';
import 'package:mydesktop/panel/widgets/panel_sub_header.dart';

class SnippetsPage extends StatefulWidget {
  const SnippetsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SnippetsPage> createState() => _SnippetsPageState();
}

class _SnippetsPageState extends State<SnippetsPage> {
  SnippetsStore? _store;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    final store = await SnippetsStore.load();
    if (!mounted) return;
    setState(() {
      _store = store;
      _loading = false;
    });
  }

  Future<void> _addSnippet() async {
    final result = await _showEditor(context);
    if (result == null || _store == null) return;
    await _store!.create(title: result.$1, content: result.$2);
    setState(() {});
  }

  Future<void> _editSnippet(SnippetItem item) async {
    final result = await _showEditor(context, item: item);
    if (result == null || _store == null) return;
    await _store!.update(item.id, title: result.$1, content: result.$2);
    setState(() {});
  }

  Future<void> _copyContent(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<(String, String)?> _showEditor(
    BuildContext context, {
    SnippetItem? item,
  }) async {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final contentCtrl = TextEditingController(text: item?.content ?? '');

    return showDialog<(String, String)>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(item == null ? '新建片段' : '编辑片段'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '标题'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: '内容'),
                  maxLines: 5,
                  minLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx, (titleCtrl.text.trim(), contentCtrl.text));
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        PanelSubHeader(
          title: '片段',
          onBack: widget.onBack,
          actions: [
            IconButton(
              onPressed: _loading ? null : _addSnippet,
              icon: const Icon(Icons.add, size: 20),
              tooltip: '新建片段',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _store!.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.text_snippet_outlined,
                              size: 40, color: scheme.outline),
                          const SizedBox(height: 12),
                          Text('暂无片段', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: _addSnippet,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('新建片段'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _store!.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _store!.items[index];
                        return Material(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              item.title.isEmpty ? '(无标题)' : item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _copyContent(item.content),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  await _editSnippet(item);
                                } else if (v == 'delete') {
                                  await _store!.delete(item.id);
                                  setState(() {});
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('编辑')),
                                PopupMenuItem(value: 'delete', child: Text('删除')),
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
