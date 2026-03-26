import 'package:flutter/material.dart';
import 'creator_health.dart';

class PerformanceCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const PerformanceCard({super.key, required this.data});

  @override
  State<PerformanceCard> createState() => _PerformanceCardState();
}

class _PerformanceCardState extends State<PerformanceCard> {
  bool _isQuickSummary = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isQuickSummary = !_isQuickSummary;
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          height: 250,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Overall Health', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    CreatorHealth(
                      engagementRate: (widget.data['engagementRate'] ?? 0.06).toDouble(),
                      streakDays: widget.data['streak'] ?? 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, color: Colors.grey[800]),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _isQuickSummary ? _buildQuickSummary() : _buildGraphPlaceholder(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGraphPlaceholder() {
    final String views = widget.data['totalViews'] ?? '0';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Performance Graph', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        const Icon(Icons.show_chart, size: 80, color: Colors.deepPurpleAccent),
        const SizedBox(height: 20),
        Text('Views: $views', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickSummary() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Quick Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SummaryItem(label: 'Total Views', value: widget.data['totalViews'] ?? '—'),
        SummaryItem(label: 'Total Likes', value: widget.data['totalLikes'] ?? '—'),
        SummaryItem(label: 'Subscribers', value: widget.data['subscribers'] ?? '—'),
        SummaryItem(label: 'Videos', value: widget.data['videos'] ?? '—'),
        SummaryItem(label: 'Watch Time', value: widget.data['watchTime'] ?? '—'),
        SummaryItem(label: 'Growth', value: widget.data['growth'] ?? '—'),
      ],
    );
  }
}

class SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const SummaryItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
