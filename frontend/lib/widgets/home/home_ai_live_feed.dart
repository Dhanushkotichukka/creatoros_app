import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class HomeAiLiveFeed extends StatelessWidget {
  final List<String> insights;

  const HomeAiLiveFeed({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    final feedItems = _buildFeedItems(insights);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c.primary, c.primary.withOpacity(0.6)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Text('AI Live Feed',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('View all →',
                      style: TextStyle(
                          color: c.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Real-time updates and suggestions for you',
              style: TextStyle(color: c.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          // Feed list
          ...feedItems.map((item) => _FeedTile(item: item, c: c)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  List<_FeedItem> _buildFeedItems(List<String> insights) {
    final icons = [
      _FeedItem(
        icon: Icons.trending_up,
        color: Colors.greenAccent,
        title: 'Your video is gaining traction!',
        subtitle: 'Viewers are watching 35% more.',
        time: '2m ago',
        type: _FeedType.success,
      ),
      _FeedItem(
        icon: Icons.warning_amber_rounded,
        color: Colors.orangeAccent,
        title: 'Retention drop at 7 sec',
        subtitle: 'Improve your hook to increase watch time.',
        time: '5m ago',
        type: _FeedType.warning,
      ),
      _FeedItem(
        icon: Icons.local_fire_department,
        color: Colors.redAccent,
        title: '"Feel good movies" is trending again!',
        subtitle: 'Create similar content for better reach.',
        time: '12m ago',
        type: _FeedType.trend,
      ),
      _FeedItem(
        icon: Icons.access_time_filled,
        color: Colors.blueAccent,
        title: 'Best time to post: 6:30 PM – 8:30 PM',
        subtitle: 'Your audience is most active during this time.',
        time: '15m ago',
        type: _FeedType.info,
      ),
    ];

    // Override with real insights if available
    if (insights.isNotEmpty && insights.first != 'Analyzing your channel performance...') {
      return insights.take(4).toList().asMap().entries.map((e) {
        final base = icons[e.key % icons.length];
        return _FeedItem(
          icon: base.icon,
          color: base.color,
          title: e.value.length > 50 ? '${e.value.substring(0, 50)}...' : e.value,
          subtitle: '',
          time: '${(e.key + 1) * 2}m ago',
          type: base.type,
        );
      }).toList();
    }

    return icons;
  }
}

enum _FeedType { success, warning, trend, info }

class _FeedItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final _FeedType type;

  const _FeedItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
  });
}

class _FeedTile extends StatelessWidget {
  final _FeedItem item;
  final AppColors c;

  const _FeedTile({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.subtitle,
                        style: TextStyle(
                            color: c.textSecondary, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(item.time,
                style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
