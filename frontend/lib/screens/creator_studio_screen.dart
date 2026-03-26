import 'package:flutter/material.dart';
import '../widgets/studio/quick_buttons.dart';
import '../widgets/studio/ai_creative_tools.dart';

class CreatorStudioScreen extends StatelessWidget {
  const CreatorStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
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
            _buildProjectCard('Bahubali Edit', '2 hours ago', Icons.movie),
            _buildProjectCard('AI Thumbnail', 'Yesterday', Icons.image),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Create New Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(String title, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.deepPurpleAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Last edited: $time', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.play_arrow, color: Colors.white70),
        onTap: () {},
      ),
    );
  }
}
