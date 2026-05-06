import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_colors.dart';

class PieChartDataPoint {
  final String label;
  final double value;
  final Color color;

  PieChartDataPoint(this.label, this.value, this.color);
}

class ReusablePieChart extends StatefulWidget {
  final List<PieChartDataPoint> data;
  final String title;

  const ReusablePieChart({
    Key? key,
    required this.data,
    this.title = '',
  }) : super(key: key);

  @override
  State<ReusablePieChart> createState() => _ReusablePieChartState();
}

class _ReusablePieChartState extends State<ReusablePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()!;
    
    if (widget.data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty) ...[
          Text(widget.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(widget.data.length, (i) {
                      final isTouched = i == touchedIndex;
                      final fontSize = isTouched ? 16.0 : 12.0;
                      final radius = isTouched ? 60.0 : 50.0;
                      final item = widget.data[i];
                      
                      return PieChartSectionData(
                        color: item.color,
                        value: item.value,
                        title: '${item.value.toInt()}%',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xffffffff),
                          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.data.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.label} (${item.value.toInt()}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
