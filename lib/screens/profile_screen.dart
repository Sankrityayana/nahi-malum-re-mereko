import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/gamification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = SupabaseService();
  final _gami = GamificationService();
  List<FlSpot> _spots = const [FlSpot(0, 0)];
  int _streak = 0;
  int _coins = 0;
  List<Map<String, dynamic>> _earned = const [];
  List<Map<String, dynamic>> _allBadges = const [];
  String _progressHint = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final history = await _db.getProgressHistory(userId, limit: 50);
      final pts = <FlSpot>[];
      for (var i = 0; i < history.length; i++) {
        final h = history[i];
        final score = (h['score'] as num).toDouble();
        pts.add(FlSpot(i.toDouble(), score));
      }
      if (pts.isEmpty) pts.add(const FlSpot(0, 0));
      final s = await _gami.getStreak();
      final c = await _gami.getCoins();
      final earned = await _db.listUserBadges(userId);
      final all = await _db.listBadges();
      // Simple progress hints
      final attempts = (await _db.getProgressStats(userId))['attempts'] as num? ?? 0;
      final nextAttempts = [10, 50, 100].firstWhere((t) => attempts < t, orElse: () => 0);
      String hint = '';
      if (nextAttempts > 0) {
        hint = 'Do ${nextAttempts - attempts.toInt()} more attempts to reach $nextAttempts.';
      } else if (_streak < 30) {
        final nextStreak = [3, 7, 30].firstWhere((t) => _streak < t, orElse: () => 0);
        if (nextStreak > 0) hint = 'Keep your streak! ${nextStreak - _streak} days to ${nextStreak}.';
      } else {
        hint = 'Aim for 90%+ accuracy to unlock top badges!';
      }
      if (mounted) setState(() { _spots = pts; _streak = s; _coins = c; _earned = earned; _allBadges = all; _progressHint = hint; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const ListTile(title: Text('Your progress')),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Streak x$_streak, Coins: $_coins'),
                  if (_progressHint.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_progressHint, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _allBadges.map((b) {
                      final code = b['code'];
                      final earned = _earned.any((e) => e['badge_code'] == code);
                      final icon = b['icon'] ?? '🏅';
                      final name = b['name'] ?? code;
                      return Chip(
                        avatar: Text(icon),
                        label: Text(name),
                        backgroundColor: earned ? Colors.green.shade100 : Colors.grey.shade200,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
