import 'package:flutter_test/flutter_test.dart';
import 'package:mydesktop/panel/pomodoro_timer.dart';

void main() {
  test('formatPomodoroTime pads minutes and seconds', () {
    expect(formatPomodoroTime(125), '02:05');
    expect(formatPomodoroTime(0), '00:00');
  });

  test('tick switches phase when focus ends', () {
    final timer = PomodoroTimer(focusMinutes: 1, breakMinutes: 1);
    timer.remainingSeconds = 1;
    timer.running = true;

    expect(timer.tick(), isTrue);
    expect(timer.phase, PomodoroPhase.breakTime);
    expect(timer.remainingSeconds, 60);
    expect(timer.running, isFalse);
  });

  test('togglePhase alternates focus and break', () {
    final timer = PomodoroTimer(focusMinutes: 25, breakMinutes: 5);
    timer.togglePhase();
    expect(timer.phase, PomodoroPhase.breakTime);
    expect(timer.remainingSeconds, 300);
  });

  test('applyDurations updates countdown', () {
    final timer = PomodoroTimer(focusMinutes: 25, breakMinutes: 5);
    timer.applyDurations(10, 3);
    expect(timer.focusMinutes, 10);
    expect(timer.remainingSeconds, 600);
  });
}
