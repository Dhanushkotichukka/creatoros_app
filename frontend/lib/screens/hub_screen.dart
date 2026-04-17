import 'package:flutter/material.dart';
import '../widgets/hub/task_tracker.dart';
import '../widgets/hub/storage_manager.dart';
import 'media_search_screen.dart';
import 'notes_screen.dart';
import 'ai_chat_screen.dart';
import 'content_planner_screen.dart';
import '../utils/responsive.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = Responsive.of(context);
    
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Text('MultiHUB', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MediaSearchScreen())),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Search...',
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: r.contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // 1. TODAY'S TASKS
          const TaskTracker(),
          const SizedBox(height: 32),

          // 2. CONTENT PLAN
          const Text('Content plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildContentPlanItem(context, Icons.note, 'Notes', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen()));
          }),
          _buildContentPlanItem(context, Icons.chat, 'AI chat', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatScreen()));
          }),
          _buildContentPlanItem(context, Icons.calendar_today, 'Content planner', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ContentPlannerScreen()));
          }),
          const SizedBox(height: 32),

          // 3. STORAGE MANAGER
          const StorageManager(),
          const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPlanItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(30),
        color: theme.colorScheme.surface,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
