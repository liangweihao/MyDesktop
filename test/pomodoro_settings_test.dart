import 'package:flutter_test/flutter_test.dart';
import 'package:mydesktop/panel/pomodoro_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists settings and daily stats', () async {
    final store = await PomodoroSettingsStore.load();
    store.settings.focusMinutes = 30;
    store.settings.breakMinutes = 8;
    await store.saveSettings();
    await store.recordFocusCompleted();

    final reloaded = await PomodoroSettingsStore.load();
    expect(reloaded.settings.focusMinutes, 30);
    expect(reloaded.settings.breakMinutes, 8);
    expect(reloaded.todayCompletedFocus, 1);
  });
}
