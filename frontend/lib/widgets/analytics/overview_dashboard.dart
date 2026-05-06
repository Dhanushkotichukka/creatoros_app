import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive.dart';
import '../../screens/video_detail_screen.dart';
import '../charts/reusable_line_chart.dart';
import '../charts/reusable_bar_chart.dart';

class OverviewDashboard extends StatefulWidget {
  final Map<String, dynamic> overviewData;
  final String platform;

  const OverviewDashboard({
    super.key,
    required this.overviewData,
    this.platform = 'Overview',
  });

  @override
  State<OverviewDashboard> createState() => _OverviewDashboardState();
}

class _OverviewDashboardState extends State<OverviewDashboard> {
  int _graphTimeFilter = 28; // 7, 28, 90
  int _activeGraphMetric = 0; // 0=Views, 1=WatchTime, 2=Subs, 3=Engagement

  List<dynamic> get lastVideos => widget.overviewData['lastVideos'] as List<dynamic>? ?? [];
  List<dynamic> get topContent => widget.overviewData['topContent'] as List<dynamic>? ?? [];
  Map<String, dynamic> get realtime => widget.overviewData['realtime'] as Map<String, dynamic>? ?? {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    final isDesktop = Responsive.isWebSize(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Section: Videos & Graphs ──────────────────────────
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildLastVideos(theme, c)),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: _buildAnalyticsGraphs(theme, c)),
            ],
          )
        else
          Column(
            children: [
              _buildLastVideos(theme, c),
              const SizedBox(height: 24),
              _buildAnalyticsGraphs(theme, c),
            ],
          ),

        const SizedBox(height: 32),

        // ── Bottom Section: Top Content & Realtime ────────────────
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _buildTopContent(theme, c)),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: _buildRealTime(theme, c)),
            ],
          )
        else
          Column(
            children: [
              _buildTopContent(theme, c),
              const SizedBox(height: 32),
              _buildRealTime(theme, c),
            ],
          ),
      ],
    );
  }

  Widget _buildLastVideos(ThemeData theme, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 3 Videos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (lastVideos.isEmpty)
          const Center(child: Text('No recent videos'))
        else
          ...lastVideos.take(3).map((v) => _buildVideoCard(v, theme, c)),
      ],
    );
  }

  Widget _buildVideoCard(dynamic v, ThemeData theme, AppColors c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VideoDetailScreen(videoId: v['id'], platform: v['platform'] ?? 'YouTube')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  v['thumbnail'] ?? '',
                  width: 100,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 100, height: 60, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v['title'] ?? 'Untitled',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _statIcon(Icons.remove_red_eye, v['views'] ?? '0', theme),
                        const SizedBox(width: 12),
                        _statIcon(Icons.thumb_up, v['likes'] ?? '0', theme),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statIcon(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAnalyticsGraphs(ThemeData theme, AppColors c) {
    // Generate dummy data based on filter for demonstration, in real app backend sends time-series
    final List<double> values = List.generate(_graphTimeFilter, (i) => 100.0 + (i * 5) + (i % 3 * 20));
    final List<String> labels = List.generate(_graphTimeFilter, (i) => 'Day $i');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Performance Trends', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: _graphTimeFilter,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 Days')),
                    DropdownMenuItem(value: 28, child: Text('28 Days')),
                    DropdownMenuItem(value: 90, child: Text('90 Days')),
                  ],
                  onChanged: (v) => setState(() => _graphTimeFilter = v ?? 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricPill('Views', 0, theme, c),
                _metricPill('Watch Time', 1, theme, c),
                _metricPill('Subscribers', 2, theme, c),
                _metricPill('Engagement', 3, theme, c),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: ReusableLineChart(
                values: values,
                labels: labels,
                showPoints: _graphTimeFilter <= 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricPill(String label, int index, ThemeData theme, AppColors c) {
    final bool active = _activeGraphMetric == index;
    return InkWell(
      onTap: () => setState(() => _activeGraphMetric = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? theme.colorScheme.primary : c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? theme.colorScheme.primary : c.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTopContent(ThemeData theme, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top 5 Content (Last 28 Days)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (topContent.isEmpty)
          const Center(child: Text('No top content'))
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topContent.length > 5 ? 5 : topContent.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
              itemBuilder: (context, i) {
                final v = topContent[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      v['thumbnail'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    v['title'] ?? 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text('${v['views'] ?? 0} views', style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      v['growthPct'] ?? '+0%',
                      style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VideoDetailScreen(videoId: v['id'], platform: v['platform'] ?? 'YouTube')),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRealTime(ThemeData theme, AppColors c) {
    final hours = (realtime['hours'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList();
    final perVideo = realtime['perVideo'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Real-time (48 hours)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.show_chart, color: Colors.blue, size: 20),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: ReusableLineChart(
                values: hours.isNotEmpty ? hours : List.generate(48, (i) => 0.0),
                labels: List.generate(48, (i) => '-${48-i}h'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Per-Video Breakdown', style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ReusableBarChart(
                values: perVideo.map((v) => (v['views48h'] as num?)?.toDouble() ?? 0.0).toList(),
                labels: perVideo.map((v) {
                  final title = v['title']?.toString() ?? 'Unknown';
                  return title.length > 10 ? '${title.substring(0, 10)}...' : title;
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
