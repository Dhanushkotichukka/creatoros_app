import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/app_colors.dart';
import '../services/api_service.dart';

/// Premium AI Insights Screen.
/// Shows insights with Confidence Levels, Why+Action format, Alerts, and History.
class InsightsScreen extends StatefulWidget {
  final String? platform;

  const InsightsScreen({super.key, this.platform});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _historicalData;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _fetchData();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'insight_history_${widget.platform ?? 'overview'}';
    final historyStr = prefs.getString(key);
    if (historyStr != null) {
      try {
        setState(() {
          _historicalData = jsonDecode(historyStr);
        });
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> _saveHistory(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'insight_history_${widget.platform ?? 'overview'}';
    
    // Save minimal summary for history
    final historyObj = {
      'date': DateTime.now().toIso8601String(),
      'summary': data['whatNext'] ?? [],
    };
    await prefs.setString(key, jsonEncode(historyObj));
  }

  Future<void> _fetchData({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (refresh) ApiService.clearInsightsCache();
      final data = await ApiService.getAIInsights(platform: widget.platform);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
        _saveHistory(data);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ── Card accent colors ───────────────────────────────────────────────
  static Color _scoreColor(String? key) {
    switch (key) {
      case 'green':
        return const Color(0xFF22C55E);
      case 'orange':
        return const Color(0xFFF97316);
      case 'red':
        return const Color(0xFFEF4444);
      case 'blue':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  // ── Timestamp formatter ──────────────────────────────────────────────
  static String _formatTime(String? iso) {
    if (iso == null) return 'just now';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return 'just now';
    }
  }

  String _platformLabel(String p) {
    if (p.toLowerCase() == 'youtube') return 'YouTube';
    if (p.toLowerCase() == 'instagram') return 'Instagram';
    if (p.toLowerCase() == 'linkedin') return 'LinkedIn';
    return p[0].toUpperCase() + p.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    
    final ts = _formatTime(_data?['generatedAt'] as String?);
    final isAI = _data?['aiPowered'] == true;
    final titleText = widget.platform != null
        ? '🧠 ${_platformLabel(widget.platform!)} Insights'
        : '🧠 AI Insights';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          titleText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_data != null)
            IconButton(
              icon: Icon(Icons.refresh, color: c.textSecondary, size: 20),
              tooltip: 'Refresh Insights',
              onPressed: () => _fetchData(refresh: true),
            ),
        ],
      ),
      body: _buildBody(context, c, theme),
    );
  }

  Widget _buildBody(BuildContext context, AppColors c, ThemeData theme) {
    // Loading state — shimmer skeletons
    if (_isLoading) return _ShimmerBody(c: c);

    // Error state — retry card
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _ErrorCard(
            message: _errorMessage!,
            onRetry: () {
              ApiService.clearInsightsCache();
              _fetchData();
            },
            c: c,
            theme: theme,
          ),
        ),
      );
    }

    // No data
    if (_data == null) return const SizedBox();

    final ts = _formatTime(_data?['generatedAt'] as String?);
    final isAI = _data?['aiPowered'] == true;

    final cards = _data!['cards'] as Map<String, dynamic>? ?? {};
    final window = _data!['dataWindow'] as String? ?? 'Last 28 Days (All Platforms)';
    final pe = _data!['patternEngine'] as Map<String, dynamic>? ?? {};

    final cardList = [
      _cardConfig('performance', cards),
      _cardConfig('hooks', cards),
      _cardConfig('winningPattern', cards),
      _cardConfig('strategy', cards),
      _cardConfig('timing', cards),
      _cardConfig('alerts', cards),
    ].whereType<Map<String, dynamic>>().toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                ),
                child: Text('📊 $window', style: const TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
              ),
              if (isAI) Text('Generated $ts ✨', style: TextStyle(fontSize: 11, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),

          // Scores bar
          if (pe['scores'] != null) _ScoresBar(scores: pe['scores'] as Map<String, dynamic>, c: c, theme: theme),

          // Winning Pattern
          if (pe['winning_pattern'] != null) _WinningPatternCard(data: pe['winning_pattern'] as Map<String, dynamic>, c: c, theme: theme),

          // Standard insight cards
          ...cardList.map((cfg) => _InsightCard(config: cfg, scoreColorResolver: _scoreColor)).toList(),

          // Top vs Low Analysis
          if (pe['top_vs_low_analysis'] != null) _TopVsLowCard(data: pe['top_vs_low_analysis'] as Map<String, dynamic>, c: c, theme: theme),

          // Performance Gap
          if (pe['performance_gap'] != null) _PerformanceGapCard(data: pe['performance_gap'] as Map<String, dynamic>, c: c, theme: theme),

          // Action Plan
          if (pe['action_plan'] != null) _ActionPlanCard(data: pe['action_plan'] as Map<String, dynamic>, c: c, theme: theme),

          // Avoid
          if (pe['avoid'] != null) _AvoidCard(avoidList: pe['avoid'] as List<dynamic>, c: c, theme: theme),

          // Next Video Plan
          if (pe['next_video_plan'] != null) _NextVideoPlanCard(data: pe['next_video_plan'] as Map<String, dynamic>, c: c, theme: theme),

          // Content Ideas
          if (pe['content_ideas'] != null) _ContentIdeasCard(ideas: pe['content_ideas'] as List<dynamic>, c: c, theme: theme),

          // What to do next
          if (_data!['whatNext'] != null) _SummaryCard(summaryList: _data!['whatNext'] as List<dynamic>),

          // History
          if (_historicalData != null) _HistorySection(history: _historicalData!),
        ],
      ),
    );
  }

  Map<String, dynamic>? _cardConfig(String key, Map<String, dynamic> cards) {
    final card = cards[key];
    if (card == null) return null;
    return Map<String, dynamic>.from(card as Map);
  }
}

