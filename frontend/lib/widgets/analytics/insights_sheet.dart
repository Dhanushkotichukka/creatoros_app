import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Premium AI Insights bottom sheet.
/// Shows 4 insight cards: Performance, Hook & Retention, Strategy, Best Time.
/// Handles loading (shimmer), error (retry), and populated states.
/// [platform] — if provided, shows platform-specific header (e.g. "YouTube").
class InsightsSheet extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? platform;

  const InsightsSheet({
    super.key,
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.platform,
  });

  // ── Card accent colors ───────────────────────────────────────────────
  static Color _scoreColor(String? key) {
    switch (key) {
      case 'green':  return const Color(0xFF22C55E);
      case 'orange': return const Color(0xFFF97316);
      case 'red':    return const Color(0xFFEF4444);
      case 'blue':   return const Color(0xFF06B6D4);
      default:       return const Color(0xFF8B5CF6);
    }
  }

  // ── Timestamp formatter ──────────────────────────────────────────────
  static String _formatTime(String? iso) {
    if (iso == null) return 'just now';
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c     = theme.extension<AppColors>()!;
    final mq    = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.88),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ─────────────────────────────────────────────────
          _SheetHeader(data: data, platform: platform),

          const SizedBox(height: 4),

          // ── Scrollable body ─────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: _buildBody(context, c, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppColors c, ThemeData theme) {
    // Loading state — shimmer skeletons
    if (isLoading) return _ShimmerBody(c: c);

    // Error state — retry card
    if (errorMessage != null) {
      return _ErrorCard(message: errorMessage!, onRetry: onRetry, c: c, theme: theme);
    }

    // No data
    if (data == null) return const SizedBox();

    final cards  = data!['cards'] as Map<String, dynamic>? ?? {};
    final window = data!['dataWindow'] as String? ?? 'Last 28 Days (All Platforms)';

    final cardList = [
      _cardConfig('performance', cards),
      _cardConfig('hooks',       cards),
      _cardConfig('strategy',    cards),
      _cardConfig('timing',      cards),
    ].whereType<Map<String, dynamic>>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data window badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
          ),
          child: Text(
            '📊 $window',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF8B5CF6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        ...cardList.map((cfg) => _InsightCard(config: cfg)).toList(),
      ],
    );
  }

  Map<String, dynamic>? _cardConfig(String key, Map<String, dynamic> cards) {
    final card = cards[key];
    if (card == null) return null;
    return Map<String, dynamic>.from(card as Map);
  }
}

// ── Sheet Header ─────────────────────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String? platform;
  const _SheetHeader({this.data, this.platform});

  String _platformLabel(String p) {
    if (p.toLowerCase() == 'youtube') return 'YouTube';
    if (p.toLowerCase() == 'instagram') return 'Instagram';
    if (p.toLowerCase() == 'linkedin') return 'LinkedIn';
    return p[0].toUpperCase() + p.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c     = theme.extension<AppColors>()!;
    final ts    = InsightsSheet._formatTime(data?['generatedAt'] as String?);
    final isAI  = data?['aiPowered'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Gradient brain icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.35),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform != null
                      ? '🧠 ${_platformLabel(platform!)} Insights'
                      : '🧠 AI Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isAI) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          platform != null ? '${_platformLabel(platform!)} · AI ✨' : 'AI Powered ✨',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      'Generated $ts',
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: Icon(Icons.close, color: c.textSecondary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ── Single Insight Card ───────────────────────────────────────────────────────
class _InsightCard extends StatefulWidget {
  final Map<String, dynamic> config;
  const _InsightCard({required this.config});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final c      = theme.extension<AppColors>()!;
    final cfg    = widget.config;
    final accent = InsightsSheet._scoreColor(cfg['scoreColor'] as String?);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accent bar at top
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(0.3)],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card title row
                      Row(
                        children: [
                          Text(
                            cfg['emoji'] as String? ?? '📊',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cfg['title'] as String? ?? '',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          // Score dot
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: accent.withOpacity(0.5), blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Status label (rule-engine signal)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cfg['statusLabel'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // AI narrative
                      Text(
                        cfg['narrative'] as String? ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: c.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action chip
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cfg['actionLabel'] as String? ?? 'Learn more',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 10, color: accent),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer Skeleton Loading ──────────────────────────────────────────────────
class _ShimmerBody extends StatefulWidget {
  final AppColors c;
  const _ShimmerBody({required this.c});

  @override
  State<_ShimmerBody> createState() => _ShimmerBodyState();
}

class _ShimmerBodyState extends State<_ShimmerBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 0.6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmerColor = Color.lerp(
          const Color(0xFF1E1E1E),
          const Color(0xFF2E2E2E),
          _anim.value,
        )!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge skeleton
            Container(
              height: 28, width: 220,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(14)),
            ),
            // 4 card skeletons with inner content lines
            ...List.generate(4, (i) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title line
                  Container(height: 16, width: 150, decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  // Status badge
                  Container(height: 28, width: 120, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  // Narrative lines
                  Container(height: 12, decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: double.infinity * 0.7, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 180, decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 16),
                  // Action button
                  Align(alignment: Alignment.centerRight, child:
                    Container(height: 30, width: 100, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(20)))),
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final AppColors c;
  final ThemeData theme;

  const _ErrorCard({
    required this.message,
    required this.c,
    required this.theme,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 36),
          const SizedBox(height: 12),
          Text(
            'Could not load insights',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
