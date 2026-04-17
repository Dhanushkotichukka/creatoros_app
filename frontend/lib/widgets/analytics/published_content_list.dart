import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../screens/video_detail_screen.dart';

/// YouTube-Studio-style expandable content list with real-time data.
class PublishedContentList extends StatefulWidget {
  final List<dynamic> topContent;
  final List<dynamic> platforms;

  const PublishedContentList({
    super.key,
    required this.topContent,
    required this.platforms,
  });

  @override
  State<PublishedContentList> createState() => _PublishedContentListState();
}

class _PublishedContentListState extends State<PublishedContentList> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    if (widget.topContent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Center(
          child: Text(
            'No published content yet.\nConnect your platforms to see content.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(widget.topContent.length, (index) {
        final item = widget.topContent[index] as Map<String, dynamic>;
        final isOpen = _expanded.contains(index);
        return _ContentAccordion(
          item: item,
          isOpen: isOpen,
          onToggle: () => setState(() {
            if (isOpen) _expanded.remove(index); else _expanded.add(index);
          }),
        );
      }),
    );
  }
}

class _ContentAccordion extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isOpen;
  final VoidCallback onToggle;

  const _ContentAccordion({
    required this.item,
    required this.isOpen,
    required this.onToggle,
  });

  Color _platformColor(String? platform) {
    switch ((platform ?? '').toLowerCase()) {
      case 'youtube':   return Colors.red;
      case 'instagram': return Color(0xFFE1306C);
      case 'linkedin':  return Colors.blue;
      default:          return Colors.grey;
    }
  }

  IconData _platformIcon(String? platform) {
    switch ((platform ?? '').toLowerCase()) {
      case 'youtube':   return Icons.play_circle_fill;
      case 'instagram': return Icons.camera_alt;
      case 'linkedin':  return Icons.business;
      default:          return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c       = Theme.of(context).extension<AppColors>()!;
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;

    final platform  = item['platform'] as String?;
    final title     = item['title']?.toString() ?? 'Untitled';
    final views     = item['views']?.toString() ?? '0';
    final likes     = item['likes']?.toString() ?? '0';
    final comments  = item['comments']?.toString() ?? '0';
    final thumbnail = item['thumbnail']?.toString();
    final engagement = item['engagement']?.toString() ?? '—';
    final id        = item['id'] ?? '';

    // Age label — e.g. "3 days ago" or we can show "Published" as fallback
    final publishedAt = item['publishedAt'] as String?;
    final ageLabel = publishedAt != null ? _formatAge(publishedAt) : 'Published';

    final pColor = _platformColor(platform);
    final pIcon  = _platformIcon(platform);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          // ── Header row (always visible) ─────────────────────────────────
          InkWell(
            onTap: () {
              if (id.isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => VideoDetailScreen(videoId: id),
                ));
              }
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumbnail != null
                        ? Image.network(
                            thumbnail,
                            width: 88, height: 52, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _thumbPlaceholder(pColor),
                          )
                        : _thumbPlaceholder(pColor),
                  ),
                  const SizedBox(width: 12),
                  // Title + age
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(pIcon, size: 12, color: pColor),
                            const SizedBox(width: 4),
                            Text(
                              ageLabel,
                              style: TextStyle(color: c.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats bar + toggle ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _StatChip(icon: Icons.bar_chart, value: views.toString(), color: c.textSecondary),
                  const SizedBox(width: 16),
                  _StatChip(icon: Icons.thumb_up_outlined, value: likes.toString(), color: c.textSecondary),
                  const SizedBox(width: 16),
                  _StatChip(icon: Icons.comment_outlined, value: comments.toString(), color: c.textSecondary),
                  const Spacer(),
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down, color: c.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail panel ────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Views', value: views.toString(), status: 'neutral'),
                  _DetailRow(label: 'Avg. engagement rate', value: engagement.toString(), status: 'good'),
                  _DetailRow(label: 'Likes', value: likes.toString(), status: 'good'),
                  _DetailRow(label: 'Comments', value: comments.toString(), status: comments == '0' ? 'neutral' : 'good'),
                  if (comments == '0') ...[
                    const SizedBox(height: 4),
                    Text(
                      'No comments yet',
                      style: TextStyle(color: c.textSecondary, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // View full details button
                  if (id.isNotEmpty)
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VideoDetailScreen(videoId: id)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'View full analytics',
                        style: TextStyle(color: c.textPrimary, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder(Color color) => Container(
    width: 88, height: 52,
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.movie, color: color, size: 24),
  );

  String _formatAge(String iso) {
    try {
      final dt   = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} month(s) ago';
      if (diff.inDays >= 1)  return '${diff.inDays} day(s) ago';
      if (diff.inHours >= 1) return '${diff.inHours} hour(s) ago';
      return 'Recently';
    } catch (_) {
      return 'Published';
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String status; // 'good' | 'neutral' | 'bad'

  const _DetailRow({required this.label, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    final c     = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    Widget statusBadge() {
      if (status == 'good')    return Icon(Icons.check_circle, color: Colors.green,    size: 16);
      if (status == 'bad')     return Icon(Icons.arrow_downward, color: Colors.red,    size: 16);
      return Icon(Icons.remove, color: c.textSecondary, size: 16);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: c.textPrimary)),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary),
          ),
          const SizedBox(width: 8),
          statusBadge(),
        ],
      ),
    );
  }
}
