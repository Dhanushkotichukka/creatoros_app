import 'package:flutter/material.dart';

class StatGrid extends StatelessWidget {
  final Map<String, dynamic> data;

  const StatGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 2.2,
      children: [
        StatCard(
          title: 'Total Views',
          value: data['totalViews']?.toString() ?? '1.2M',
          trend: '+12.5%',
          isPositive: true,
          icon: Icons.remove_red_eye_outlined,
        ),
        StatCard(
          title: 'Active followers',
          value: data['subscribers']?.toString() ?? '27,064',
          trend: '+8.2%',
          isPositive: true,
          icon: Icons.people_outline,
        ),
        StatCard(
          title: 'Total likes',
          value: data['totalLikes']?.toString() ?? '16,568',
          trend: '-2.4%',
          isPositive: false,
          icon: Icons.favorite_border,
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
    final theme = Theme.of(context);
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.bodySmall),
                Icon(icon, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 28)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('vs last month', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
