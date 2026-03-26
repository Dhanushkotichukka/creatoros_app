import 'package:flutter/material.dart';

class GroupsSection extends StatelessWidget {
  const GroupsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Groups',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(icon: const Icon(Icons.group_add), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Social Platform Updates 🤖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildUpdateItem('Instagram', 'New Reel algorithm changes detected.', Icons.camera_alt, Colors.pink),
          _buildUpdateItem('YouTube', 'Shorts monetisation expansion announced.', Icons.play_circle_fill, Colors.red),
          const SizedBox(height: 20),
          const Text('Your Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const ListTile(
            leading: CircleAvatar(child: Text('MB')),
            title: Text('Movie Breakdown Creators'),
            subtitle: Text('1.2K Members • 15 active now'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateItem(String platform, String text, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(platform, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(text),
        trailing: const Text('Now', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ),
    );
  }
}
