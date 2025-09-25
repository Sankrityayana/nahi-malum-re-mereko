import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingService {
  final _rec = AudioRecorder();

  Future<bool> hasPermission() async {
    return await _rec.hasPermission();
  }

  Future<String?> start() async {
    if (!await hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );
    return path;
  }

  Future<String?> stop() async {
    return await _rec.stop();
  }

  Future<void> dispose() async {
    await _rec.dispose();
  }
}
