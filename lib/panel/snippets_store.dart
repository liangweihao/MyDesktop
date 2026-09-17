import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String kSnippetsPrefKey = 'mydesktop_snippets_v1';

class SnippetItem {
  SnippetItem({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String id;
  String title;
  String content;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SnippetItem.fromJson(Map<String, dynamic> json) => SnippetItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class SnippetsStore {
  SnippetsStore(this._prefs);

  final SharedPreferences _prefs;
  List<SnippetItem> _items = [];

  List<SnippetItem> get items => List.unmodifiable(_items);

  static Future<SnippetsStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = SnippetsStore(prefs);
    await store._load();
    return store;
  }

  Future<void> _load() async {
    final raw = _prefs.getString(kSnippetsPrefKey);
    if (raw == null) {
      _items = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _items = list
          .map((e) => SnippetItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      _items = [];
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      kSnippetsPrefKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<SnippetItem> create({String title = '', String content = ''}) async {
    final item = SnippetItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      content: content,
      updatedAt: DateTime.now(),
    );
    _items.insert(0, item);
    await _persist();
    return item;
  }

  Future<void> update(String id, {String? title, String? content}) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    if (title != null) _items[index].title = title;
    if (content != null) _items[index].content = content;
    _items[index].updatedAt = DateTime.now();
    _items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _persist();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _persist();
  }
}
