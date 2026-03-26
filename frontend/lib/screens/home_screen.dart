import 'package:flutter/material.dart';
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
        
        // Mocking some AI updates based on the streak or growth
        List<String> insights = [
            'Your reel engagement increased by ${data['growth'] ?? '0%'} this week',
            'Best time to post today: 7:00 PM',
            'Trending topic detected: AI Tools Explained'
        ];

    List<Widget> appBarActions = [
      IconButton(icon: const Icon(Icons.publish), onPressed: () {}),
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
            CreatorOverviewCard(data: data),
            const SizedBox(height: 20),
            PlatformAnalyticsSlider(platforms: platforms),
            const SizedBox(height: 20),
            AIUpdateTicker(updates: insights),
            const SizedBox(height: 20),
            if (data['topContent'] != null && (data['topContent'] as List).isNotEmpty)
              ...() {
                final list = data['topContent'] as List;
                final yt = list.firstWhere((c) => c['platform'] == 'YouTube', orElse: () => null);
                final ig = list.firstWhere((c) => c['platform'] == 'Instagram', orElse: () => null);
                
                return [
                  if (yt != null) Column(children: [
                    const SectionHeader(title: 'Latest YouTube Content'),
                    ContentSection(platform: 'YouTube', contentData: yt),
                    const SizedBox(height: 20),
                  ]),
                  if (ig != null) Column(children: [
                    const SectionHeader(title: 'Latest Instagram Content'),
                    ContentSection(platform: 'Instagram', contentData: ig),
                    const SizedBox(height: 20),
                  ]),
                  if (yt == null && ig == null) const Text('No recent content found'),
                ];
              }()
            else
              const Column(
                children: [
                   SectionHeader(title: 'Latest YouTube Content'),
                   ContentSection(platform: 'YouTube'), // Fallback/Mock
                   SizedBox(height: 20),
                   SectionHeader(title: 'Latest Instagram Content'),
                   ContentSection(platform: 'Instagram'), // Fallback/Mock
                   SizedBox(height: 20),
                ]
              ),
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
