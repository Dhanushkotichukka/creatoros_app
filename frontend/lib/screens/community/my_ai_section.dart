import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MyAISection extends StatelessWidget {
  const MyAISection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter Content Category (e.g. Technology)',
              prefixIcon: const Icon(Icons.category),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Viral Topics List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildTopicCard(context, 'Varanasi Movie — Full Story Explained', '95/100', Colors.green),
          _buildTopicCard(context, 'Bahubali Hidden Details', '89/100', Colors.green),
          _buildTopicCard(context, 'Best AI Editing Tools 2025', '82/100', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, String title, String score, Color scoreColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: scoreColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: Text('Trend Score: $score', style: TextStyle(fontSize: 10, color: scoreColor)),
            ),
            const SizedBox(width: 10),
            const Text('Medium Difficulty', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _showGenerateScriptDialog(context, title),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
          child: const Text('Generate Script', style: TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

  void _showGenerateScriptDialog(BuildContext context, String topic) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: ApiService.generateScript(topic),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating Script with Groq/Gemini...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('${snapshot.error}'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
            );
          } else {
            return AlertDialog(
              title: Text('Script for: $topic'),
              content: SingleChildScrollView(child: Text(snapshot.data ?? 'No script generated')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ElevatedButton(onPressed: () {}, child: const Text('Copy to Hub')),
              ],
            );
          }
        },
      ),
    );
  }
}
