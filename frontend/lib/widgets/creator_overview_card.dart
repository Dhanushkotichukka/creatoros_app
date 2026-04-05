import 'package:flutter/material.dart';

class CreatorOverviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic>? platforms;
  final VoidCallback? onPostRequested;

  const CreatorOverviewCard({super.key, required this.data, this.platforms, this.onPostRequested});

  @override
  Widget build(BuildContext context) {
    // Try to get real channel name and avatar from the first connected platform
    String? avatarUrl;
    String channelName = 'Creator';
    if (platforms != null) {
      final connected = platforms!.where((p) => p['isConnected'] == true).toList();
      if (connected.isNotEmpty) {
        avatarUrl = connected.first['channelAvatar'] as String?;
        channelName = (connected.first['channelName'] as String?) ?? 'Creator';
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? theme.cardColor : Colors.white,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Icon(Icons.person, color: theme.colorScheme.primary, size: 28)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: theme.textTheme.bodySmall),
                        Text(
                          channelName,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${data['totalViews'] ?? '0'} Views',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 24),
                    ),
                    Text('Total Reach', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${data['streak'] ?? '0'} Day Streak',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Text(
                    '↑${data['growth'] ?? '+0%'} from last month',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPostRequested,
                    icon: const Icon(Icons.video_call, size: 18),
                    label: const Text('Create Reel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPostRequested,
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Upload Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
