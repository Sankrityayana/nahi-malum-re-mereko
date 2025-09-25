import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.local_fire_department, color: Colors.orange),
      label: Text('$streak day streak'),
      backgroundColor: Colors.orange.withOpacity(0.1),
    );
  }
}
