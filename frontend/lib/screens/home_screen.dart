import 'package:flutter/material.dart';
import 'multi_post_hub_screen.dart';
import '../models/multi_post/platform_type.dart';

import '../widgets/creator_overview_card.dart';
import '../widgets/platform_analytics_slider.dart';
import '../widgets/ai_update_ticker.dart';
import '../widgets/content_section.dart';
import '../widgets/creator_score_widget.dart';
import '../widgets/connect_platforms_view.dart';
import '../widgets/profile_panel.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/view_state_provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _analyticsFuture;
  int _lastProcessedTrigger = 0;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = ApiService.getAnalyticsOverview();
  }

  void _refreshData() {
    setState(() {
      _analyticsFuture = ApiService.getAnalyticsOverview();
    });
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
        
        final viewState = context.watch<ViewStateProvider>();

        // Check if the home reset trigger has changed (from BottomNav click or external signal)
        if (viewState.homeResetTrigger > _lastProcessedTrigger) {
          _lastProcessedTrigger = viewState.homeResetTrigger;
          // Defer the state change to avoid "build phase" errors
          Future.microtask(() => _refreshData());
        }

        if (platforms.isEmpty) {
          return ConnectPlatformsView(onConnected: () => _refreshData());
        }

        if (viewState.showConnectView) {
          return ConnectPlatformsView(onConnected: () {
            _refreshData();
            viewState.setShowConnectView(false);
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

    List<Widget> appBarActions = [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uploadBg = isDark ? const Color(0xFF6C63FF) : const Color(0xFFFF6A3D);

    appBarActions.add(
      Padding(
        padding: const EdgeInsets.only(right: 4.0, top: 8.0, bottom: 8.0),
        child: ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MultiPostHubScreen(initialPlatforms: connectedPlatformTypes)),
            );
            _refreshData();
          },
          icon: const Icon(Icons.upload, size: 18),
          label: const Text('Upload'),
          style: ElevatedButton.styleFrom(
            backgroundColor: uploadBg,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
    appBarActions.add(IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}));


    for (var p in platforms) {
      if (p['isConnected'] == true) {
        IconData iconData = Icons.public; Color color = Colors.white;
        if (p['name'] == 'YouTube') { iconData = Icons.play_circle_fill; color = Colors.red; }
        if (p['name'] == 'Instagram') { iconData = Icons.camera_alt; color = Colors.pink; }
        if (p['name'] == 'LinkedIn') { iconData = Icons.business; color = Colors.blue; }
        appBarActions.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4), 
          child: Icon(iconData, color: color.withOpacity(0.8), size: 18)
        ));
      }
    }

    appBarActions.add(
      TextButton.icon(
        onPressed: () {
          context.read<ViewStateProvider>().setShowConnectView(true);
        },
        icon: Icon(Icons.add_link, color: Theme.of(context).colorScheme.primary, size: 20),
        label: Text('Connect', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
      )
    );

    appBarActions.add(
      Padding(
        padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
        child: GestureDetector(
          onTap: () => showProfilePanel(context),
          child: _ProfileAvatar(),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, Vasanth 👋', style: Theme.of(context).textTheme.titleLarge),
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
                final list = (data['topContent'] as List? ?? []);
                final connectedPlatforms = platforms.where((p) => p['isConnected'] == true).toList();

                if (connectedPlatforms.isEmpty) {
                  return [
                    const SectionHeader(title: 'Latest Content'),
                    const ContentSection(platform: 'YouTube'),
                    const SizedBox(height: 20),
                  ];
                }

                return connectedPlatforms.map((p) {
                  final pName = p['name'];
                  final pContent = list.where((c) => c['platform'] == pName).toList();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: 'Latest $pName Content'),
                      ContentSection(platform: pName, contentList: pContent),
                      const SizedBox(height: 20),
                    ],
                  );
                }).toList();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

/// Gradient pulsing avatar shown in the home AppBar.
class _ProfileAvatar extends StatefulWidget {
  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(_pulse.value * 0.4),
                blurRadius: 10 * _pulse.value,
                spreadRadius: 1 * _pulse.value,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'V',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
