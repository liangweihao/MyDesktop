import 'dart:convert';

import 'package:mydesktop/panel/clipboard_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kClipboardPrefKey = 'mydesktop_clipboard_v1';
const int kClipboardMaxItems = 50;

class ClipboardEntry {
  ClipboardEntry({
    required this.id,
    required this.text,
    required this.copiedAt,
  });

  final String id;
  final String text;
  final DateTime copiedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'copiedAt': copiedAt.toIso8601String(),
      };

  factory ClipboardEntry.fromJson(Map<String, dynamic> json) => ClipboardEntry(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        copiedAt: DateTime.tryParse(json['copiedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class ClipboardStore {
  ClipboardStore(this._prefs);

  final SharedPreferences _prefs;
  final List<ClipboardEntry> _entries = [];
  String? _lastPolledText;

  List<ClipboardEntry> get entries => List.unmodifiable(_entries);

  static Future<ClipboardStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = ClipboardStore(prefs);
    await store._load();
    return store;
  }

  Future<void> _load() async {
    final raw = _prefs.getString(kClipboardPrefKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _entries
        ..clear()
        ..addAll(
          list.map((e) => ClipboardEntry.fromJson(e as Map<String, dynamic>)),
        );
      _entries.sort((a, b) => b.copiedAt.compareTo(a.copiedAt));
    } catch (_) {
      _entries.clear();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      kClipboardPrefKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addText(String text, {bool fromPoll = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (_entries.isNotEmpty && _entries.first.text == trimmed) return;

    _entries.insert(
      0,
      ClipboardEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: trimmed,
        copiedAt: DateTime.now(),
      ),
    );
    while (_entries.length > kClipboardMaxItems) {
      _entries.removeLast();
    }
    if (fromPoll) _lastPolledText = trimmed;
    await _persist();
  }

  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _persist();
  }

  /// 轮询系统剪贴板；有新增返回 true
  Future<bool> poll(ClipboardReader reader) async {
    final text = await reader.readText();
    if (text == null) return false;
    if (text == _lastPolledText) return false;
    if (_entries.isNotEmpty && _entries.first.text == text) {
      _lastPolledText = text;
      return false;
    }
    await addText(text, fromPoll: true);
    return true;
  }

  void markWritten(String text) {
    _lastPolledText = text.trim();
  }
}
