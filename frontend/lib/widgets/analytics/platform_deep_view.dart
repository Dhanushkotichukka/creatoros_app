import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/analytics/performance_card.dart';
import '../../widgets/analytics/platform_header.dart';
import '../../widgets/analytics/video_tabs.dart';
import '../../widgets/analytics/main_performance_chart.dart';
import '../../widgets/analytics/audience_widgets.dart';
import '../../widgets/analytics/insights_fab.dart';
import '../../screens/insights_screen.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive.dart';
import 'overview_dashboard.dart';
import 'dart:async';

class PlatformDeepView extends StatefulWidget {
  final String platform;
  final Map<String, dynamic> data;

  const PlatformDeepView({super.key, required this.platform, required this.data});

  @override
  State<PlatformDeepView> createState() => _PlatformDeepViewState();
}

class _PlatformDeepViewState extends State<PlatformDeepView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Open platform-specific insights ─────────────────────────────────
  Future<void> _openInsights() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => InsightsScreen(platform: widget.platform),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const Center(child: Text("No Data Available"));

    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    final r = Responsive.of(context);

    final platformData = widget.data['platformData'] as Map<String, dynamic>? ?? {};
    final videos = widget.data['videos'] as List<dynamic>? ?? [];

    return Stack(
      children: [
        // ── Main scrollable content ──────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlatformHeader(platformData: platformData),
            const SizedBox(height: 12),

            // ── Tab Bar with 3 tabs ──────────────────────────────────────
            TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: c.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Content'),
                Tab(text: 'Audience'),
              ],
            ),

            const SizedBox(height: 12),

            // ── Tab Content ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1: Overview ──────────────────────────────────────
                  _OverviewTab(data: widget.data),

                  // ── Tab 2: Content ───────────────────────────────────────
                  _ContentTab(videos: videos),

                  // ── Tab 3: Audience ──────────────────────────────────────
                  _AudienceTab(
                    data: widget.data['audience'] as Map<String, dynamic>? ?? {},
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Platform-specific AI Insights FAB ───────────────────────────
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
  }
}

// ── Overview Tab ────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OverviewTab({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data['overview'] == null) {
      return const Center(child: Text('Overview data unavailable'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: OverviewDashboard(overviewData: data['overview'] as Map<String, dynamic>),
    );
  }
}

// ── Content Tab ──────────────────────────────────────────────────────────────
class _ContentTab extends StatelessWidget {
  final List<dynamic> videos;
  const _ContentTab({required this.videos});

  @override
  Widget build(BuildContext context) => VideoTabs(videos: videos);
}

// ── Audience Tab ─────────────────────────────────────────────────────────────
class _AudienceTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AudienceTab({required this.data});

  @override
  Widget build(BuildContext context) => AudienceDashboard(data: data);
}

// ── Real-time Sparkline ───────────────────────────────────────────────────────
class _RealTimeGraph extends StatelessWidget {
  final Map<String, dynamic> realtime;
  const _RealTimeGraph({required this.realtime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;

    final labels = realtime['labels'] as List<dynamic>? ?? [];
    final values = realtime['values'] as List<dynamic>? ?? [];

    if (values.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Loading live activity...', style: TextStyle(color: c.textSecondary)),
      );
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 48 Hours',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '${values.last} views now',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        values.length,
                        (i) => FlSpot(i.toDouble(), (values[i] as num).toDouble()),
                      ),
                      isCurved: true,
                      barWidth: 2,
                      color: theme.colorScheme.primary,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
