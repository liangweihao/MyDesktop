import 'package:flutter_test/flutter_test.dart';
import 'package:mydesktop/panel/snippets_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('creates and updates snippets', () async {
    final store = await SnippetsStore.load();
    final item = await store.create(title: 'greet', content: 'hi');
    await store.update(item.id, content: 'hello');

    final reloaded = await SnippetsStore.load();
    expect(reloaded.items.first.content, 'hello');
  });
}
