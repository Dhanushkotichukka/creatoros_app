import 'package:flutter/material.dart';
import '../../widgets/analytics/performance_card.dart';
import '../../widgets/analytics/platform_header.dart';
import '../../widgets/analytics/video_tabs.dart';

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
        const Text('Platform Health & Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        PerformanceCard(data: platformData), // Directly pass deep platform metadata into generic graph component!
        const SizedBox(height: 24),
        const Text('All Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 12),
        VideoTabs(videos: videos),
      ],
    );
  }
}
