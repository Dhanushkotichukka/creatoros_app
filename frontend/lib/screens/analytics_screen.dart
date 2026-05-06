import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/app_colors.dart';
import '../widgets/analytics/main_performance_chart.dart';
import '../widgets/analytics/stat_grid.dart';
import '../widgets/analytics/published_content_list.dart';
import '../widgets/analytics/platform_deep_view.dart';
import '../widgets/analytics/real_time_data.dart';
import '../widgets/analytics/insights_fab.dart';
import '../widgets/analytics/overview_dashboard.dart';
import 'insights_screen.dart';
import '../widgets/connect_platforms_view.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/view_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<Map<String, dynamic>> _analyticsFuture;

  // Cached connected-platform list from last successful load — drives AppBar chips
  // without firing a second API call.
  List<String> _connectedPlatforms = [];

  // ── Auto-refresh (90s) — only when screen is fully visible ──────────────
  Timer?  _autoRefreshTimer;
  bool    _isRefreshing = false;
  DateTime? _lastFetchTime;

  // ── Header flip timer ────────────────────────────────────────────────
  Timer?  _headerTimer;
  int     _headerIndex = 0;
  bool    _headerPaused = false; // paused when user is scrolling/touching


  // ── Scroll controller (used to detect user interaction) ─────────────
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPinnedPlatform();
    _analyticsFuture = ApiService.getAnalyticsOverview();
    _lastFetchTime = DateTime.now();
    _startHeaderTimer();
    _fetchPlatformStatus();
    _startAutoRefresh();

    // Pause header flip on scroll
    _scrollCtrl.addListener(_onScroll);

    // Listen for platform changes (e.g. from jumpToAnalytics)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewState = context.read<ViewStateProvider>();
      viewState.addListener(_handleGlobalPlatformChange);

      // Initial fetch if we're starting on a specific platform
      if (viewState.analyticsPlatform != 'Overview') {
        _handleGlobalPlatformChange();
      }
    });
  }

  // ── Auto-refresh every 90 seconds (smart: only when active) ─────────────
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (!mounted) return;
      // Only refresh if screen is active (not paused)
      final vp = context.read<ViewStateProvider>();
      final platform = vp.analyticsPlatform;
      if (!_headerPaused) {
        _triggerSmartRefresh(platform);
      }
    });
  }

  Future<void> _triggerSmartRefresh(String platform) async {
    if (_isRefreshing) return;
    // Debounce: don't re-fetch if we fetched within the last 60s
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < const Duration(seconds: 60)) return;
    _isRefreshing = true;
    try {
      setState(() {
        _analyticsFuture = platform == 'Overview'
            ? ApiService.getAnalyticsOverview(forceRefresh: true)
            : ApiService.getPlatformAnalytics(platform, forceRefresh: true);
        _lastFetchTime = DateTime.now();
      });
      await _analyticsFuture;
    } finally {
      _isRefreshing = false;
    }
  }

  // ── Scroll listener: pause header while user is dragging ─────────────
  void _onScroll() {
    if (!_headerPaused) {
      setState(() => _headerPaused = true);
    }
    _scrollPauseDebounce?.cancel();
    _scrollPauseDebounce = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _headerPaused = false);
    });
  }

  Timer? _scrollPauseDebounce;

  void _handleGlobalPlatformChange() {
    if (!mounted) return;
    final platform = context.read<ViewStateProvider>().analyticsPlatform;
    setState(() {
      _analyticsFuture = platform == 'Overview'
          ? ApiService.getAnalyticsOverview()
          : ApiService.getPlatformAnalytics(platform);
      _lastFetchTime = DateTime.now();
    });
  }

  Future<void> _fetchPlatformStatus() async {
    try {
      final status = await ApiService.getPlatformStatus();
      if (mounted) {
        setState(() {
          _connectedPlatforms = status.where((p) => p['isConnected'] == true)
              .map((p) => p['name'].toString())
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching platform status: $e');
    }
  }

  @override
  void dispose() {
    _headerTimer?.cancel();
    _scrollPauseDebounce?.cancel();
    _autoRefreshTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    context.read<ViewStateProvider>().removeListener(_handleGlobalPlatformChange);
    super.dispose();
  }

  void _startHeaderTimer() {
    _headerTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_headerPaused) {
        setState(() { _headerIndex++; });
      }
    });
  }

  Future<void> _loadPinnedPlatform() async {
    final prefs = await SharedPreferences.getInstance();
    final pinned = prefs.getString('pinned_platform');
    if (pinned != null) {
      final viewState = context.read<ViewStateProvider>();
      viewState.setPinnedPlatform(pinned);
      if (pinned != 'Overview' && mounted) {
        viewState.setAnalyticsPlatform(pinned);
        setState(() {
          _analyticsFuture = ApiService.getPlatformAnalytics(pinned);
        });
      }
    }
  }

  Future<void> _togglePin(String platform) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPin = prefs.getString('pinned_platform');

    if (currentPin == platform) {
      await prefs.remove('pinned_platform');
      context.read<ViewStateProvider>().setPinnedPlatform(null);
    } else {
      await prefs.setString('pinned_platform', platform);
      context.read<ViewStateProvider>().setPinnedPlatform(platform);
    }
    setState(() {});
  }

  // ── Open Insights ────────────────────────────────────────────────────
  Future<void> _openInsights() async {
    final viewState = context.read<ViewStateProvider>();
    final platform = viewState.analyticsPlatform == 'Overview' ? null : viewState.analyticsPlatform;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => InsightsScreen(platform: platform),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c     = theme.extension<AppColors>()!;
    final r     = Responsive.of(context);

    return Scaffold(
      // ── App Bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Manual refresh button
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh data',
            onPressed: _isRefreshing ? null : () async {
              final vp = context.read<ViewStateProvider>();
              await _triggerSmartRefresh(vp.analyticsPlatform);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          // ── Use cached platform list, no extra API call ──────────────
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _chip('Overview'),
                ..._connectedPlatforms.map((name) => _chip(name)),
                IconButton(
                  icon: Icon(Icons.add_link, color: theme.colorScheme.primary, size: 20),
                  onPressed: () => context.read<ViewStateProvider>().setShowConnectView(true),
                  tooltip: 'Connect platform',
                ),
                const SizedBox(width: 4),
                _chip('28 Days', icon: Icons.calendar_today),
              ],
            ),
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          // Loading — show skeleton instead of blank spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _AnalyticsSkeleton();
          }
          // Error → show connect view
          if (snapshot.hasError) {
            return ConnectPlatformsView(onConnected: () => setState(() {
              _analyticsFuture = ApiService.getAnalyticsOverview();
            }));
          }

          final data      = snapshot.data ?? {};
          final platforms = data['platforms'] as List<dynamic>? ?? [];
          final viewState = context.watch<ViewStateProvider>();

          // Update cached platform list for AppBar chips whenever connectivity data is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final platformsData = data['platforms'] as List<dynamic>?;
            if (platformsData != null) {
              final connected = platformsData
                  .where((p) => p['isConnected'] == true)
                  .map((p) => p['name'].toString())
                  .toList();
              if (!_listEquals(connected, _connectedPlatforms)) {
                setState(() => _connectedPlatforms = connected);
              }
            }
          });

          // Connect view guard
          if (viewState.analyticsPlatform == 'Overview') {
            final connected = platforms.where((p) => p['isConnected'] == true).toList();
            if (connected.isEmpty || viewState.showConnectView) {
              return ConnectPlatformsView(onConnected: () => setState(() {
                _analyticsFuture = ApiService.getAnalyticsOverview();
                viewState.setShowConnectView(false);
              }));
            }
          }
          if (viewState.showConnectView) {
            return ConnectPlatformsView(onConnected: () => setState(() {
              _analyticsFuture = ApiService.getAnalyticsOverview();
              viewState.setShowConnectView(false);
            }));
          }

          // Platform-specific deep view
          if (viewState.analyticsPlatform != 'Overview') {
            return Padding(
              padding: r.contentPadding,
              child: PlatformDeepView(
                platform: viewState.analyticsPlatform,
                data: data,
              ),
            );
          }

          // ── OVERVIEW LAYOUT ─────────────────────────────────────────────
          final topContent  = data['topContent'] as List<dynamic>? ?? [];
          final totalViews  = data['totalViews']?.toString() ?? '0';

          // Find avatar from first connected platform
          final connected = platforms.where((p) => p['isConnected'] == true).toList();

          return Stack(
            children: [
              // ── Main scrollable content ──────────────────────────────
              RefreshIndicator(
                onRefresh: () async {
                  // Force-refresh bypasses the backend 5-min cache
                  setState(() { _analyticsFuture = ApiService.getAnalyticsOverview(forceRefresh: true); });
                  await _analyticsFuture;
                },
                child: Listener(
                  // Pause header flip on any pointer-down (touch start)
                  onPointerDown: (_) { if (!_headerPaused) setState(() => _headerPaused = true); },
                  onPointerUp: (_) {
                    _scrollPauseDebounce?.cancel();
                    _scrollPauseDebounce = Timer(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _headerPaused = false);
                    });
                  },
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: r.contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── 1. Channel header strip (Animated Flip) ────────
                        _ChannelHeader(
                          platforms: platforms.where((p) => p['isConnected'] == true).toList(),
                          index: _headerIndex,
                          totalViews: totalViews,
                          onPin: () => _togglePin('Overview'),
                        ),

                        SizedBox(height: r.spacing),

                        // ── 2. Section label + date range ──────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Channel analytics',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.secondary.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: c.border),
                              ),
                              child: Text(
                                // ✅ Improvement #4 — clear combined label
                                'Last 28 Days (All Platforms)',
                                style: TextStyle(fontSize: 12, color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: r.spacing * 0.75),

                        // ── 3. Quick stat cards ────────────────────────────
                        StatGrid(data: data),

                        SizedBox(height: r.spacing),

                        // ── 4. Main Dashboard UI ───────────────────────────
                        if (data['overview'] != null)
                          OverviewDashboard(overviewData: data['overview'] as Map<String, dynamic>)
                        else
                          const Center(child: Text('Overview data unavailable')),

                        // Extra bottom padding so FAB doesn't overlap last content
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Floating Insights FAB ────────────────────────────────
              Positioned(
                right: 16,
                bottom: 16,
                child: InsightsFAB(
                  isLoading: false,
                  onPressed: _openInsights,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Simple list equality helper (avoids importing collection package)
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
    return true;
  }

  Widget _chip(String label, {IconData? icon}) {
    final theme      = Theme.of(context);
    final viewState  = context.read<ViewStateProvider>();
    final isSelected = viewState.analyticsPlatform == label;
    final isPinned   = viewState.pinnedPlatform == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onLongPress: () {
          _togglePin(label);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isPinned ? 'Unpinned $label' : 'Pinned $label as default view'), duration: const Duration(seconds: 1)),
          );
        },
        child: FilterChip(
          avatar: isPinned
              ? Icon(Icons.push_pin, size: 14, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)
              : (icon != null
                  ? Icon(icon, size: 14, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)
                  : null),
          label: Text(label),
          selected: isSelected,
          onSelected: (_) {
            viewState.setAnalyticsPlatform(label);
            // The listener (_handleGlobalPlatformChange) will trigger the data fetch
          },
          selectedColor: theme.colorScheme.primary.withOpacity(0.15),
          labelStyle: TextStyle(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 13,
          ),
          showCheckmark: isSelected && !isPinned,
          checkmarkColor: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ── Channel header widget (Auto-Flip, pauses on touch/scroll) ─────────────────
class _ChannelHeader extends StatelessWidget {
  final List<dynamic> platforms;
  final int index;
  final String totalViews;
  final VoidCallback? onPin;

  const _ChannelHeader({
    required this.platforms,
    required this.index,
    required this.totalViews,
    this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;

    if (platforms.isEmpty) return const SizedBox();

    // Determine current platform to show based on cycle
    final current = platforms[index % platforms.length];
    final avatarUrl    = current['channelAvatar'] as String?;
    final channelName  = current['channelName']   as String? ?? 'Creator';
    final platformName = current['name']           as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          // Avatar with Flip Animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: CircleAvatar(
              key: ValueKey('avatar_$index'),
              radius: 26,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, color: theme.colorScheme.primary, size: 24)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          // Channel name + subscribers (Animated Text)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Column(
                key: ValueKey('text_$index'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channelName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        platformName.toLowerCase() == 'youtube' ? Icons.play_circle_fill : Icons.camera_alt,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        platformName,
                        style: TextStyle(color: c.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Metrics Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  totalViews,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text('Total Views', style: TextStyle(color: c.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header (kept for compatibility) ────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

// ── Skeleton Loading UI ───────────────────────────────────────────────────────
class _AnalyticsSkeleton extends StatefulWidget {
  @override
  State<_AnalyticsSkeleton> createState() => _AnalyticsSkeletonState();
}

class _AnalyticsSkeletonState extends State<_AnalyticsSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final color = c.border.withOpacity(_anim.value);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel header skeleton
              Container(
                height: 76,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 20),
              // Stat cards skeleton
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    height: 80,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 20),
              // Chart skeleton
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 20),
              // Content list skeletons
              ...List.generate(3, (i) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 78,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}
