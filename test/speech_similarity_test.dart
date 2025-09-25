import 'package:flutter_test/flutter_test.dart';
import 'package:speech_practice_app/services/speech_service.dart';

void main() {
  test('Similarity scoring returns higher for closer strings', () {
    final s = SpeechService();
    final a = s.scoreSimilarity('Hello', 'Hello');
    final b = s.scoreSimilarity('Hello', 'Hollo');
    final c = s.scoreSimilarity('Hello', 'World');
    expect(a > b, true);
    expect(b > c, true);
  });
}
