import 'package:flutter_test/flutter_test.dart';
import 'package:mydesktop/panel/clipboard_reader.dart';
import 'package:mydesktop/panel/clipboard_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('addText deduplicates consecutive same content', () async {
    final store = await ClipboardStore.load();
    await store.addText('hello');
    await store.addText('hello');
    expect(store.entries, hasLength(1));
  });

  test('poll skips when text unchanged', () async {
    final store = await ClipboardStore.load();
    await store.addText('a', fromPoll: true);

    final reader = _FakeReader('a');
    expect(await store.poll(reader), isFalse);
    expect(store.entries, hasLength(1));
  });

  test('poll adds new clipboard text', () async {
    final store = await ClipboardStore.load();
    final reader = _FakeReader('new item');
    expect(await store.poll(reader), isTrue);
    expect(store.entries.first.text, 'new item');
  });
}

class _FakeReader implements ClipboardReader {
  _FakeReader(this._text);

  final String? _text;

  @override
  Future<String?> readText() async => _text;

  @override
  Future<void> writeText(String text) async {}
}
