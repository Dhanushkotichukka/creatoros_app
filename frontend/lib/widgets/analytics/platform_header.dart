import 'package:flutter/material.dart';

class PlatformHeader extends StatelessWidget {
  final Map<String, dynamic> platformData;

  const PlatformHeader({super.key, required this.platformData});

  @override
  Widget build(BuildContext context) {
    if (platformData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(platformData['avatar'] ?? 'https://via.placeholder.com/150'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                platformData['name'] ?? 'Unknown Platform',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatChip(label: 'Subscribers', value: platformData['subscribers'] ?? '—', icon: Icons.people, color: Colors.blueAccent),
            _StatChip(label: 'Total Views', value: platformData['totalViews'] ?? '—', icon: Icons.visibility, color: Colors.purpleAccent),
            _StatChip(label: 'Total Likes', value: platformData['totalLikes'] ?? '—', icon: Icons.thumb_up, color: Colors.pinkAccent),
            _StatChip(label: 'Watch Hours', value: platformData['watchTime'] ?? '—', icon: Icons.timer, color: Colors.orangeAccent),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
