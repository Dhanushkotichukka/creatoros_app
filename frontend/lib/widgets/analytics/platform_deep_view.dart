import 'package:flutter/material.dart';
import '../../widgets/analytics/performance_card.dart';
import '../../widgets/analytics/platform_header.dart';
import '../../widgets/analytics/video_tabs.dart';
import '../../widgets/analytics/main_performance_chart.dart';

class PlatformDeepView extends StatelessWidget {
  final String platform;
  final Map<String, dynamic> data;

  const PlatformDeepView({super.key, required this.platform, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("No Data Available"));

    final platformData = data['platformData'] as Map<String, dynamic>? ?? {};
    final videos = data['videos'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlatformHeader(platformData: platformData),
        const SizedBox(height: 24),
        Text('Engagement Trend', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: MainPerformanceChart(data: data),
          ),
        ),
        const SizedBox(height: 24),
        Text('Platform Health & Stats', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        PerformanceCard(data: data),
        const SizedBox(height: 24),
        Text('All Content', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        VideoTabs(videos: videos),
      ],
    );
  }
}
