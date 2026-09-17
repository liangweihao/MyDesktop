import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String kNotesPrefKey = 'mydesktop_notes_v1';

class NoteItem {
  NoteItem({
    required this.id,
    required this.text,
    required this.updatedAt,
  });

  final String id;
  String text;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class NotesStore {
  NotesStore(this._prefs);

  final SharedPreferences _prefs;
  List<NoteItem> _notes = [];

  List<NoteItem> get notes => List.unmodifiable(_notes);

  static Future<NotesStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = NotesStore(prefs);
    await store._load();
    return store;
  }

  Future<void> _load() async {
    final raw = _prefs.getString(kNotesPrefKey);
    if (raw == null) {
      _notes = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _notes = list
          .map((e) => NoteItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      _notes = [];
    }
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await _prefs.setString(kNotesPrefKey, raw);
  }

  Future<NoteItem> create() async {
    final note = NoteItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: '',
      updatedAt: DateTime.now(),
    );
    _notes.insert(0, note);
    await _persist();
    return note;
  }

  Future<void> update(String id, String text) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index < 0) return;
    _notes[index].text = text;
    _notes[index].updatedAt = DateTime.now();
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _persist();
  }

  Future<void> delete(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _persist();
  }
}
