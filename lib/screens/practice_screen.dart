import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/speech_service.dart';
import '../services/supabase_service.dart';
import '../services/recording_service.dart';
import '../services/gamification_service.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final SpeechService _speech = SpeechService();
  final SupabaseService _db = SupabaseService();
  final RecordingService _rec = RecordingService();
  final GamificationService _gami = GamificationService();

  String _target = 'नमस्ते / Hello';
  String? _wordId;
  String _lang = 'hi';
  String? _recognized;
  double? _score;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Load a random word on first open
    WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  void _next() async {
    try {
      final list = await _db.getRandomWords(limit: 1, lang: _lang);
      if (list.isNotEmpty) setState(() { _target = list.first['text']; _wordId = list.first['id']; });
    } catch (_) {}
  }

  void _tts() async {
    await _speech.speak(_target, locale: _lang == 'hi' ? 'hi-IN' : 'en-IN');
  }

  void _record() async {
    if (_isListening) return;
    setState(() => _isListening = true);
    final text = await _speech.listenOnce(localeId: _lang == 'hi' ? 'hi_IN' : 'en_IN');
    if (text != null) {
  // Keep Latin (A-Z) and Devanagari (U+0900–U+097F) letters + spaces
  final normalizedTarget = _target.replaceAll(RegExp(r'[^A-Za-z\u0900-\u097F\s]'), '');
  final normalizedHeard = text.replaceAll(RegExp(r'[^A-Za-z\u0900-\u097F\s]'), '');
      final score = _speech.scoreSimilarity(normalizedTarget, normalizedHeard);
      setState(() { _recognized = text; _score = score; });
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _db.saveProgress(userId: userId, wordId: _wordId, targetText: _target, score: score);
        await _gami.bumpOnPractice();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress saved!')));
        }

        // Server-side compute+award; show unlock dialog if any
        try {
          final newlyAwarded = await _db.computeAndAwardBadges(userId);
          if (mounted && newlyAwarded.isNotEmpty) {
            showDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('Badges Unlocked!'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.8, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (c, scale, child) => Transform.scale(scale: scale, child: child),
                        child: const Icon(Icons.emoji_events, size: 56, color: Colors.amber),
                      ),
                      const SizedBox(height: 8),
                      ...newlyAwarded.map((b) => ListTile(
                        leading: Text((b['icon'] ?? '🏅').toString(), style: const TextStyle(fontSize: 20)),
                        title: Text(b['name']?.toString() ?? b['code']?.toString() ?? 'Badge'),
                      ))
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Nice!'))
                  ],
                );
              }
            );
          }
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _isListening = false);
  }

  void _recordAndUpload() async {
    final startedPath = await _rec.start();
    if (startedPath == null) return;
    // Wait for 3 seconds and stop (simple demo). In UI, you could toggle instead.
    await Future.delayed(const Duration(seconds: 3));
    final path = await _rec.stop();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && path != null) {
      await _db.uploadRecording(userId, path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded recording')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'hi', label: Text('Hindi')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {_lang},
            onSelectionChanged: (s) => setState(() => _lang = s.first),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(_target, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.center, children: [
                    ElevatedButton.icon(onPressed: _tts, icon: const Icon(Icons.volume_up), label: const Text('Listen')),
                    FilledButton.icon(
                      onPressed: _record,
                      onLongPress: _recordAndUpload,
                      icon: Icon(_isListening ? Icons.hearing : Icons.mic),
                      label: Text(_isListening ? 'Listening…' : 'Record'),
                    ),
                    OutlinedButton.icon(onPressed: _next, icon: const Icon(Icons.shuffle), label: const Text('Random')),
                  ]),
                  const SizedBox(height: 16),
                  if (_score != null)
                    _AccuracyRing(score: _score!.clamp(0, 100).toDouble()),
                  if (_score != null) const SizedBox(height: 8),
                  if (_score != null)
                    Text(
                      _score! >= 80 ? 'Shabash! Great job.' : (_score! >= 60 ? 'Getting there! Try once more.' : 'Keep practicing, you’ve got this!'),
                      style: TextStyle(color: _score! >= 80 ? Colors.green : (_score! >= 60 ? Colors.orange : Colors.red)),
                    )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_recognized != null)
            Card(
              color: (_score ?? 0) > 70 ? Colors.green.shade50 : Colors.red.shade50,
              child: ListTile(
                title: Text('You said: $_recognized'),
                subtitle: Text('Accuracy: ${_score?.toStringAsFixed(1)}%'),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccuracyRing extends StatelessWidget {
  final double score; // 0-100
  const _AccuracyRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score / 100).clamp(0.0, 1.0);
    final color = score >= 80 ? Colors.green : (score >= 60 ? Colors.orange : Colors.red);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0, end: pct),
      builder: (context, v, _) => SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: v, strokeWidth: 10, color: color, backgroundColor: Colors.grey.shade300),
            Text('${score.toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }
}
