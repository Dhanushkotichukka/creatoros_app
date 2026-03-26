import 'package:flutter/material.dart';
import '../widgets/hub/media_search_bar.dart';
import '../widgets/hub/task_tracker.dart';
import '../widgets/hub/storage_manager.dart';
import '../screens/media_search_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/content_planner_screen.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MediaSearchScreen())),
                child: const IgnorePointer(child: MediaSearchBar()),
            ),
            const SizedBox(height: 20),
            const TaskTracker(),
            const SizedBox(height: 20),
            const StorageManager(),
            const SizedBox(height: 20),
            _buildActionCard(context, 'Notes', Icons.note_add, 'Your idea vault and script drafts.', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen()));
            }),
            const SizedBox(height: 10),
            _buildActionCard(context, 'AI Chat', Icons.chat_bubble_outline, 'Ask AI for hooks, stories, and plans.', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatScreen()));
            }),
            const SizedBox(height: 10),
            _buildActionCard(context, 'Content Planner', Icons.calendar_month, 'Your visual content calendar.', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContentPlannerScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
