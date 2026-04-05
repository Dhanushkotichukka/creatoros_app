import 'package:flutter/material.dart';
import 'creator_health.dart';
import 'main_performance_chart.dart';

class PerformanceCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const PerformanceCard({super.key, required this.data});

  @override
  State<PerformanceCard> createState() => _PerformanceCardState();
}

class _PerformanceCardState extends State<PerformanceCard> {
  bool _isQuickSummary = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isQuickSummary = !_isQuickSummary;
        });
      },
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          height: 250,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Overall Health', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),
                    CreatorHealth(
                      engagementRate: (widget.data['engagementRate'] ?? 0.06).toDouble(),
                      streakDays: widget.data['streak'] ?? 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              VerticalDivider(color: theme.dividerColor.withOpacity(0.1), width: 1),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isQuickSummary ? _buildQuickSummary() : _buildMiniGraph(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniGraph() {
    final theme = Theme.of(context);
    final String views = widget.data['totalViews']?.toString() ?? widget.data['views']?.toString() ?? '0';
    
    // Check if we have graphData
    final hasGraph = widget.data.containsKey('graphData');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Engagement Rate', style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Expanded(
          child: hasGraph 
            ? IgnorePointer(child: MainPerformanceChart(data: widget.data))
            : Icon(Icons.auto_graph, size: 60, color: theme.colorScheme.primary.withOpacity(0.5)),
        ),
        const SizedBox(height: 10),
        Text('Actual Reach: $views', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickSummary() {
    return Column(
      key: const ValueKey('summary'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Quick Summary', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SummaryItem(label: 'Total Views', value: (widget.data['totalViews'] ?? widget.data['views'] ?? '—').toString()),
        SummaryItem(label: 'Total Likes', value: (widget.data['totalLikes'] ?? '—').toString()),
        SummaryItem(label: 'Subscribers', value: (widget.data['subscribers'] ?? '—').toString()),
        SummaryItem(label: 'Videos', value: (widget.data['videos'] ?? '—').toString()),
        SummaryItem(label: 'Growth', value: (widget.data['growth'] ?? '—').toString()),
      ],
    );
  }
}

class SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const SummaryItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
