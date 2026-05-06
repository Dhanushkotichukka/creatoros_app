import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import 'transcript_modal.dart';

/// Reusable premium video card used across My AI and Master AI sections.
/// Displays a large banner thumbnail or compact row with source badge, trend score, 
/// meta info, and action buttons.
class VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;
  final bool isSelected;
  final bool showSelection;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onViewScript;
  final VoidCallback? onGenerateScript;
  final bool isCompact;

  const VideoCard({
    super.key,
    required this.video,
    this.isSelected = false,
    this.showSelection = false,
    this.onToggleSelect,
    this.onViewScript,
    this.onGenerateScript,
    this.isCompact = false,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _elevationAnim =
        Tween<double>(begin: 0, end: 1).animate(_hoverController);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool h) {
    setState(() => _hovered = h);
    if (h) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  Color get _sourceColor {
    final src = widget.video['source'] ?? '';
    if (src == 'YouTube') return Colors.red;
    if (src == 'Google Trends') return const Color(0xFF1A73E8);
    return Colors.purple;
  }

  IconData get _sourceIcon {
    final src = widget.video['source'] ?? '';
    if (src == 'YouTube') return Icons.play_circle_filled;
    if (src == 'Google Trends') return Icons.trending_up;
    return Icons.article;
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final thumbnail = widget.video['thumbnail'] as String?;
    final title = widget.video['title'] ?? 'Untitled';
    final source = widget.video['source'] ?? 'Unknown';
    final views = widget.video['viewsFormatted'] ?? widget.video['views']?.toString() ?? '';
    final ago = widget.video['timeAgo'] ?? '';
    final url = widget.video['url'] as String?;
    final score = (widget.video['trendScore'] ?? 0) as num;
    final scoreInt = score.toInt();
    final scoreClr = _scoreColor(scoreInt);
    final channelName = widget.video['channelName'] as String?;
    final videoId = widget.video['videoId'] as String?;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _elevationAnim,
        builder: (context, child) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? c.primary
                  : _hovered
                      ? c.primary.withOpacity(0.4)
                      : c.border,
              width: widget.isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06 + _elevationAnim.value * 0.06),
                blurRadius: 16 + _elevationAnim.value * 12,
                offset: Offset(0, 4 + _elevationAnim.value * 4),
              ),
              if (widget.isSelected)
                BoxShadow(
                  color: c.primary.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: widget.isCompact 
              ? _buildCompactLayout(thumbnail, title, source, views, ago, scoreInt, scoreClr, c, channelName, videoId, url)
              : _buildBannerLayout(thumbnail, title, source, views, ago, scoreInt, scoreClr, c, channelName, videoId, url),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerLayout(String? thumbnail, String title, String source, String views, String ago, int scoreInt, Color scoreClr, AppColors c, String? channelName, String? videoId, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThumbnail(thumbnail, source, scoreInt, scoreClr, c),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoreInfo(channelName, title, views, ago, c),
              const SizedBox(height: 16),
              _buildActions(videoId, url: url, c: c),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(String? thumbnail, String title, String source, String views, String ago, int scoreInt, Color scoreClr, AppColors c, String? channelName, String? videoId, String? url) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: c.background,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumbnail != null
                      ? Image.network(thumbnail, fit: BoxFit.cover)
                      : _thumbPlaceholder(source, c),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _scoreColor(scoreInt).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$scoreInt',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoreInfo(channelName, title, views, ago, c),
                const SizedBox(height: 12),
                _buildActions(videoId, url: url, c: c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreInfo(String? channelName, String title, String views, String ago, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (channelName != null && channelName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              channelName,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.primary, letterSpacing: 0.5),
            ),
          ),
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.textPrimary, height: 1.2),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (views.isNotEmpty) ...[
              Icon(Icons.visibility_outlined, size: 12, color: c.textSecondary),
              const SizedBox(width: 4),
              Text(views, style: TextStyle(fontSize: 11, color: c.textSecondary)),
              const SizedBox(width: 10),
            ],
            if (ago.isNotEmpty) ...[
              Icon(Icons.access_time, size: 12, color: c.textSecondary),
              const SizedBox(width: 4),
              Text(ago, style: TextStyle(fontSize: 11, color: c.textSecondary)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail(String? thumbnail, String source, int score, Color scoreClr, AppColors c) {
    return Stack(
      children: [
        if (thumbnail != null)
          Image.network(
            thumbnail,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbPlaceholder(source, c),
          )
        else
          _thumbPlaceholder(source, c),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreClr.withOpacity(0.5), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: scoreClr, size: 13),
                const SizedBox(width: 4),
                Text('$score', style: TextStyle(color: scoreClr, fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
          ),
        ),
        if (widget.showSelection)
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: widget.onToggleSelect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: widget.isSelected ? c.primary : Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: widget.isSelected ? c.primary : Colors.white54, width: 2),
                ),
                child: widget.isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(String? videoId, {required String? url, required AppColors c}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSourceBadge(c),
        if (url != null)
          _actionButton(
            icon: Icons.play_circle_outline,
            label: widget.isCompact ? 'Watch' : 'Watch Video',
            color: Colors.red,
            onTap: () => _openUrl(url),
          ),
        if (videoId != null)
          _actionButton(
            icon: Icons.article_outlined,
            label: widget.isCompact ? 'Transcript' : 'View Script',
            color: Colors.blue,
            onTap: widget.onViewScript,
          ),
        _actionButton(
          icon: Icons.auto_awesome,
          label: widget.isCompact ? 'Script' : 'Generate Script',
          color: c.primary,
          onTap: widget.onGenerateScript,
          filled: true,
        ),
      ],
    );
  }

  Widget _buildSourceBadge(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _sourceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_sourceIcon, size: 10, color: _sourceColor),
          const SizedBox(width: 4),
          Text(
            widget.video['source'] ?? 'Source',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _sourceColor),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool filled = false,
  }) {
    final double paddingH = widget.isCompact ? 8 : 12;
    final double paddingV = widget.isCompact ? 6 : 9;

    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 13),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        style: FilledButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _thumbPlaceholder(String source, AppColors c) {
    final color = _sourceColor;
    return Container(
      width: double.infinity,
      height: widget.isCompact ? 80 : 200,
      color: color.withOpacity(0.08),
      child: Icon(Icons.video_library, color: color.withOpacity(0.2), size: 40),
    );
  }
}
