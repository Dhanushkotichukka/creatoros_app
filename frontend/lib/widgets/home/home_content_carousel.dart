import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../screens/content_detail_screen.dart';

class HomeContentCarousel extends StatelessWidget {
  final String platformName;
  final List<dynamic> content;
  final Color platformColor;

  const HomeContentCarousel({
    super.key,
    required this.platformName,
    required this.content,
    required this.platformColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    if (content.isEmpty) {
      return _EmptyCarousel(platformName: platformName, c: c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: platformColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Latest $platformName Content',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContentDetailScreen(
                      platformName: platformName,
                      content: content,
                      platformColor: platformColor,
                    ),
                  ),
                ),
                child: Text(
                  'View all →',
                  style: TextStyle(
                    color: platformColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Single Latest Post ─────────────────────────────────────────
        SizedBox(
          height: 200,
          child: _ContentCard(
            item: content.first,
            platformColor: platformColor,
            c: c,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContentDetailScreen(
                  platformName: platformName,
                  content: content,
                  platformColor: platformColor,
                  initialIndex: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatefulWidget {
  final dynamic item;
  final Color platformColor;
  final AppColors c;
  final VoidCallback onTap;

  const _ContentCard({
    required this.item,
    required this.platformColor,
    required this.c,
    required this.onTap,
  });

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final c = widget.c;
    final thumbnail = item['thumbnail'] as String? ?? '';
    final title = item['title'] as String? ?? 'Untitled';
    final views = item['views'] as String? ?? '0';
    final likes = item['likes'] as String? ?? '0';
    final comments = item['comments'] as String? ?? '0';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? widget.platformColor.withOpacity(0.5)
                  : c.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.platformColor.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: thumbnail.isNotEmpty
                    ? Image.network(
                        thumbnail,
                        height: 105,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 105,
                          color: c.border,
                          child: Icon(Icons.image_not_supported,
                              color: c.textSecondary),
                        ),
                      )
                    : Container(
                        height: 105,
                        color: c.border,
                        child: Icon(Icons.play_circle_outline,
                            color: c.textSecondary, size: 32),
                      ),
              ),

              // Content info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      // Stats row
                      Row(
                        children: [
                          _statChip(Icons.remove_red_eye, views, c),
                          const SizedBox(width: 8),
                          _statChip(Icons.thumb_up, likes, c),
                          const SizedBox(width: 8),
                          _statChip(Icons.comment, comments, c),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, AppColors c) {
    return Row(
      children: [
        Icon(icon, size: 10, color: c.textSecondary),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(color: c.textSecondary, fontSize: 10)),
      ],
    );
  }
}

class _EmptyCarousel extends StatelessWidget {
  final String platformName;
  final AppColors c;

  const _EmptyCarousel({required this.platformName, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Center(
        child: Text(
          'No $platformName content yet',
          style: TextStyle(color: c.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}
