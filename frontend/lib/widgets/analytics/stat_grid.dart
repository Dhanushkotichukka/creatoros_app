import 'package:flutter/material.dart';

class StatGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const StatGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Helper: parse a growth string like '+12.5%' → double
    bool _pos(String? g) => g != null && !g.startsWith('-');
    String _trend(String? g) => g?.isNotEmpty == true ? g! : '—';

    final growthViews = data['growth']?.toString();
    final growthSubs  = data['growthSubs']?.toString();
    final growthLikes = data['growthLikes']?.toString();
    final growthWatch = data['growthWatch']?.toString();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: StatCard(
              title: 'Total Views',
              value: data['totalViews']?.toString() ?? '0',
              trend: _trend(growthViews),
              isPositive: _pos(growthViews),
              icon: Icons.remove_red_eye_outlined,
              bgColor: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: StatCard(
              title: 'Followers',
              value: data['totalSubscribers']?.toString() ?? '0',
              trend: _trend(growthSubs),
              isPositive: _pos(growthSubs),
              icon: Icons.people_outline,
              bgColor: const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: StatCard(
              title: 'Total Likes',
              value: data['totalLikes']?.toString() ?? '—',
              trend: _trend(growthLikes),
              isPositive: _pos(growthLikes),
              icon: Icons.favorite_border,
              bgColor: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: StatCard(
              title: 'Watch Time',
              value: data['totalWatchTime']?.toString() ?? '0',
              trend: _trend(growthWatch),
              isPositive: _pos(growthWatch),
              icon: Icons.timer_outlined,
              bgColor: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  final IconData icon;
  final Color bgColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
    required this.icon,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final w      = MediaQuery.of(context).size.width;
    // Card width ≈ (screenWidth - sidebar - padding) / 3
    // On mobile (≈390px) each card is ~110px wide — use compact sizing
    final bool compact = w < 700;
    final color  = isPositive ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 18,
          vertical:   compact ? 12 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: compact ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: compact ? 13 : 17, color: bgColor),
                ),
              ],
            ),

            SizedBox(height: compact ? 8 : 12),

            // Value
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 18 : 26,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),

            SizedBox(height: compact ? 8 : 12),

            // Trend badge + label
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 10,
                          color: color,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            trend,
                            style: TextStyle(
                              color: color,
                              fontSize: compact ? 9 : 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'vs last month',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: compact ? 8 : 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
