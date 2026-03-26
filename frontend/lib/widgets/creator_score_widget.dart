import 'package:flutter/material.dart';

class CreatorScoreWidget extends StatelessWidget {
  const CreatorScoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Creator Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Level Up Your Profile', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(value: 0.82, color: Colors.green, strokeWidth: 6),
                    ),
                    const Text('82', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ScoreItem(label: 'Consistency', score: '90'),
                ScoreItem(label: 'Engagement', score: '75'),
                ScoreItem(label: 'Frequency', score: '85'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreItem extends StatelessWidget {
  final String label;
  final String score;
  const ScoreItem({super.key, required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(score, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
