import 'package:flutter/material.dart';

class TaskTracker extends StatelessWidget {
  const TaskTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today\'s Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Yesterday | Tomorrow', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        _buildTaskItem('Edit Reel', 'Instagram', true),
        _buildTaskItem('Upload Short', 'YouTube', false),
        _buildTaskItem('Write Script', 'General', false),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
        ),
      ],
    );
  }

  Widget _buildTaskItem(String title, String tag, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isCompleted,
        onChanged: (val) {},
        title: Text(title, style: TextStyle(decoration: isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.deepPurpleAccent)),
        secondary: const Icon(Icons.task_alt, size: 20),
      ),
    );
  }
}
