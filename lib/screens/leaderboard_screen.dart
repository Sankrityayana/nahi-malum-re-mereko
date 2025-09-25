import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseService _db = SupabaseService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _db.getLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _db.getLeaderboard()),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemBuilder: (c, i) {
              if (i == 0) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() => _future = _db.getLeaderboard()),
                  ),
                );
              }
              final row = data[i - 1];
              return ListTile(
                leading: CircleAvatar(child: Text('$i')),
                title: Text(row['email'] ?? row['user_id'] ?? 'User'),
                trailing: Text('${row['total_score'] ?? row['score'] ?? 0}'),
              );
            },
            separatorBuilder: (ctx, i) => i == 0 ? const SizedBox.shrink() : const Divider(height: 0),
            itemCount: data.length + 1,
          ),
        );
      },
    );
  }
}