// ── Single Insight Card ───────────────────────────────────────────────────────
class _InsightCard extends StatefulWidget {
  final Map<String, dynamic> config;
  final Color Function(String?) scoreColorResolver;

  const _InsightCard({required this.config, required this.scoreColorResolver});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
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
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    final cfg = widget.config;
    final accent = widget.scoreColorResolver(cfg['scoreColor'] as String?);
    
    final conf = cfg['confidence'] as String? ?? 'Low';
    final confColor = conf == 'High' ? Colors.green : (conf == 'Medium' ? Colors.orange : Colors.grey);
    
    final narrative = cfg['structuredNarrative'] as Map<String, dynamic>?;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cfg['scoreColor'] == 'red' ? accent.withOpacity(0.5) : c.border.withOpacity(0.6)),
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
                      // Card title & Confidence
                      Row(
                        children: [
                          Text(
                            cfg['emoji'] as String? ?? '📊',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cfg['title'] as String? ?? '',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          // Confidence Level
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(color: confColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Confidence: $conf',
                                  style: TextStyle(fontSize: 10, color: c.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Compare Text & Status
                      Row(
                        children: [
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
                          const Spacer(),
                          Text(
                            cfg['compareText'] as String? ?? '',
                            style: TextStyle(fontSize: 11, color: c.textSecondary),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Structured Narrative (Problem / Why / Action)
                      if (narrative != null) ...[
                        _buildNarrativeRow('Problem', narrative['problem'] ?? '', c, theme),
                        const SizedBox(height: 8),
                        _buildNarrativeRow('Why', narrative['why'] ?? '', c, theme),
                        const SizedBox(height: 8),
                        _buildNarrativeRow('Action', narrative['action'] ?? '', c, theme, isAction: true),
                      ] else ...[
                        Text(
                          cfg['narrative'] as String? ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: c.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Bottom Actions (Copy + Custom Action)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.copy, size: 16, color: c.textSecondary),
                            onPressed: () {
                              final textToCopy = narrative != null 
                                ? "Problem: ${narrative['problem']}\nWhy: ${narrative['why']}\nAction: ${narrative['action']}"
                                : (cfg['narrative'] ?? '');
                              Clipboard.setData(ClipboardData(text: textToCopy));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Insight copied to clipboard'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                          GestureDetector(
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
                        ],
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

  Widget _buildNarrativeRow(String label, String text, AppColors c, ThemeData theme, {bool isAction = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isAction ? const Color(0xFF06B6D4) : c.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isAction ? c.textPrimary : c.textSecondary.withOpacity(0.9),
              fontSize: 13,
              height: 1.4,
              fontWeight: isAction ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Summary Card (What to do next) ───────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final List<dynamic> summaryList;
  const _SummaryCard({required this.summaryList});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF8B5CF6).withOpacity(0.1), const Color(0xFF06B6D4).withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚀', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'What to do next',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...summaryList.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 10),
                  child: Icon(Icons.check_circle, size: 16, color: Color(0xFF06B6D4)),
                ),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── History Section ─────────────────────────────────────────────────────────
class _HistorySection extends StatelessWidget {
  final Map<String, dynamic> history;
  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    final dateStr = history['date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr).toLocal() : null;
    final summary = history['summary'] as List<dynamic>? ?? [];

    if (summary.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🕰️ Past Insights (${date?.month}/${date?.day})',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: summary.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $s', style: TextStyle(color: c.textSecondary, fontSize: 12)),
              )).toList(),
            ),
          )
        ],
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
  late final Animation<double> _anim;

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
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                height: 28, width: 220,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(14)),
              ),
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
                    Container(height: 16, width: 140, decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 12),
                    Container(height: 28, width: 110, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 12),
                    Container(height: 12, decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 200, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 160, decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 16),
                    Align(alignment: Alignment.centerRight, child:
                      Container(height: 30, width: 100, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(20)))),
                  ],
                ),
              )),
            ],
          ),
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
        mainAxisSize: MainAxisSize.min,
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

