import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_colors.dart';

class ReusableBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String title;
  final Color? barColor;
  final bool isHorizontal;

  const ReusableBarChart({
    Key? key,
    required this.values,
    required this.labels,
    this.title = '',
    this.barColor,
    this.isHorizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    final color = barColor ?? theme.colorScheme.primary;
    
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
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY == 0 ? 10 : maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => theme.colorScheme.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${labels[group.x.toInt()]}\n${rod.toY.toInt()}',
                      TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) return const SizedBox.shrink();
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
              gridData: const FlGridData(show: false),
              barGroups: List.generate(
                values.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      color: color,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    )
                  ],
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
