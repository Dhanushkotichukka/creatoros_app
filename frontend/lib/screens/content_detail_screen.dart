import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Full-page list of content for a given platform.
/// Reached by tapping a card in HomeContentCarousel.
class ContentDetailScreen extends StatelessWidget {
  final String platformName;
  final List<dynamic> content;
  final Color platformColor;
  final int initialIndex;

  const ContentDetailScreen({
    super.key,
    required this.platformName,
    required this.content,
    required this.platformColor,
    this.initialIndex = 0,
  });

  IconData get _platformIcon {
    switch (platformName.toLowerCase()) {
      case 'youtube': return Icons.play_circle_fill;
      case 'instagram': return Icons.camera_alt;
      case 'linkedin': return Icons.business;
      default: return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(_platformIcon, color: platformColor, size: 20),
          const SizedBox(width: 8),
          Text('$platformName Content',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        backgroundColor: c.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: c.border),
        ),
      ),
      backgroundColor: c.background,
      body: content.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: c.textSecondary),
                  const SizedBox(height: 12),
                  Text('No $platformName content yet',
                      style: TextStyle(color: c.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: content.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
              itemBuilder: (context, i) {
                final item = content[i];
                return _ContentListTile(
                  item: item,
                  platformColor: platformColor,
                  c: c,
                  isHighlighted: i == initialIndex,
                );
              },
            ),
    );
  }
}

class _ContentListTile extends StatelessWidget {
  final dynamic item;
  final Color platformColor;
  final AppColors c;
  final bool isHighlighted;

  const _ContentListTile({
    required this.item,
    required this.platformColor,
    required this.c,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnail = item['thumbnail'] as String? ?? '';
    final title = item['title'] as String? ?? 'Untitled';
    final views = item['views'] as String? ?? '0';
    final likes = item['likes'] as String? ?? '0';
    final comments = item['comments'] as String? ?? '0';
    final type = item['type'] as String? ?? 'video';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? platformColor.withOpacity(0.08)
            : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? platformColor.withOpacity(0.4) : c.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: thumbnail.isNotEmpty
                ? Image.network(thumbnail,
                    width: 90, height: 62, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(width: 90, height: 62, color: c.border,
                            child: Icon(Icons.image_not_supported, color: c.textSecondary)))
                : Container(width: 90, height: 62, color: c.border,
                    child: Icon(Icons.play_circle_outline, color: c.textSecondary, size: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: platformColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(type.toUpperCase(),
                        style: TextStyle(color: platformColor, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 10),
                Row(children: [
                  _stat(Icons.remove_red_eye, views, c),
                  const SizedBox(width: 14),
                  _stat(Icons.thumb_up_outlined, likes, c),
                  const SizedBox(width: 14),
                  _stat(Icons.chat_bubble_outline, comments, c),
                ]),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: c.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, AppColors c) {
    return Row(children: [
      Icon(icon, size: 13, color: c.textSecondary),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(color: c.textSecondary, fontSize: 12)),
    ]);
  }
}
