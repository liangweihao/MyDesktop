import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mydesktop/panel/notes_store.dart';
import 'package:mydesktop/panel/widgets/panel_sub_header.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  NotesStore? _store;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    final store = await NotesStore.load();
    if (!mounted) return;
    setState(() {
      _store = store;
      _loading = false;
    });
  }

  Future<void> _addNote() async {
    final store = _store;
    if (store == null) return;
    await store.create();
    setState(() {});
  }

  Future<void> _deleteNote(String id) async {
    final store = _store;
    if (store == null) return;
    await store.delete(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        PanelSubHeader(
          title: '便签',
          onBack: widget.onBack,
          actions: [
            IconButton(
              onPressed: _loading ? null : _addNote,
              icon: const Icon(Icons.add, size: 20),
              tooltip: '新建便签',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _store!.notes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 40, color: scheme.outline),
                            const SizedBox(height: 12),
                            Text('暂无便签', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: _addNote,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('新建便签'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _store!.notes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final note = _store!.notes[index];
                        return _NoteCard(
                          key: ValueKey(note.id),
                          note: note,
                          onChanged: (text) async {
                            await _store!.update(note.id, text);
                          },
                          onDelete: () => _deleteNote(note.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatefulWidget {
  const _NoteCard({
    super.key,
    required this.note,
    required this.onChanged,
    required this.onDelete,
  });

  final NoteItem note;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.text);
  }

  @override
  void didUpdateWidget(covariant _NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id == widget.note.id &&
        oldWidget.note.text != widget.note.text &&
        _controller.text != widget.note.text) {
      _controller.text = widget.note.text;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSave(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatTime(widget.note.updatedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: '删除',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            TextField(
              controller: _controller,
              onChanged: _scheduleSave,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: '写点什么…',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
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
