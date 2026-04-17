import 'package:flutter/material.dart';

class StatGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const StatGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Views',
            value: data['totalViews']?.toString() ?? '0',
            trend: '+12.5%',
            isPositive: true,
            icon: Icons.remove_red_eye_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            title: 'Followers',
            value: data['subscribers']?.toString() ?? '0',
            trend: '+8.2%',
            isPositive: true,
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            title: 'Total Likes',
            value: data['totalLikes']?.toString() ?? '0',
            trend: '-2.4%',
            isPositive: false,
            icon: Icons.favorite_border,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
    required this.icon,
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
                      fontSize: compact ? 10 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(icon, size: compact ? 13 : 17, color: Colors.grey),
              ],
            ),

            SizedBox(height: compact ? 8 : 12),

            // Value
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: compact ? 18 : 26,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),

            SizedBox(height: compact ? 4 : 6),

            // Trend badge + label
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 4 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: color,
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 4 : 6),

            Text(
              'vs last month',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 9 : 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
