import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseService _db = SupabaseService();
  Future<List<Map<String, dynamic>>>? _future;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = _fetchLeaderboard();
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboard() async {
    setState(() => _error = null);
    try {
      // Try external API first (works on Web hosting alongside an /api route)
      final uri = kIsWeb
          ? Uri.parse('${Uri.base.origin}/api/leaderboard')
          : Uri.parse('http://localhost/api/leaderboard'); // placeholder; will likely fail on mobile and fallback to Supabase
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          return body.map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>()).toList();
        }
      }
      // Fallback to Supabase RPC if API not available
      return await _db.getLeaderboard();
    } catch (e) {
      try {
        return await _db.getLeaderboard();
      } catch (e2) {
        setState(() => _error = 'Could not load leaderboard.');
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final msg = _error ?? 'Something went wrong.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _future = _fetchLeaderboard()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snap.data ?? const <Map<String, dynamic>>[];
        if (data.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _fetchLeaderboard()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: Text('No scores yet')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _fetchLeaderboard()),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemBuilder: (c, i) {
              final row = data[i];
              final rank = i + 1;
              final title = (row['email'] ?? row['user'] ?? row['user_id'] ?? 'User').toString();
              final score = (row['total_score'] ?? row['score'] ?? 0).toString();
              return ListTile(
                leading: CircleAvatar(child: Text('$rank')),
                title: Text(title),
                trailing: Text(score),
              );
            },
            separatorBuilder: (ctx, i) => const Divider(height: 0),
            itemCount: data.length,
          ),
        );
      },
    );
  }
}
