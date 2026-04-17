import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/app_colors.dart';
import '../widgets/analytics/main_performance_chart.dart';
import '../widgets/analytics/stat_grid.dart';
import '../widgets/analytics/published_content_list.dart';
import '../widgets/analytics/platform_deep_view.dart';
import '../widgets/analytics/real_time_data.dart';
import '../widgets/connect_platforms_view.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/view_state_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPlatform = 'Overview';
  late Future<Map<String, dynamic>> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = ApiService.getAnalyticsOverview();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getAnalyticsOverview(),
            builder: (context, snapshot) {
              final data      = snapshot.data ?? {};
              final platforms = (data['platforms'] as List? ?? []);
              final connected = platforms
                  .where((p) => p['isConnected'] == true)
                  .map((p) => p['name'].toString())
                  .toList();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _chip('Overview'),
                    ...connected.map((name) => _chip(name)),
                    IconButton(
                      icon: Icon(Icons.add_link, color: theme.colorScheme.primary, size: 20),
                      onPressed: () => context.read<ViewStateProvider>().setShowConnectView(true),
                      tooltip: 'Connect platform',
                    ),
                    const SizedBox(width: 4),
                    _chip('28 Days', icon: Icons.calendar_today),
                  ],
                ),
              );
            },
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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

          // Connect view guard
          if (_selectedPlatform == 'Overview') {
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
          if (_selectedPlatform != 'Overview') {
            return SingleChildScrollView(
              padding: r.contentPadding,
              child: PlatformDeepView(platform: _selectedPlatform, data: data),
            );
          }

          // ── OVERVIEW LAYOUT ─────────────────────────────────────────────
          final topContent  = data['topContent'] as List<dynamic>? ?? [];
          final subscribers = data['subscribers']?.toString() ?? '0';
          final totalViews  = data['totalViews']?.toString() ?? '0';

          // Find avatar from first connected platform
          String? avatarUrl;
          String channelName = 'Creator';
          final connected = platforms.where((p) => p['isConnected'] == true).toList();
          if (connected.isNotEmpty) {
            avatarUrl   = connected.first['channelAvatar'] as String?;
            channelName = connected.first['channelName'] as String? ?? 'Creator';
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() { _analyticsFuture = ApiService.getAnalyticsOverview(); });
              await _analyticsFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: r.contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── 1. Channel header strip ────────────────────────────
                  _ChannelHeader(
                    avatarUrl: avatarUrl,
                    channelName: channelName,
                    subscribers: subscribers,
                    totalViews: totalViews,
                  ),

                  SizedBox(height: r.spacing),

                  // ── 2. Section label + date range ─────────────────────
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
                          'Last 28 days',
                          style: TextStyle(fontSize: 12, color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: r.spacing * 0.75),

                  // ── 3. Quick stat cards (Views + Watch time / Likes) ──
                  StatGrid(data: data),

                  SizedBox(height: r.spacing),

                  // ── 4. Performance chart ───────────────────────────────
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(r.spacing, r.spacing, r.spacing, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Views over time',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              DropdownButton<String>(
                                value: 'This year',
                                onChanged: (v) {},
                                underline: const SizedBox(),
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: 'This year',  child: Text('This year')),
                                  DropdownMenuItem(value: 'This month', child: Text('This month')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        MainPerformanceChart(data: data),
                      ],
                    ),
                  ),

                  SizedBox(height: r.spacing),

                  // ── 5. Latest Published Content (YT Studio accordion) ─
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest published content',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (topContent.length > 3)
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'See all',
                            style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PublishedContentList(
                    topContent: topContent,
                    platforms: platforms,
                  ),

                  SizedBox(height: r.spacing),

                  // ── 6. Real-time / live card ──────────────────────────
                  Text(
                    'Real-time activity',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RealTimeDataCard(data: data['realTimeData'] as Map<String, dynamic>?),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, {IconData? icon}) {
    final theme      = Theme.of(context);
    final isSelected = _selectedPlatform == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        avatar: icon != null
            ? Icon(icon, size: 14, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)
            : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedPlatform = label;
            _analyticsFuture = label == 'Overview'
                ? ApiService.getAnalyticsOverview()
                : ApiService.getPlatformAnalytics(label);
          });
        },
        selectedColor: theme.colorScheme.primary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          fontSize: 13,
        ),
        showCheckmark: isSelected,
        checkmarkColor: theme.colorScheme.primary,
      ),
    );
  }
}

// ── Channel header widget ──────────────────────────────────────────────────────
class _ChannelHeader extends StatelessWidget {
  final String? avatarUrl;
  final String  channelName;
  final String  subscribers;
  final String  totalViews;

  const _ChannelHeader({
    required this.avatarUrl,
    required this.channelName,
    required this.subscribers,
    required this.totalViews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c     = theme.extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Icon(Icons.person, color: theme.colorScheme.primary, size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          // Channel name + subscribers
          Expanded(
            child: Column(
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
                    Text(
                      subscribers,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'subscribers',
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Total views pill
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
