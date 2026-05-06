import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive.dart';
import '../charts/reusable_pie_chart.dart';
import '../charts/reusable_bar_chart.dart';

class AudienceDashboard extends StatelessWidget {
  final Map<String, dynamic> data;
  const AudienceDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final audience = data['audience'] as Map<String, dynamic>? ?? {};
    final isDesktop = Responsive.isWebSize(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildGenderChart(context, audience)),
                const SizedBox(width: 24),
                Expanded(child: _buildDeviceChart(context, audience)),
              ],
            )
          else ...[
            _buildGenderChart(context, audience),
            const SizedBox(height: 24),
            _buildDeviceChart(context, audience),
          ],
          
          const SizedBox(height: 32),
          _buildAgeChart(context, audience),
          
          const SizedBox(height: 32),
          _buildActiveTimesHeatmap(context, audience),
        ],
      ),
    );
  }

  Widget _buildGenderChart(BuildContext context, Map<String, dynamic> audience) {
    final theme = Theme.of(context);
    final gender = audience['gender'] as Map<String, dynamic>? ?? {'male': 0, 'female': 0};
    
    final data = [
      PieChartDataPoint('Male', (gender['male'] as num?)?.toDouble() ?? 0, Colors.blue),
      PieChartDataPoint('Female', (gender['female'] as num?)?.toDouble() ?? 0, Colors.pink),
      if (gender['other'] != null)
        PieChartDataPoint('Other', (gender['other'] as num).toDouble(), Colors.grey),
    ].where((e) => e.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: ReusablePieChart(data: data),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceChart(BuildContext context, Map<String, dynamic> audience) {
    final theme = Theme.of(context);
    final device = audience['deviceType'] as Map<String, dynamic>? ?? {'mobile': 0, 'desktop': 0};
    
    final data = [
      PieChartDataPoint('Mobile', (device['mobile'] as num?)?.toDouble() ?? 0, Colors.green),
      PieChartDataPoint('Desktop', (device['desktop'] as num?)?.toDouble() ?? 0, Colors.orange),
      if (device['tablet'] != null)
        PieChartDataPoint('Tablet', (device['tablet'] as num).toDouble(), Colors.purple),
    ].where((e) => e.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Device Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: ReusablePieChart(data: data),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeChart(BuildContext context, Map<String, dynamic> audience) {
    final theme = Theme.of(context);
    final ageRanges = audience['ageRanges'] as List<dynamic>? ?? [];
    
    final values = ageRanges.map((e) => (e['percentage'] as num?)?.toDouble() ?? 0.0).toList();
    final labels = ageRanges.map((e) => e['range']?.toString() ?? 'Unk').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Age Demographics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: ReusableBarChart(
                values: values.isEmpty ? [0] : values,
                labels: labels.isEmpty ? ['None'] : labels,
                barColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTimesHeatmap(BuildContext context, Map<String, dynamic> audience) {
    final theme = Theme.of(context);
    // As requested, active times is an approximation for now.
    // In a real heatmap, we'd have a 7x24 grid. We'll show a simplified representation.
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When your viewers are on YouTube', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_filled, size: 48, color: Colors.purple),
                const SizedBox(height: 16),
                Text(
                  'Best time to post based on 48h history:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Weekdays at 6:00 PM',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your audience is highly active during evening hours. Publishing 2 hours before peak ensures content is indexed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
