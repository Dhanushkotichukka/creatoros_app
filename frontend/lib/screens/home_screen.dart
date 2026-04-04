import 'package:flutter/material.dart';
import 'multi_post_hub_screen.dart';
import '../models/multi_post/platform_type.dart';

import '../widgets/creator_overview_card.dart';
import '../widgets/platform_analytics_slider.dart';
import '../widgets/ai_update_ticker.dart';
import '../widgets/content_section.dart';
import '../widgets/creator_score_widget.dart';
import '../widgets/connect_platforms_view.dart';
import '../services/api_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _analyticsFuture;
  bool _showConnectView = false;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = ApiService.getAnalyticsOverview();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return ConnectPlatformsView(onConnected: () => setState(() {
            _analyticsFuture = ApiService.getAnalyticsOverview();
          }));
        }

        final data = snapshot.data ?? {};
        final platforms = data['platforms'] as List<dynamic>? ?? [];
        
        if (platforms.isEmpty) {
          return ConnectPlatformsView(onConnected: () => setState(() {
            _analyticsFuture = ApiService.getAnalyticsOverview();
          }));
        }

        if (_showConnectView) {
          return ConnectPlatformsView(onConnected: () {
            setState(() {
              _showConnectView = false;
              _analyticsFuture = ApiService.getAnalyticsOverview();
            });
          });
        }
        
        // Build real AI insights from actual data
        final growth = data['growth'] ?? '+0%';
        final totalViews = data['totalViews'] ?? '0';
        final streak = data['streak'] ?? 0;
        final topContent = data['topContent'] as List<dynamic>? ?? [];
        
        List<String> insights = ['Analyzing your channel performance...'];
        if (topContent.isNotEmpty) {
          insights = [];
          // Insight 1: growth
          insights.add('📈 Your content reached $totalViews total views — growth is $growth this month');
          // Insight 2: post streak
          if (streak > 0) {
            insights.add('🔥 You\'re on a $streak-day posting streak — keep it up!');
          }
          // Insight 3: top video
          final ytVideos = topContent.where((c) => c['platform'] == 'YouTube').toList();
          if (ytVideos.isNotEmpty) {
            // Sort by viewsNum to get top performer
            ytVideos.sort((a, b) => (b['viewsNum'] ?? 0).compareTo(a['viewsNum'] ?? 0));
            final topVideo = ytVideos.first;
            insights.add('🏆 Top video: "${topVideo['title'] ?? ''}\" with ${topVideo['views'] ?? '0'} views');
          }
          // Insight 4: best time to post (static for now)
          insights.add('⏰ Best time to post today: 6:00 PM — 9:00 PM for maximum reach');
          // Insight 5: trending topic
          insights.add('🚀 Trending topic detected: AI Tools for Creators — consider making a video now');
        }

        Set<PlatformType> connectedPlatformTypes = {};
        for (var p in platforms) {
          if (p['isConnected'] == true) {
            if (p['name'] == 'YouTube') connectedPlatformTypes.add(PlatformType.youtube);
            if (p['name'] == 'Instagram') connectedPlatformTypes.add(PlatformType.instagram);
            if (p['name'] == 'LinkedIn') connectedPlatformTypes.add(PlatformType.linkedin);
            if (p['name'] == 'Facebook') connectedPlatformTypes.add(PlatformType.facebook);
          }
        }

    List<Widget> appBarActions = [
      Padding(
        padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MultiPostHubScreen(initialPlatforms: connectedPlatformTypes)),
            );
          },
          icon: const Icon(Icons.upload, size: 18),
          label: const Text('Upload'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
    ];

    for (var p in platforms) {
      if (p['isConnected'] == true) {
        IconData iconData = Icons.public; Color color = Colors.white;
        if (p['name'] == 'YouTube') { iconData = Icons.play_circle_fill; color = Colors.red; }
        if (p['name'] == 'Instagram') { iconData = Icons.camera_alt; color = Colors.pink; }
        if (p['name'] == 'LinkedIn') { iconData = Icons.business; color = Colors.blue; }
        appBarActions.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4), 
          child: Icon(iconData, color: color, size: 20)
        ));
      }
    }

    appBarActions.add(
      TextButton.icon(
        onPressed: () {
          setState(() { _showConnectView = true; });
        },
        icon: const Icon(Icons.add_link, color: Colors.purpleAccent, size: 20),
        label: const Text('Connect', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
      )
    );

    appBarActions.add(const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: CircleAvatar(child: Icon(Icons.person)),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi, Vasanth 🏠', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: appBarActions,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CreatorOverviewCard(
              data: data,
              platforms: platforms,
              onPostRequested: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MultiPostHubScreen(initialPlatforms: connectedPlatformTypes)),
                );
              },
            ),
            const SizedBox(height: 20),
            PlatformAnalyticsSlider(platforms: platforms),
            const SizedBox(height: 20),
            AIUpdateTicker(updates: insights),
            const SizedBox(height: 20),
            ...() {
                final list = (data['topContent'] as List?);
                final ytList = list?.where((c) => c['platform'] == 'YouTube').toList();
                final igList = list?.where((c) => c['platform'] == 'Instagram').toList();

                return [
                  if (ytList != null && ytList.isNotEmpty) ...[
                    const SectionHeader(title: 'Latest YouTube Content'),
                    ContentSection(platform: 'YouTube', contentList: ytList),
                    const SizedBox(height: 20),
                  ],
                  if (igList != null && igList.isNotEmpty) ...[
                    const SectionHeader(title: 'Latest Instagram Content'),
                    ContentSection(platform: 'Instagram', contentList: igList),
                    const SizedBox(height: 20),
                  ],
                  if ((ytList == null || ytList.isEmpty) && (igList == null || igList.isEmpty)) ...[
                    const SectionHeader(title: 'Latest Content'),
                    ContentSection(platform: 'YouTube'),
                    const SizedBox(height: 20),
                  ],
                ];
              }(),
            const SectionHeader(title: 'Scheduled Content 🤖'),
            const Placeholder(fallbackHeight: 100), // To be implemented
            const SizedBox(height: 20),
            const CreatorScoreWidget(),
          ],
        ),
      ),
    );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
