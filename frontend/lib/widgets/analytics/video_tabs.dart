import 'package:flutter/material.dart';
import '../../screens/video_detail_screen.dart';

class VideoTabs extends StatelessWidget {
  final List<dynamic> videos;
  const VideoTabs({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            isScrollable: true,
            indicatorColor: Colors.deepPurpleAccent,
            labelColor: Colors.deepPurpleAccent,
            unselectedLabelColor: Colors.grey,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Latest'),
              Tab(text: 'Popular'),
              Tab(text: 'Old'),
              Tab(text: 'Scheduled'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: TabBarView(
              children: [
                _buildVideoList(context, videos),
                _buildVideoList(context, _sortByPopular(videos)),
                _buildVideoList(context, _sortByOldest(videos)),
                _buildScheduledEmpty(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sort helpers ──────────────────────────────────────────────────────────
  List<dynamic> _sortByPopular(List<dynamic> list) {
    final s = List<dynamic>.from(list);
    s.sort((a, b) {
      final av = (a['viewsNum'] as num? ?? 0).toInt();
      final bv = (b['viewsNum'] as num? ?? 0).toInt();
      return bv.compareTo(av);
    });
    return s;
  }

  List<dynamic> _sortByOldest(List<dynamic> list) {
    final s = List<dynamic>.from(list);
    s.sort((a, b) {
      final ad = DateTime.tryParse(a['publishedAt']?.toString() ?? '') ?? DateTime.now();
      final bd = DateTime.tryParse(b['publishedAt']?.toString() ?? '') ?? DateTime.now();
      return ad.compareTo(bd);
    });
    return s;
  }

  // ── Age formatter ─────────────────────────────────────────────────────────
  String _age(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays >= 30)  return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays >= 1)   return '${diff.inDays}d ago';
      if (diff.inHours >= 1)  return '${diff.inHours}h ago';
      return 'Recently';
    } catch (_) { return ''; }
  }

  Color _platformColor(String p) {
    switch (p.toLowerCase()) {
      case 'youtube':   return Colors.red;
      case 'instagram': return const Color(0xFFE1306C);
      case 'linkedin':  return const Color(0xFF0A66C2);
      default:          return Colors.grey;
    }
  }

  // ── Empty scheduled state ─────────────────────────────────────────────────
  Widget _buildScheduledEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, size: 46,
              color: theme.colorScheme.onSurface.withOpacity(0.25)),
          const SizedBox(height: 12),
          Text('No scheduled videos',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                  fontSize: 14)),
        ],
      ),
    );
  }

  // ── Video list ─────────────────────────────────────────────────────────────
  Widget _buildVideoList(BuildContext context, List<dynamic> list) {
    final theme = Theme.of(context);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, size: 42,
                color: theme.colorScheme.onSurface.withOpacity(0.25)),
            const SizedBox(height: 12),
            Text('No videos found',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.45))),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final v = list[i] as Map<String, dynamic>;
        final thumb    = v['thumbnail']?.toString() ?? '';
        final title    = v['title']?.toString() ?? 'Untitled';
        final views    = v['views']?.toString() ?? '—';
        final likes    = v['likes']?.toString() ?? '—';
        final platform = v['platform']?.toString() ?? '';
        final ageStr   = _age(v['publishedAt']?.toString());
        final pColor   = _platformColor(platform);

        return InkWell(
          onTap: () {
            final id = v['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => VideoDetailScreen(videoId: id),
              ));
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail + platform badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: thumb.isNotEmpty
                          ? Image.network(thumb,
                              width: 118, height: 68, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbBox(pColor))
                          : _thumbBox(pColor),
                    ),
                    Positioned(
                      bottom: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: pColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          platform.isNotEmpty ? platform.substring(0, 2).toUpperCase() : 'YT',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600, fontSize: 13, height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (ageStr.isNotEmpty)
                        Text(ageStr,
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withOpacity(0.45))),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _statChip(context, Icons.bar_chart, views),
                          const SizedBox(width: 10),
                          _statChip(context, Icons.thumb_up_alt_outlined, likes),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.25)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.45)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }

  Widget _thumbBox(Color color) => Container(
    width: 118, height: 68,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.play_circle_outline, color: color.withOpacity(0.55), size: 26),
  );
}
