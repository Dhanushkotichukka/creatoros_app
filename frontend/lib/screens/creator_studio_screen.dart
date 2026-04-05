import 'package:flutter/material.dart';
import '../widgets/studio/quick_buttons.dart';
import '../widgets/studio/ai_creative_tools.dart';

class CreatorStudioScreen extends StatelessWidget {
  const CreatorStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Creator Studio', style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const QuickButtons(),
            const SizedBox(height: 30),
            const Text('AI Creative Tools 🤖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const AICreativeTools(),
            const SizedBox(height: 30),
            const Text('Recent Creative Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildProjectCard(context, 'Bahubali Edit', '2 hours ago', Icons.movie),
            _buildProjectCard(context, 'AI Thumbnail', 'Yesterday', Icons.image),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Create New Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, String title, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('Last edited: $time', style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