// ── Scores Bar ────────────────────────────────────────────────────────────────
class _ScoresBar extends StatelessWidget {
  final Map<String, dynamic> scores;
  final AppColors c;
  final ThemeData theme;
  const _ScoresBar({required this.scores, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Hook', 'val': scores['hook_score'] ?? 0, 'color': const Color(0xFFF97316)},
      {'label': 'Retention', 'val': scores['retention_score'] ?? 0, 'color': const Color(0xFF22C55E)},
      {'label': 'Growth', 'val': scores['growth_score'] ?? 0, 'color': const Color(0xFF8B5CF6)},
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Performance Scores', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: items.map<Widget>((item) {
              final val = (item['val'] as num).toInt();
              final color = item['color'] as Color;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(children: [
                  Text('$val', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                  Text('/100', style: TextStyle(fontSize: 10, color: c.textSecondary)),
                  const SizedBox(height: 4),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                    value: val / 100, minHeight: 6, color: color, backgroundColor: color.withOpacity(0.15),
                  )),
                  const SizedBox(height: 4),
                  Text(item['label'] as String, style: TextStyle(fontSize: 11, color: c.textSecondary, fontWeight: FontWeight.w600)),
                ]),
              ));
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Winning Pattern Card ──────────────────────────────────────────────────────
class _WinningPatternCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppColors c;
  final ThemeData theme;
  const _WinningPatternCard({required this.data, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFF97316).withOpacity(0.15), const Color(0xFF8B5CF6).withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF97316).withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(data['title'] ?? 'Winning Pattern', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 10),
        Text(data['insight'] ?? '', style: TextStyle(fontSize: 13, height: 1.5, color: c.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (data['duration_range'] != null) _tag('⏱️ ${data['duration_range']}'),
            if (data['hook_type'] != null) _tag('🎣 ${data['hook_type']} Hook'),
            if (data['multiplier'] != null) _tag('🚀 ${data['multiplier']}', isHighlight: true),
          ],
        ),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(8)), child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 ', style: TextStyle(fontSize: 13)),
            Expanded(child: Text(data['why_it_works'] ?? '', style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.4))),
          ])
        ),
      ]),
    );
  }

  Widget _tag(String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFF97316).withOpacity(0.2) : c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHighlight ? const Color(0xFFF97316).withOpacity(0.5) : c.border),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isHighlight ? const Color(0xFFF97316) : c.textSecondary)),
    );
  }
}

// ── Top vs Low Analysis Card ──────────────────────────────────────────────────
class _TopVsLowCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppColors c;
  final ThemeData theme;
  const _TopVsLowCard({required this.data, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📈 Top vs Low Performer', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _row(context, '🚀 Top', data['top_performer_example'] ?? '-', const Color(0xFF22C55E)),
        const SizedBox(height: 8),
        _row(context, '⚠️ Low', data['low_performer_example'] ?? '-', const Color(0xFFEF4444)),
        const Divider(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🔑 ', style: TextStyle(fontSize: 13)),
          Expanded(child: Text(data['key_difference'] ?? '', style: TextStyle(fontSize: 13, color: c.textPrimary, fontWeight: FontWeight.w600))),
        ]),
      ]),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 48, child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Theme.of(context).extension<AppColors>()!.textSecondary))),
    ]);
  }
}

