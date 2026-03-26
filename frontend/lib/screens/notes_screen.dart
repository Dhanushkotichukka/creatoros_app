import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Idea Vault'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildNoteCard('Script Draft: Vlogging Tips', 'Remember to talk about the Rule of Thirds.', 'Today, 2:00 PM', Colors.deepPurple.shade900),
                  _buildNoteCard('Video Ideas', '1. A day in the life\n2. Setup Reveal\n3. Q&A', 'Yesterday', Colors.grey.shade900),
                  _buildNoteCard('Sponsored Read', 'Make sure to mention the 20% off code at the intro.', 'Nov 12', Colors.blueGrey.shade900),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteCard(String title, String preview, String date, Color color) {
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        isThreeLine: true,
        onTap: () {},
      ),
    );
  }
}
