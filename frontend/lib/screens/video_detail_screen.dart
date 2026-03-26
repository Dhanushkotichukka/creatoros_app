import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;

  const VideoDetailScreen({super.key, required this.videoId});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late Future<Map<String, dynamic>> _videoFuture;

  @override
  void initState() {
    super.initState();
    _videoFuture = ApiService.getVideoAnalytics(widget.videoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _videoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Failed to load video data", style: TextStyle(color: Colors.red)));
          }

          final data = snapshot.data!;
          final video = data['video'] ?? {};
          final aiInsights = data['aiInsights'] as List<dynamic>? ?? [];
          final earlyPerf = data['earlyPerformance'] ?? {};
          final deepMetrics = data['deepMetrics'] ?? {};
          final comments = data['comments'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSection(video),
                const SizedBox(height: 24),
                _buildAIVideoInsights(aiInsights),
                const SizedBox(height: 24),
                _buildVideoSettingsPanel(video),
                const SizedBox(height: 24),
                _buildEarlyPerformanceSummary(earlyPerf),
                const SizedBox(height: 24),
                _buildDetailedPerformancePage(deepMetrics),
                const SizedBox(height: 24),
                _buildCommentsSection(comments),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      )
    );
  }

  Widget _buildTopSection(Map<String, dynamic> video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                video['thumbnail'] ?? 'https://via.placeholder.com/600x300',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(height: 220, color: Colors.grey[900]),
              ),
            ),
            Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, size: 40, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
            IconButton(icon: const Icon(Icons.share, color: Colors.green), onPressed: () {}),
            IconButton(icon: const Icon(Icons.open_in_browser, color: Colors.red), onPressed: () {}),
          ]
        ),
        const SizedBox(height: 8),
        Text(video['title'] ?? 'Untitled Video', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text('${video['views'] ?? '0'} Views • Published: ${video['publishedAt'] != null ? video['publishedAt'].toString().split('T')[0] : 'Unknown'}', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildAIVideoInsights(List<dynamic> insights) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.auto_awesome, color: Colors.purpleAccent), SizedBox(width: 8), Text('AI Video Performance Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))]),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.purpleAccent, fontSize: 18)),
                Expanded(child: Text(insight.toString(), style: const TextStyle(color: Colors.grey, height: 1.4))),
              ],
            ),
          )),
        ],
      )
    );
  }

  Widget _buildVideoSettingsPanel(Map<String, dynamic> video) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Video Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
             const Divider(),
             _buildSettingRow('Visibility', video['visibility'] ?? 'Public', true),
             _buildSettingRow('Quality', video['quality'] ?? 'HD', false),
             _buildSettingRow('Restrictions', video['restrictions'] ?? 'None', false),
             _buildSettingRow('Category', video['category'] ?? 'Entertainment', false),
             _buildSettingRow('Monetisation', video['monetisation'] ?? 'Monetised', false),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              if (isEditable) const SizedBox(width: 8),
              if (isEditable) const Icon(Icons.edit, size: 14, color: Colors.blueAccent),
            ]
          )
        ],
      ),
    );
  }

  Widget _buildEarlyPerformanceSummary(Map<String, dynamic> earlyPerf) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Early Performance Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('First ${earlyPerf['timeSinceUpload'] ?? 'Unknown'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(),
          _buildSummaryRow('Views', earlyPerf['views'] ?? '0', isUp: true),
          _buildSummaryRow('Impression Rate', earlyPerf['impressionRate'] ?? '0%', isUp: true),
          _buildSummaryRow('Subscriber Gain', earlyPerf['subGain'] ?? '0', isUp: true),
          _buildSummaryRow('Comments Ratio', earlyPerf['commentsToViews'] ?? '0%', isUp: false),
        ],
      )
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isUp = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: const TextStyle(color: Colors.grey)),
           Row(
             children: [
               Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isUp ? Colors.green : Colors.white)),
               if (isUp) const SizedBox(width: 4),
               if (isUp) const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
             ]
           )
        ],
      )
    );
  }

  Widget _buildDetailedPerformancePage(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deep Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        _buildMetricBlock('Watch Retention Curve', Icons.insights, Colors.orange),
        _buildMetricBlock('Audience Demographics', Icons.pie_chart, Colors.purple),
        _buildMetricBlock('Traffic Sources', Icons.alt_route, Colors.blue),
      ],
    );
  }

  Widget _buildMetricBlock(String title, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      )
    );
  }

  Widget _buildCommentsSection(List<dynamic> comments) {
    if (comments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
           Text('Recent Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
           Text('View All', style: TextStyle(color: Colors.blueAccent))
        ]),
        const SizedBox(height: 12),
        ...comments.map((c) => Card(
          elevation: 0,
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c['author'] ?? '@user', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: c['sentiment'] == 'Positive' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text(c['sentiment'] ?? 'Neutral', style: TextStyle(fontSize: 10, color: c['sentiment'] == 'Positive' ? Colors.green : Colors.grey)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(c['text'] ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const Row(children: [Icon(Icons.reply, size: 14, color: Colors.blueAccent), SizedBox(width: 4), Text('Reply', style: TextStyle(fontSize: 12, color: Colors.blueAccent))])
              ],
            )
          )
        ))
      ],
    );
  }
}
