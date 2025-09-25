import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  static const _kStreak = 'streak_count';
  static const _kLastPractice = 'last_practice_date';
  static const _kCoins = 'coins_total';
  final _client = Supabase.instance.client;

  Future<int> getStreak() async {
    // Try cloud first
    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final res = await _client.from('user_stats').select('streak').eq('user_id', uid).maybeSingle();
        if (res != null && res['streak'] != null) return (res['streak'] as num).toInt();
      } catch (_) {}
    }
    // Fallback local
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kStreak) ?? 0;
  }

  Future<int> bumpOnPractice() async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastIso = sp.getString(_kLastPractice);
    int streak = sp.getInt(_kStreak) ?? 0;

    DateTime? last = lastIso != null ? DateTime.tryParse(lastIso) : null;
    if (last == null) {
      streak = 1;
    } else {
      final diff = now.difference(DateTime(last.year, last.month, last.day)).inDays;
      if (diff == 0) {
        // same day, keep streak
      } else if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1; // reset
      }
    }

    await sp.setInt(_kStreak, streak);
    await sp.setString(_kLastPractice, now.toIso8601String());

    final coins = (sp.getInt(_kCoins) ?? 0) + 5; // reward
    await sp.setInt(_kCoins, coins);

    // Sync to cloud
    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await _client.from('user_stats').upsert({
          'user_id': uid,
          'streak': streak,
          'coins': coins,
          'last_practice_date': DateTime(now.year, now.month, now.day).toIso8601String(),
        });
      } catch (_) {}
    }

    return streak;
  }

  Future<int> getCoins() async {
    // Try cloud first
    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final res = await _client.from('user_stats').select('coins').eq('user_id', uid).maybeSingle();
        if (res != null && res['coins'] != null) return (res['coins'] as num).toInt();
      } catch (_) {}
    }
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kCoins) ?? 0;
  }

  Future<void> pullFromCloud() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await _client.from('user_stats').select('streak, coins, last_practice_date').eq('user_id', uid).maybeSingle();
      if (res != null) {
        final sp = await SharedPreferences.getInstance();
        if (res['streak'] != null) await sp.setInt(_kStreak, (res['streak'] as num).toInt());
        if (res['coins'] != null) await sp.setInt(_kCoins, (res['coins'] as num).toInt());
        if (res['last_practice_date'] != null) await sp.setString(_kLastPractice, DateTime.parse(res['last_practice_date']).toIso8601String());
      }
    } catch (_) {}
  }
}
