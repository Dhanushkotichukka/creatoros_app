import 'package:flutter/material.dart';
import '../widgets/analytics/performance_card.dart';
import '../widgets/analytics/ai_suggestions.dart';
import '../widgets/analytics/platform_deep_view.dart';
import '../widgets/analytics/creator_health.dart';
import '../widgets/analytics/rotating_greeting.dart';
import '../widgets/analytics/top_content_list.dart';
import '../widgets/analytics/real_time_data.dart';
import '../widgets/connect_platforms_view.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPlatform = 'Overview';
  late Future<Map<String, dynamic>> _analyticsFuture;
  bool _showConnectView = false;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = ApiService.getAnalyticsOverview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getAnalyticsOverview(), // Use a fresh fetch for tabs
            builder: (context, snapshot) {
              final data = snapshot.data ?? {};
              final platforms = (data['platforms'] as List? ?? []);
              final connectedNames = platforms
                  .where((p) => p['isConnected'] == true)
                  .map((p) => p['name'].toString())
                  .toList();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Overview'),
                    ...connectedNames.map((name) => _buildFilterChip(name)),
                    IconButton(
                      icon: const Icon(Icons.add_link, color: Colors.deepPurpleAccent), 
                      onPressed: () {
                        setState(() { _showConnectView = true; });
                      }
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('28 Days', icon: Icons.calendar_today),
                  ],
                ),
              );
            }
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ConnectPlatformsView(onConnected: () => setState(() {
              _analyticsFuture = ApiService.getAnalyticsOverview();
            }));
          }

          final data = snapshot.data ?? {};
          final platforms = data['platforms'] as List<dynamic>? ?? [];
          
          if (_selectedPlatform == 'Overview') {
            final connectedPlatforms = platforms.where((p) => p['isConnected'] == true).toList();
            if (connectedPlatforms.isEmpty || _showConnectView) {
              return ConnectPlatformsView(onConnected: () => setState(() {
                _showConnectView = false;
                _analyticsFuture = ApiService.getAnalyticsOverview();
              }));
            }
          }

          if (_showConnectView) {
             return ConnectPlatformsView(onConnected: () => setState(() {
                _showConnectView = false;
                _analyticsFuture = ApiService.getAnalyticsOverview();
             }));
          }

          if (_selectedPlatform != 'Overview') {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: PlatformDeepView(platform: _selectedPlatform, data: snapshot.data ?? {}),
            );
          }

          final health = data['creatorHealth'] ?? 'Happy';
          
          List<String> aiInsights = [
            'Your reel engagement increased by ${data['growth'] ?? '0%'} this week',
            'Best time to post today: based on your audience activity pattern',
            'Your posting velocity has improved your overall Creator Score to ${data['creatorScore'] ?? 80}/100'
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RotatingGreeting(platforms: platforms),
                const SizedBox(height: 10),
                const Text('Hold graph to toggle numbers', style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 10),
                PerformanceCard(data: data),
                const SizedBox(height: 20),
                AISuggestions(suggestions: aiInsights),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Top Content'),
                const SizedBox(height: 12),
                TopContentList(topContent: data['topContent'] as List<dynamic>? ?? []),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Real-Time Data'),
                const SizedBox(height: 12),
                RealTimeDataCard(data: data['realTimeData'] as Map<String, dynamic>?),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon}) {
    bool isSelected = _selectedPlatform == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        avatar: icon != null ? Icon(icon, size: 16) : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedPlatform = label;
            if (label == 'Overview') {
                _analyticsFuture = ApiService.getAnalyticsOverview();
            } else {
                _analyticsFuture = ApiService.getPlatformAnalytics(label);
            }
          });
        },
        selectedColor: Colors.deepPurpleAccent.withOpacity(0.3),
      ),
    );
  }
}


class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text('View All')),
      ],
    );
  }
}
