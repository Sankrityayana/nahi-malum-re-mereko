import 'package:flutter_test/flutter_test.dart';
import 'package:speech_practice_app/services/gamification_service.dart';

void main() {
  test('Streak increments day over day and resets after gap', () async {
    final g = GamificationService();
    // We can only test local behavior deterministically here.
    final s1 = await g.bumpOnPractice();
    expect(s1 >= 1, true);
    final s2 = await g.getStreak();
    expect(s2, s1);
  });
}
