import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Simple task model for local state
class _Task {
  final String id;
  String title;
  String description;
  bool isCompleted;
  final DateTime date;

  _Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.date,
  });
}

class ContentPlannerScreen extends StatefulWidget {
  const ContentPlannerScreen({super.key});

  @override
  State<ContentPlannerScreen> createState() => _ContentPlannerScreenState();
}

class _ContentPlannerScreenState extends State<ContentPlannerScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _viewMonth = DateTime.now();

  final List<_Task> _tasks = [
    _Task(
      id: '1',
      title: 'Record Setup Tour',
      description: 'YouTube reel about new desk setup',
      date: DateTime.now(),
    ),
    _Task(
      id: '2',
      title: 'Edit Vlog #12',
      description: 'Add B-roll transitions',
      isCompleted: true,
      date: DateTime.now(),
    ),
    _Task(
      id: '3',
      title: 'Post Instagram Reel',
      description: 'Schedule for 6 PM',
      date: DateTime.now().add(const Duration(days: 2)),
    ),
  ];

  List<_Task> get _todayTasks {
    return _tasks.where((t) =>
      t.date.year == _selectedDate.year &&
      t.date.month == _selectedDate.month &&
      t.date.day == _selectedDate.day
    ).toList();
  }

  bool _hasTaskOnDate(DateTime date) {
    return _tasks.any((t) =>
      t.date.year == date.year &&
      t.date.month == date.month &&
      t.date.day == date.day
    );
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Task title',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Text('Adding for: ${DateFormat('EEE, dd MMM').format(_selectedDate)}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              setState(() {
                _tasks.add(_Task(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  date: _selectedDate,
                ));
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.08);

    // Build days for the horizontal strip (30 days from current month start)
    final firstDayOfStrip = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Planner', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Month navigation header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() =>
                    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)),
                ),
                Text(DateFormat.yMMMM().format(_viewMonth),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() =>
                    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1)),
                ),
              ],
            ),
          ),

          // Horizontal date strip
          SizedBox(
            height: 86,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 30,
              itemBuilder: (_, i) {
                final date = DateTime(firstDayOfStrip.year, firstDayOfStrip.month, firstDayOfStrip.day + i);
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final hasTask = _hasTaskOnDate(date);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: isToday && !isSelected
                          ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                          : Border.all(color: borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.E().format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasTask
                                ? (isSelected ? Colors.white70 : Colors.green)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate.year == DateTime.now().year &&
                  _selectedDate.month == DateTime.now().month &&
                  _selectedDate.day == DateTime.now().day
                      ? "Today's Tasks"
                      : 'Tasks for ${DateFormat('EEE, dd MMM').format(_selectedDate)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('${_todayTasks.where((t) => t.isCompleted).length}/${_todayTasks.length} done',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tasks list
          Expanded(
            child: _todayTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_outlined, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                        const SizedBox(height: 16),
                        Text('No tasks for this day',
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _showAddTaskDialog,
                          child: Text('+ Add Task', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _todayTasks.length,
                    itemBuilder: (_, i) {
                      final task = _todayTasks[i];
                      return Dismissible(
                        key: Key(task.id),
                        onDismissed: (_) => setState(() => _tasks.removeWhere((t) => t.id == task.id)),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => task.isCompleted = !task.isCompleted),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: task.isCompleted
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: task.isCompleted
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: task.isCompleted
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                        color: task.isCompleted
                                            ? theme.colorScheme.onSurface.withOpacity(0.4)
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (task.description.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        task.description,
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(Icons.drag_handle, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
