import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class HomeRecentActivity extends StatelessWidget {
  final List<dynamic> topContent;
  const HomeRecentActivity({super.key, required this.topContent});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    final activities = _buildActivities(topContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            Text('View all →', style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ActivityCard(item: activities[i], c: c),
          ),
        ),
      ],
    );
  }

  List<_ActivityItem> _buildActivities(List<dynamic> content) {
    final defaults = [
      _ActivityItem(icon: Icons.comment, color: Colors.blueAccent,
          title: 'New comment on', subtitle: 'Horror Turns Into Sci-Fi Crime',
          platform: 'YouTube', platformColor: const Color(0xFFFF0000), time: '2m ago'),
      _ActivityItem(icon: Icons.person_add, color: Colors.pinkAccent,
          title: 'New follower', subtitle: '@movie_lover_143 started following you',
          platform: 'Instagram', platformColor: const Color(0xFFE1306C), time: '5m ago'),
      _ActivityItem(icon: Icons.handshake, color: Colors.blueAccent,
          title: 'New connection', subtitle: 'Ravi Teja connected with you',
          platform: 'LinkedIn', platformColor: const Color(0xFF0A66C2), time: '12m ago'),
      _ActivityItem(icon: Icons.bar_chart, color: Colors.greenAccent,
          title: 'Your video reached', subtitle: '1K views in last 1 hour',
          platform: 'YouTube', platformColor: const Color(0xFFFF0000), time: '15m ago'),
    ];

    if (content.isNotEmpty) {
      return [
        _ActivityItem(icon: Icons.bar_chart, color: Colors.greenAccent,
            title: 'Top content', subtitle: content.first['title'] ?? 'Your video is trending',
            platform: content.first['platform'] ?? 'YouTube',
            platformColor: content.first['platform'] == 'Instagram'
                ? const Color(0xFFE1306C) : const Color(0xFFFF0000),
            time: 'Just now'),
        ...defaults.take(3),
      ];
    }
    return defaults;
  }
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title, subtitle, platform, time;
  final Color platformColor;
  const _ActivityItem({
    required this.icon, required this.color, required this.title,
    required this.subtitle, required this.platform,
    required this.platformColor, required this.time,
  });
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  final AppColors c;
  const _ActivityCard({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 14),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.platformColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(item.platform,
                  style: TextStyle(color: item.platformColor, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(item.title,
              style: TextStyle(color: c.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(item.time, style: TextStyle(color: c.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}
