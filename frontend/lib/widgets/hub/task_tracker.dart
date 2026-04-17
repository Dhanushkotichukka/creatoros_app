import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'candy_progress_bar.dart';

class TaskTracker extends StatefulWidget {
  const TaskTracker({super.key});

  @override
  State<TaskTracker> createState() => _TaskTrackerState();
}

class _TaskTrackerState extends State<TaskTracker> {
  DateTime _selectedDate = DateTime.now();
  bool _showAllTasks = false;

  final List<Map<String, dynamic>> _allTasks = [
    {'title': 'Edit Reel', 'tag': 'Instagram', 'isCompleted': true, 'date': DateTime.now()},
    {'title': 'Upload Short', 'tag': 'YouTube', 'isCompleted': false, 'date': DateTime.now()},
    {'title': 'Write Script', 'tag': 'General', 'isCompleted': false, 'date': DateTime.now()},
    {'title': 'Review Analytics', 'tag': 'Strategy', 'isCompleted': false, 'date': DateTime.now().add(const Duration(days: 1))},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.1);

    // Filter Tasks for selected date
    final todayTasks = _allTasks.where((t) {
      final d = t['date'] as DateTime;
      return d.year == _selectedDate.year &&
             d.month == _selectedDate.month &&
             d.day == _selectedDate.day;
    }).toList();

    final completedCount = todayTasks.where((t) => t['isCompleted']).length;
    final progress = todayTasks.isEmpty ? 0.0 : completedCount / todayTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Today Task's", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CandyProgressBar(
                  value: progress,
                  duration: const Duration(milliseconds: 1500),
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                  child: Icon(Icons.chevron_left, size: 20, color: theme.colorScheme.primary),
                ),
                Text(' ${DateFormat('dd/MMM').format(_selectedDate)} ', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                GestureDetector(
                  onTap: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                  child: Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (todayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No tasks assigned', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                )
              else
                ...(_showAllTasks ? todayTasks : todayTasks.take(2)).map((task) => _buildTaskItem(task, theme)),
              
              if (todayTasks.length > 2)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAllTasks = !_showAllTasks),
                    icon: Icon(_showAllTasks ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16),
                    label: Text(_showAllTasks ? 'less' : 'all'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, ThemeData theme) {
    bool isCompleted = task['isCompleted'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        ),
        tileColor: theme.colorScheme.surface,
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
        title: Text(
          task['title'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(task['tag'], style: TextStyle(fontSize: 11, color: theme.colorScheme.primary.withOpacity(0.8))),
        trailing: Icon(Icons.more_vert, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        onTap: () {
          setState(() {
            task['isCompleted'] = !task['isCompleted'];
          });
        },
      ),
    );
  }
}
