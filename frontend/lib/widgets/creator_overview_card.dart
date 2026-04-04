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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 26)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back,', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(
                          channelName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text('All Platforms', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange),
                    const SizedBox(width: 5),
                    Text(
                      '${data['streak'] ?? '0'} Day Streak',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '⬆${data['growth'] ?? '+0%'} from last month',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: onPostRequested,
                  icon: const Icon(Icons.video_call, size: 16),
                  label: const Text('Create Reel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onPostRequested,
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Upload Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.35),
                    foregroundColor: Colors.white,
                    elevation: 0,
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
