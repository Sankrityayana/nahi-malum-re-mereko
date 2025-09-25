import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRandomWords({int limit = 10, String lang = 'en'}) async {
    final res = await _client.rpc('get_random_words', params: {
      'p_lang': lang,
      'p_limit': limit,
    });
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveProgress({required String userId, String? wordId, required String targetText, required double score}) async {
    await _client.from('progress').insert({
      'user_id': userId,
      'word_id': wordId,
      'target_text': targetText,
      'score': score,
    });
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    final res = await _client.rpc('get_leaderboard', params: {'limit_count': limit});
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<String?> uploadRecording(String userId, String localPath) async {
    final fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.wav';
    final storagePath = '$userId/$fileName';
    await _client.storage.from('recordings').upload(storagePath, File(localPath));
    final url = _client.storage.from('recordings').getPublicUrl(storagePath);
    return url;
  }

  Future<List<Map<String, dynamic>>> getProgressHistory(String userId, {int limit = 50}) async {
    final res = await _client
        .from('progress')
        .select('created_at, score')
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listBadges() async {
    final res = await _client.from('badges').select('code, name, description, icon');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listUserBadges(String userId) async {
    final res = await _client
        .from('user_badges')
        .select('badge_code, earned_at, badges:badge_code(code, name, description, icon)')
        .eq('user_id', userId)
        .order('earned_at');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> awardBadge(String userId, String badgeCode) async {
    await _client.from('user_badges').upsert({'user_id': userId, 'badge_code': badgeCode});
  }

  Future<Map<String, dynamic>> getProgressStats(String userId) async {
    final res = await _client.rpc('get_progress_stats', params: {'p_user': userId});
    if (res is List && res.isNotEmpty) return (res.first as Map).cast<String, dynamic>();
    if (res is Map) return res.cast<String, dynamic>();
    return {};
  }

  Future<List<Map<String, dynamic>>> computeAndAwardBadges(String userId) async {
    final res = await _client.rpc('compute_and_award_badges', params: {'p_user': userId});
    if (res is List) return (res).cast<Map<String, dynamic>>();
    return [];
  }
}
