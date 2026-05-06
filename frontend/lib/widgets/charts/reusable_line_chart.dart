import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_colors.dart';

class ReusableLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String title;
  final bool showPoints;

  const ReusableLineChart({
    Key? key,
    required this.values,
    required this.labels,
    this.title = '',
    this.showPoints = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    
    if (values.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final double maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                      // Only show a few labels to prevent crowding
                      if (labels.length > 7 && index % (labels.length ~/ 5) != 0) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          labels[index],
                          style: TextStyle(color: c.textSecondary, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        _formatNumber(value),
                        style: TextStyle(color: c.textSecondary, fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (values.length - 1).toDouble(),
              minY: 0,
              maxY: maxY == 0 ? 10 : maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: showPoints),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withOpacity(0.15),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => theme.colorScheme.surface,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      return LineTooltipItem(
                        '${labels[touchedSpot.x.toInt()]}\n${_formatNumber(touchedSpot.y)}',
                        TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toInt().toString();
  }
}
