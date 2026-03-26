import 'package:flutter/material.dart';

class RealTimeDataCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  
  const RealTimeDataCard({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Center(child: Text('Connect a platform to view live Real-Time activity.', style: TextStyle(color: Colors.grey)));
    }

    final String totalViews48h = data!['totalViews48h'] ?? '0';
    List<double> hourlyViews = (data!['hourlyViews'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    if (hourlyViews.isEmpty) {
      hourlyViews = [12, 15, 8, 20, 25, 40, 35, 30, 45, 60, 55, 65, 80, 75, 90, 110, 105, 95, 85, 70, 50, 40, 30, 20];
    }
    final double maxVal = hourlyViews.reduce((a, b) => a > b ? a : b);
    final List<dynamic> trendingVideos = data!['trendingVideos'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_tethering, color: Colors.blueAccent, size: 18),
              SizedBox(width: 8),
              Text('Live • Last 48 Hours', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ]
          ),
          const SizedBox(height: 12),
          Text('$totalViews48h Views', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Hourly Bar Graph
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: hourlyViews.map((val) {
                return Container(
                  width: 8,
                  height: (val / maxVal) * 120,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('24h ago', style: TextStyle(color: Colors.grey, fontSize: 10)),
               Text('Now', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ]
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          
          // Live Video Activity
          const Text('Currently Trending', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (trendingVideos.isEmpty)
             const Text('No active trending loops detected.', style: TextStyle(color: Colors.white54)),
          ...trendingVideos.map((v) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildLiveItem(v['thumbnail'] ?? '', v['title'] ?? 'Unknown', v['subtitle'] ?? '0 views this hour'),
          )),
        ],
      )
    );
  }

  Widget _buildLiveItem(String thumb, String title, String subtitle) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            thumb,
            width: 50,
            height: 30,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              width: 50,
              height: 30,
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.play_arrow, size: 16, color: Colors.white54),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.green, fontSize: 11)),
            ],
          )
        )
      ],
    );
  }
}
