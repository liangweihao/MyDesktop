import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String kPomodoroSettingsKey = 'mydesktop_pomodoro_settings_v1';
const String kPomodoroStatsKey = 'mydesktop_pomodoro_stats_v1';

class PomodoroSettings {
  PomodoroSettings({
    this.focusMinutes = 25,
    this.breakMinutes = 5,
    this.soundEnabled = true,
  });

  int focusMinutes;
  int breakMinutes;
  bool soundEnabled;

  Map<String, dynamic> toJson() => {
        'focus': focusMinutes,
        'break': breakMinutes,
        'sound': soundEnabled,
      };

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) =>
      PomodoroSettings(
        focusMinutes: (json['focus'] as num?)?.toInt() ?? 25,
        breakMinutes: (json['break'] as num?)?.toInt() ?? 5,
        soundEnabled: json['sound'] as bool? ?? true,
      );
}

class PomodoroSettingsStore {
  PomodoroSettingsStore(this._prefs);

  final SharedPreferences _prefs;
  PomodoroSettings settings = PomodoroSettings();
  final Map<String, int> _dailyFocusCount = {};

  static Future<PomodoroSettingsStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = PomodoroSettingsStore(prefs);
    await store._load();
    return store;
  }

  Future<void> _load() async {
    final settingsRaw = _prefs.getString(kPomodoroSettingsKey);
    if (settingsRaw != null) {
      try {
        settings = PomodoroSettings.fromJson(
          jsonDecode(settingsRaw) as Map<String, dynamic>,
        );
      } catch (_) {
        settings = PomodoroSettings();
      }
    }

    final statsRaw = _prefs.getString(kPomodoroStatsKey);
    if (statsRaw != null) {
      try {
        final map = jsonDecode(statsRaw) as Map<String, dynamic>;
        _dailyFocusCount
          ..clear()
          ..addAll(map.map((k, v) => MapEntry(k, (v as num).toInt())));
      } catch (_) {
        _dailyFocusCount.clear();
      }
    }
  }

  Future<void> saveSettings() async {
    await _prefs.setString(
      kPomodoroSettingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get todayCompletedFocus => _dailyFocusCount[_todayKey()] ?? 0;

  Future<void> recordFocusCompleted() async {
    final key = _todayKey();
    _dailyFocusCount[key] = (_dailyFocusCount[key] ?? 0) + 1;
    await _prefs.setString(kPomodoroStatsKey, jsonEncode(_dailyFocusCount));
  }
}