// ── Action Plan Card ──────────────────────────────────────────────────────────
class _ActionPlanCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppColors c;
  final ThemeData theme;
  const _ActionPlanCard({required this.data, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    final steps = data['steps'] as List<dynamic>? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('⚡ Action Plan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(data['summary'] ?? '', style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.4)),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 22, height: 22, margin: const EdgeInsets.only(right: 10, top: 1),
              decoration: BoxDecoration(color: const Color(0xFF06B6D4), shape: BoxShape.circle),
              child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
            ),
            Expanded(child: Text(e.value.toString(), style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}

// ── Next Video Plan Card ──────────────────────────────────────────────────────
class _NextVideoPlanCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppColors c;
  final ThemeData theme;
  const _NextVideoPlanCard({required this.data, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    final structure = data['structure'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.12), const Color(0xFF06B6D4).withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🎬', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('Your Next Video', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        _planRow('Hook', data['hook'] ?? '-', c, theme),
        _planRow('Format', '${data['format'] ?? '-'} • ${data['length'] ?? '-'}', c, theme),
        _planRow('Post at', data['posting_time'] ?? '-', c, theme),
        
        if (structure.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Script Structure', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c.textSecondary)),
          const SizedBox(height: 8),
          ...structure.map((item) {
             final step = item['step']?.toString() ?? '';
             final detail = item['detail']?.toString() ?? '';
             return Padding(
               padding: const EdgeInsets.only(bottom: 8),
               child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Container(
                   width: 8,
                   height: 8,
                   margin: const EdgeInsets.only(top: 5, right: 8),
                   decoration: const BoxDecoration(color: Color(0xFF06B6D4), shape: BoxShape.circle),
                 ),
                 Expanded(
                   child: RichText(
                     text: TextSpan(
                       style: TextStyle(fontSize: 12, color: c.textPrimary, height: 1.4, fontFamily: theme.textTheme.bodyMedium?.fontFamily),
                       children: [
                         TextSpan(text: '$step: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                         TextSpan(text: detail, style: TextStyle(color: c.textSecondary)),
                       ],
                     ),
                   ),
                 ),
               ]),
             );
          }).toList(),
        ],
      ]),
    );
  }

  Widget _planRow(String label, String value, AppColors c, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 56, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF8B5CF6)))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.4))),
      ]),
    );
  }
}

// ── Content Ideas Card ────────────────────────────────────────────────────────
class _ContentIdeasCard extends StatelessWidget {
  final List<dynamic> ideas;
  final AppColors c;
  final ThemeData theme;
  const _ContentIdeasCard({required this.ideas, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('💡 Video Ideas Based on Your Data', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...ideas.map((idea) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🎯 ', style: TextStyle(fontSize: 14)),
              Expanded(child: Text(idea.toString(), style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.4))),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ── Performance Gap Card ──────────────────────────────────────────────────────
class _PerformanceGapCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppColors c;
  final ThemeData theme;
  const _PerformanceGapCard({required this.data, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    final topUse = data['top_videos_use'] as List<dynamic>? ?? [];
    final lowUse = data['low_videos_use'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📉', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('Performance Gap', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statBlock('Top Videos', '${data['top_avg'] ?? 0}%', const Color(0xFF22C55E), c),
            Container(width: 1, height: 40, color: c.border),
            _statBlock('Low Videos', '${data['low_avg'] ?? 0}%', const Color(0xFFEF4444), c),
            Container(width: 1, height: 40, color: c.border),
            _statBlock('Gap', '${data['gap_ratio'] ?? '-'}', const Color(0xFF8B5CF6), c),
          ],
        ),
        if (topUse.isNotEmpty || lowUse.isNotEmpty) ...[
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚀 Top videos use:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF22C55E))),
                  const SizedBox(height: 6),
                  ...topUse.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $item', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                  )),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Low videos have:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                  const SizedBox(height: 6),
                  ...lowUse.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $item', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                  )),
                ],
              )),
            ],
          ),
        ],
        if (data['action_to_take'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⚡ ', style: TextStyle(fontSize: 13)),
              Expanded(child: Text(data['action_to_take'], style: TextStyle(fontSize: 12, color: const Color(0xFF06B6D4), fontWeight: FontWeight.bold))),
            ]),
          ),
        ] else ...[
          const Divider(height: 24),
          Text(data['explanation'] ?? '', style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.4)),
        ],
      ]),
    );
  }

  Widget _statBlock(String label, String val, Color color, AppColors c) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.textSecondary)),
      ],
    );
  }
}

// ── Avoid Card ──────────────────────────────────────────────────────────
class _AvoidCard extends StatelessWidget {
  final List<dynamic> avoidList;
  final AppColors c;
  final ThemeData theme;
  const _AvoidCard({required this.avoidList, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🚫', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('What to Avoid', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
        ]),
        const SizedBox(height: 12),
        ...avoidList.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 2),
              child: Icon(Icons.close, size: 14, color: Color(0xFFEF4444)),
            ),
            Expanded(child: Text(item.toString(), style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}
