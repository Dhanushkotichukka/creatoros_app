import 'package:flutter/material.dart';

class AISuggestions extends StatelessWidget {
  final List<String> suggestions;

  const AISuggestions({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent),
            SizedBox(width: 8),
            Text('AI Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        if (suggestions.isEmpty)
          const Text('No new insights at this time.', style: TextStyle(color: Colors.grey))
        else
          ...suggestions.map((s) => _buildSuggestionCard(s, icon: Icons.insights)).toList(),
      ],
    );
  }

  Widget _buildSuggestionCard(String text, {required IconData icon, Color color = Colors.deepPurpleAccent}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, size: 16),
        onTap: () {},
      ),
    );
  }
}
