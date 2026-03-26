import 'package:flutter/material.dart';

class AICreativeTools extends StatelessWidget {
  const AICreativeTools({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAIToolCard('Text → Video', Icons.movie_creation, 'Generate video from text.'),
          _buildAIToolCard('Text → Image', Icons.brush, 'Generate thumbnails from text.'),
          _buildAIToolCard('BG Removal', Icons.content_cut, 'One-tap background removal.'),
          _buildAIToolCard('Auto Caption', Icons.subtitles, 'Subtitles from audio.'),
        ],
      ),
    );
  }

  Widget _buildAIToolCard(String title, IconData icon, String desc) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurpleAccent),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
