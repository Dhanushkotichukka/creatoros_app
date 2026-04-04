import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../screens/publishing_progress_screen.dart';

class ActionsSection extends StatelessWidget {
  const ActionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final activePost = provider.activePost;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () async {
              await context.read<PostProvider>().saveAsDraft();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved to Drafts')),
                );
                Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              side: BorderSide(color: Colors.grey.shade700, width: 2),
            ),
            child: const Text('Drafts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              if (activePost.mediaPaths.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload media first')));
                 return;
              }

              final isScheduling = activePost.scheduledTime != null;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PublishingProgressScreen(
                    provider: provider,
                    isScheduling: isScheduling,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              backgroundColor: activePost.scheduledTime != null ? Colors.orange : Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              activePost.scheduledTime != null ? 'Schedule' : 'Publish',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
