import 'package:flutter/material.dart';

class ContentSection extends StatelessWidget {
  final String platform;
  final List<dynamic>? contentList; // All videos for this platform, sorted by latest
  const ContentSection({super.key, required this.platform, this.contentList});

  String _formatTimeAgo(String? isoDateStr) {
    if (isoDateStr == null) return 'Just now';
    try {
      final date = DateTime.parse(isoDateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
      if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
      return 'Just now';
    } catch (_) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort by publishedAt descending to find the actual LATEST video
    List<dynamic> sorted = [];
    if (contentList != null && contentList!.isNotEmpty) {
      sorted = List.from(contentList!);
      sorted.sort((a, b) {
        final aDate = DateTime.tryParse(a['publishedAt']?.toString() ?? '') ?? DateTime(0);
        final bDate = DateTime.tryParse(b['publishedAt']?.toString() ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
    }

    final latestVideo = sorted.isNotEmpty ? sorted.first : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: latestVideo != null && latestVideo['thumbnail'] != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          latestVideo['thumbnail'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: Icon(
                                platform == 'YouTube' ? Icons.play_circle_outline : Icons.image_outlined,
                                color: Colors.grey,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: platform == 'YouTube' ? Colors.red : Colors.pinkAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              latestVideo['type']?.toString().toUpperCase() ?? platform.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            platform == 'YouTube' ? Icons.play_circle_fill : Icons.play_arrow_rounded,
                            color: Colors.white70,
                            size: 48,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(
                          platform == 'YouTube' ? Icons.play_circle_outline : Icons.camera_alt_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  latestVideo != null ? (latestVideo['title'] ?? 'Untitled') : 'No recent $platform content found',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      latestVideo != null
                          ? '${latestVideo['views'] ?? '0'} Views • ${_formatTimeAgo(latestVideo['publishedAt']?.toString())}'
                          : '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (latestVideo != null)
                      Row(
                        children: [
                          const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            latestVideo['likes']?.toString() ?? '0',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.comment_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            latestVideo['comments']?.toString() ?? '0',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
