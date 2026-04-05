import 'package:flutter/material.dart';
import '../widgets/analytics/main_performance_chart.dart';
import '../widgets/analytics/stat_grid.dart';
import '../widgets/analytics/ai_suggestions.dart';
import '../widgets/analytics/platform_deep_view.dart';
import '../widgets/analytics/top_content_list.dart';
import '../widgets/analytics/real_time_data.dart';
import '../widgets/connect_platforms_view.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/view_state_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPlatform = 'Overview';
  late Future<Map<String, dynamic>> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = ApiService.getAnalyticsOverview();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      icon: Icon(Icons.add_link, color: theme.colorScheme.primary), 
                      onPressed: () {
                        context.read<ViewStateProvider>().setShowConnectView(true);
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
          
          final viewState = context.watch<ViewStateProvider>();
          
          if (_selectedPlatform == 'Overview') {
            final connectedPlatforms = platforms.where((p) => p['isConnected'] == true).toList();
            if (connectedPlatforms.isEmpty || viewState.showConnectView) {
              return ConnectPlatformsView(onConnected: () => setState(() {
                _analyticsFuture = ApiService.getAnalyticsOverview();
                viewState.setShowConnectView(false);
              }));
            }
          }

          if (viewState.showConnectView) {
             return ConnectPlatformsView(onConnected: () => setState(() {
                _analyticsFuture = ApiService.getAnalyticsOverview();
                viewState.setShowConnectView(false);
             }));
          }

          if (_selectedPlatform != 'Overview') {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: PlatformDeepView(platform: _selectedPlatform, data: data),
            );
          }

          List<String> aiInsights = [
            'Your reel engagement increased by ${data['growth'] ?? '0%'} this week',
            'Best time to post today: based on your audience activity pattern',
            'Your posting velocity has improved your overall Creator Score to ${data['creatorScore'] ?? 80}/100'
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Track your performance across all platforms', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Widget'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.onSurface,
                        foregroundColor: theme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                StatGrid(data: data),
                const SizedBox(height: 32),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Analytics Overview', style: theme.textTheme.titleMedium),
                            DropdownButton<String>(
                              value: 'This year',
                              onChanged: (v) {},
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'This year', child: Text('This year')),
                                DropdownMenuItem(value: 'This month', child: Text('This month')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      MainPerformanceChart(data: data),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Top Content'),
                          const SizedBox(height: 12),
                          TopContentList(topContent: data['topContent'] as List<dynamic>? ?? []),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'AI Insights'),
                          const SizedBox(height: 12),
                          AISuggestions(suggestions: aiInsights),
                          const SizedBox(height: 24),
                          const SectionHeader(title: 'Real-Time'),
                          const SizedBox(height: 12),
                          RealTimeDataCard(data: data['realTimeData'] as Map<String, dynamic>?),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon}) {
    final theme = Theme.of(context);
    bool isSelected = _selectedPlatform == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary) : null,
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
        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
        labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
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
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text('View All')),
      ],
    );
  }
}
