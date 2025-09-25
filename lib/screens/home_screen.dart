import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/streak_badge.dart';
import 'practice_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import '../services/gamification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  final _gami = GamificationService();
  int _streak = 0;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _loadGami();
    // Pull latest from cloud then refresh UI
    Future.microtask(() async { await _gami.pullFromCloud(); await _loadGami(); });
  }

  Future<void> _loadGami() async {
    final s = await _gami.getStreak();
    final c = await _gami.getCoins();
    if (mounted) setState(() { _streak = s; _coins = c; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final session = Supabase.instance.client.auth.currentSession;

    final pages = [
  _Dashboard(onPractice: () => setState(() => _tabIndex = 1), streak: _streak, coins: _coins),
      const PracticeScreen(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Practice'),
        actions: [
          IconButton(onPressed: _loadGami, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => auth.signOut(), icon: const Icon(Icons.logout))
        ],
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.record_voice_over), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final VoidCallback onPractice;
  final int streak;
  final int coins;
  const _Dashboard({required this.onPractice, required this.streak, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          StreakBadge(streak: streak),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Coins: $coins'),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            lineHeight: 14.0,
            percent: 0.4,
            backgroundColor: Colors.grey.shade300,
            progressColor: Theme.of(context).colorScheme.primary,
            barRadius: const Radius.circular(8),
            animation: true,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text('Daily Practice'),
              subtitle: const Text('Keep your streak alive!'),
              trailing: ElevatedButton(onPressed: onPractice, child: const Text('Start')),
            ),
          ),
        ],
      ),
    );
  }
}
