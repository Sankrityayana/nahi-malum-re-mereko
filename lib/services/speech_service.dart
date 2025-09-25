import 'dart:async';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';

class SpeechService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  Future<void> speak(String text, {String locale = 'en-IN'}) async {
    await _tts.setLanguage(locale); // 'en-IN' or 'hi-IN'
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<bool> initSTT() async {
    final available = await _stt.initialize();
    return available;
  }

  Future<String?> listenOnce({String localeId = 'en_IN', Duration timeout = const Duration(seconds: 5)}) async {
    if (!await initSTT()) return null;
    final completer = Completer<String?>();

    _stt.listen(
      localeId: localeId,
      onResult: (result) {
        if (result.finalResult) {
          completer.complete(result.recognizedWords);
          _stt.stop();
        }
      },
      listenMode: stt.ListenMode.confirmation,
      pauseFor: timeout,
    );

    return completer.future.timeout(timeout + const Duration(seconds: 2), onTimeout: () {
      _stt.stop();
      return null;
    });
  }

  double scoreSimilarity(String target, String recognized) {
    final score = target.similarityTo(recognized); // 0.0 to 1.0
    return (score * 100).clamp(0, 100);
  }

  Future<File> saveDummyAudio(String baseName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$baseName.txt');
    await file.writeAsString('placeholder for audio path');
    return file;
  }
}
