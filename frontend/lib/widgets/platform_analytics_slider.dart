import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/view_state_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class PlatformAnalyticsSlider extends StatelessWidget {
  final List<dynamic> platforms;
  const PlatformAnalyticsSlider({super.key, required this.platforms});

  IconData _iconFor(String name) {
    switch (name.toLowerCase()) {
      case 'youtube': return Icons.play_circle_fill;
      case 'instagram': return Icons.camera_alt;
      case 'linkedin': return Icons.business;
      case 'facebook': return Icons.facebook;
      default: return Icons.public;
    }
  }

  Color _colorFor(String name) {
    switch (name.toLowerCase()) {
      case 'youtube': return const Color(0xFFFF0000);
      case 'instagram': return const Color(0xFFE1306C);
      case 'linkedin': return const Color(0xFF0A66C2);
      case 'facebook': return const Color(0xFF1877F2);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: platforms.length + 1,
        itemBuilder: (context, index) {
          if (index == platforms.length) return const _AddPlatformCard();
          final p = platforms[index];
          final name = p['name'] as String? ?? 'Unknown';
          final color = _colorFor(name);

          if (p['isConnected'] == false) {
            return _ConnectCard(name: name, icon: _iconFor(name), color: color);
          }

          final views = (p['views'] ?? p['reach'] ?? '0') as String;
          final sub = p['subscribers'] != null ? '${p['subscribers']} Subscribers' :
                      (p['followers'] != null ? '${p['followers']} Followers' : '');
          return _PlatformCard(
            name: name, views: views, subText: sub,
            icon: _iconFor(name), color: color,
            avatarUrl: p['channelAvatar'] as String?,
            accountName: p['channelName'] as String?,
          );
        },
      ),
    );
  }
}

// ─── CONNECTED PLATFORM CARD ─────────────────────────────────────────
class _PlatformCard extends StatefulWidget {
  final String name, views, subText;
  final IconData icon;
  final Color color;
  final String? avatarUrl, accountName;

  const _PlatformCard({
    required this.name, required this.views, required this.subText,
    required this.icon, required this.color, this.avatarUrl, this.accountName,
  });

  @override
  State<_PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends State<_PlatformCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final viewState = context.read<ViewStateProvider>();
    return MouseRegion(
      onEnter: (_) { setState(() => _hovered = true); _ctrl.forward(); },
      onExit: (_) { setState(() => _hovered = false); _ctrl.reverse(); },
      child: InkWell(
        onTap: () => viewState.jumpToAnalytics(widget.name),
        borderRadius: BorderRadius.circular(16),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered ? widget.color.withOpacity(0.6) : c.border,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered ? widget.color.withOpacity(0.2) : Colors.black.withOpacity(0.08),
                  blurRadius: _hovered ? 20 : 8,
                  spreadRadius: _hovered ? 1 : 0,
                  offset: const Offset(0, 2),
                ),
              ],
              gradient: LinearGradient(
                colors: [widget.color.withOpacity(_hovered ? 0.08 : 0.04), Colors.transparent],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (widget.avatarUrl != null)
                    CircleAvatar(radius: 10, backgroundImage: NetworkImage(widget.avatarUrl!))
                  else
                    Icon(widget.icon, color: widget.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.accountName ?? widget.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c.textPrimary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ]),
                const Spacer(),
                Text(
                  widget.views,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary),
                ),
                Text(widget.subText, style: TextStyle(fontSize: 10, color: c.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CONNECT CARD ─────────────────────────────────────────────────────
class _ConnectCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  const _ConnectCard({required this.name, required this.icon, required this.color});

  @override
  State<_ConnectCard> createState() => _ConnectCardState();
}

class _ConnectCardState extends State<_ConnectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? widget.color.withOpacity(0.5) : c.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered ? [BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 2))] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: _hovered ? widget.color : Colors.grey, size: 22),
            const SizedBox(height: 6),
            Text(
              'Connect ${widget.name}',
              style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 11,
                color: _hovered ? widget.color : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.name == 'YouTube')   ApiService.loginWithYouTube();
                  if (widget.name == 'Instagram') ApiService.loginWithMeta();
                  if (widget.name == 'LinkedIn')  ApiService.loginWithLinkedIn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color.withOpacity(0.15),
                  foregroundColor: widget.color,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(80, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ADD PLATFORM CARD ────────────────────────────────────────────────
class _AddPlatformCard extends StatefulWidget {
  const _AddPlatformCard();

  @override
  State<_AddPlatformCard> createState() => _AddPlatformCardState();
}

class _AddPlatformCardState extends State<_AddPlatformCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final viewState = context.read<ViewStateProvider>();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: () => viewState.setShowConnectView(true),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _hovered ? c.primary.withOpacity(0.5) : c.border, width: _hovered ? 1.5 : 1),
            color: _hovered ? c.primary.withOpacity(0.05) : c.secondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: _hovered ? c.primary : Colors.grey),
              const SizedBox(height: 5),
              Text('Add Platform', style: TextStyle(fontSize: 12, color: _hovered ? c.primary : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
