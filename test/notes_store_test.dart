import 'package:flutter_test/flutter_test.dart';
import 'package:mydesktop/panel/notes_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotesStore', () {
    test('creates and persists notes', () async {
      final store = await NotesStore.load();
      expect(store.notes, isEmpty);

      final note = await store.create();
      await store.update(note.id, 'hello');

      final reloaded = await NotesStore.load();
      expect(reloaded.notes, hasLength(1));
      expect(reloaded.notes.first.text, 'hello');
    });

    test('deletes note', () async {
      final store = await NotesStore.load();
      final note = await store.create();
      await store.delete(note.id);

      final reloaded = await NotesStore.load();
      expect(reloaded.notes, isEmpty);
    });
  });
}
