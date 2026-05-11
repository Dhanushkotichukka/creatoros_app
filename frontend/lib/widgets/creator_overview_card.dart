import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class CreatorOverviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic>? platforms;
  final VoidCallback? onCreateReelRequested;
  final VoidCallback? onUploadVideoRequested;

  const CreatorOverviewCard({
    super.key, 
    required this.data, 
    this.platforms, 
    this.onCreateReelRequested,
    this.onUploadVideoRequested,
  });

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
    final r = Responsive.of(context);

    return Card(
      elevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Container(
        padding: EdgeInsets.all(r.value(mobile: 16.0, tablet: 20.0, web: 24.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r.cardRadius + 8),
          color: isDark ? theme.cardColor : Colors.white,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back,', style: theme.textTheme.bodySmall),
                            Text(
                              channelName,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${data['totalViews'] ?? '0'} Views',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 22),
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
                    onPressed: onCreateReelRequested,
                    icon: const Icon(Icons.video_call, size: 18),
                    label: const Text('Create Reel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onUploadVideoRequested,
                      icon: Icon(Icons.upload, size: 18, color: theme.colorScheme.primary),
                      label: Text('Upload Video', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
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
