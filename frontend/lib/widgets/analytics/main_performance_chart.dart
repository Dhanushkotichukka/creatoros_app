import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MainPerformanceChart extends StatefulWidget {
  final Map<String, dynamic> data;
  const MainPerformanceChart({super.key, required this.data});

  @override
  State<MainPerformanceChart> createState() => _MainPerformanceChartState();
}

class _MainPerformanceChartState extends State<MainPerformanceChart> {
  bool _showRawData = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final graphData = widget.data['graphData'] as Map<String, dynamic>? ?? {};
    final List<dynamic> rawViews = graphData['views'] as List? ?? [];
    final List<dynamic> rawDates = graphData['dates'] as List? ?? [];

    if (_showRawData) {
      return GestureDetector(
        onLongPress: () => setState(() => _showRawData = false),
        child: Container(
          height: 350,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Raw Data (Tap & Hold to switch back)', style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: rawViews.length,
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    title: Text(rawDates[i].toString()),
                    trailing: Text(rawViews[i].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<FlSpot> spots = [];
    for (int i = 0; i < rawViews.length; i++) {
       spots.add(FlSpot(i.toDouble(), (rawViews[i] as num).toDouble()));
    }

    if (spots.isEmpty) {
      for (int i = 0; i < 7; i++) spots.add(FlSpot(i.toDouble(), 0));
    }

    final double maxY = spots.isEmpty ? 100 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;
    final double safeMaxY = maxY <= 0 ? 100 : maxY;

    return GestureDetector(
      onLongPress: () => setState(() => _showRawData = true),
      child: Container(
        height: 350,
        padding: const EdgeInsets.fromLTRB(10, 40, 20, 10),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: safeMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: safeMaxY > 0 ? safeMaxY / 5 : 20,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.dividerColor.withOpacity(0.05),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final int index = value.toInt();
                    if (index >= 0 && index < rawDates.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          rawDates[index].toString().toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 1),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 32,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    String text = '';
                    if (value >= 1000000) text = '${(value / 1000000).toStringAsFixed(1)}M';
                    else if (value >= 1000) text = '${(value / 1000).toStringAsFixed(1)}K';
                    else text = value.toInt().toString();
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                    );
                  },
                  reservedSize: 45,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.primary.withOpacity(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => theme.colorScheme.surface,
                tooltipRoundedRadius: 12,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    return LineTooltipItem(
                      '${barSpot.y.toInt()} Views',
                      TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
