enum PomodoroPhase { focus, breakTime }

String formatPomodoroTime(int totalSeconds) {
  final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class PomodoroTimer {
  PomodoroTimer({
    this.focusMinutes = 25,
    this.breakMinutes = 5,
  }) : remainingSeconds = focusMinutes * 60;

  int focusMinutes;
  int breakMinutes;

  PomodoroPhase phase = PomodoroPhase.focus;
  int remainingSeconds;
  bool running = false;

  int get phaseTotalSeconds => phase == PomodoroPhase.focus
      ? focusMinutes * 60
      : breakMinutes * 60;

  double get progress {
    final total = phaseTotalSeconds;
    if (total <= 0) return 0;
    return 1 - remainingSeconds / total;
  }

  String get phaseLabel =>
      phase == PomodoroPhase.focus ? '专注' : '休息';

  void applyDurations(int focus, int breakMin) {
    focusMinutes = focus.clamp(1, 120);
    breakMinutes = breakMin.clamp(1, 60);
    resetPhase();
  }

  void resetPhase() {
    remainingSeconds = phaseTotalSeconds;
    running = false;
  }

  void togglePhase() {
    phase = phase == PomodoroPhase.focus
        ? PomodoroPhase.breakTime
        : PomodoroPhase.focus;
    resetPhase();
  }

  /// 返回 true 表示刚完成一个专注阶段
  bool tick() {
    if (remainingSeconds <= 0) return false;
    remainingSeconds--;
    if (remainingSeconds <= 0) {
      running = false;
      final completedFocus = phase == PomodoroPhase.focus;
      togglePhase();
      return completedFocus;
    }
    return false;
  }
}
