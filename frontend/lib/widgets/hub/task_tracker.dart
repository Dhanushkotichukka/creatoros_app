import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'candy_progress_bar.dart';
import '../../utils/app_colors.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TaskTracker extends StatefulWidget {
  const TaskTracker({super.key});

  @override
  State<TaskTracker> createState() => _TaskTrackerState();
}

class _TaskTrackerState extends State<TaskTracker> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  bool _showAllTasks = false;

  List<Map<String, dynamic>> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('multihub_tasks');
    if (tasksJson != null) {
      final List<dynamic> decoded = json.decode(tasksJson);
      setState(() {
        _allTasks = decoded.map((e) => {
          'id': e['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'title': e['title'],
          'tag': e['tag'],
          'isCompleted': e['isCompleted'],
          'date': DateTime.parse(e['date']),
          'time': e['time'] ?? '10:00 AM',
        }).toList();
      });
    } else {
      // Default tasks if empty
      setState(() {
        _allTasks = [
          {'id': '1', 'title': 'Edit Reel', 'tag': 'Instagram', 'isCompleted': true, 'date': DateTime.now(), 'time': '10:00 AM'},
          {'id': '2', 'title': 'Upload Short', 'tag': 'YouTube', 'isCompleted': false, 'date': DateTime.now(), 'time': '04:00 PM'},
        ];
        _saveTasks();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> toSave = _allTasks.map((e) => {
      'id': e['id'],
      'title': e['title'],
      'tag': e['tag'],
      'isCompleted': e['isCompleted'],
      'date': (e['date'] as DateTime).toIso8601String(),
      'time': e['time'],
    }).toList();
    await prefs.setString('multihub_tasks', json.encode(toSave));
  }

  static const Map<String, Color> _tagColors = {
    'Instagram': Color(0xFFE91E8C),
    'YouTube':   Color(0xFFFF0000),
    'TikTok':    Color(0xFF000000),
    'Twitter':   Color(0xFF1DA1F2),
    'Facebook':  Color(0xFF1877F2),
    'General':   Color(0xFF607D8B),
    'Strategy':  Color(0xFF9C27B0),
    'Editing':   Color(0xFF795548),
    'Script':    Color(0xFF009688),
  };

  Color _tagColor(String tag) => _tagColors[tag] ?? const Color(0xFF607D8B);

  void _showAddTaskSheet() {
    final titleCtrl = TextEditingController();
    String selectedTag = 'General';
    final tags = ['General', 'YouTube', 'Instagram', 'TikTok', 'Twitter', 'Strategy', 'Editing', 'Script'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Task · ${DateFormat('dd MMM').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        setState(() {
                          _allTasks.add({
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'title': titleCtrl.text.trim(),
                            'tag': selectedTag,
                            'isCompleted': false,
                            'date': _selectedDate,
                            'time': DateFormat('hh:mm a').format(DateTime.now()),
                          });
                          _saveTasks();
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Task title...',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Platform / Tag', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    final isSelected = selectedTag == tag;
                    final color = _tagColor(tag);
                    return GestureDetector(
                      onTap: () => setModal(() => selectedTag = tag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(isSelected ? 1.0 : 0.3)),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.1);

    final todayTasks = _allTasks.where((t) {
      final d = t['date'] as DateTime;
      return d.year == _selectedDate.year &&
             d.month == _selectedDate.month &&
             d.day == _selectedDate.day;
    }).toList();

    final completedCount = todayTasks.where((t) => t['isCompleted']).length;
    final progress = todayTasks.isEmpty ? 0.0 : completedCount / todayTasks.length;
    final isToday = _selectedDate.year == DateTime.now().year &&
                    _selectedDate.month == DateTime.now().month &&
                    _selectedDate.day == DateTime.now().day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isToday ? "Today's Tasks" : DateFormat('dd MMM').format(_selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (todayTasks.isNotEmpty)
              Row(
                children: [
                  Text(
                    '$completedCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' / ${todayTasks.length} Completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Task Container (Hero Box) ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111), // Darkest background
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.05),
                const Color(0xFF111111),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // ── Progress bar section ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Overall Progress',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              ),
                              Text(
                                '$completedCount of ${todayTasks.length} tasks done',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final width = constraints.maxWidth * progress;
                                          return Container(
                                            width: width,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                              gradient: LinearGradient(
                                                colors: [
                                                  theme.colorScheme.primary.withOpacity(0.6),
                                                  theme.colorScheme.primary,
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: theme.colorScheme.primary.withOpacity(0.8),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      // Faked sparks effect using small blurred dots below the progress bar
                                      if (progress > 0)
                                        Positioned(
                                          bottom: -8,
                                          left: 0,
                                          right: 0,
                                          child: Opacity(
                                            opacity: 0.6,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: List.generate(
                                                (progress * 5).toInt().clamp(0, 5), 
                                                (index) => Container(
                                                  width: 3, height: 3,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [BoxShadow(color: theme.colorScheme.primary, blurRadius: 4, spreadRadius: 2)],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Add Task Button
                    GestureDetector(
                      onTap: _showAddTaskSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.8), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Add Task',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Colors.white10),

              if (todayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                      const SizedBox(height: 12),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Add Task" to start planning.',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      ),
                    ],
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Column(
                    children: [
                      ...(_showAllTasks ? todayTasks : todayTasks.take(3))
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => _buildTaskItem(e.value, theme, e.key)),
                    ],
                  ),
                ),
                if (todayTasks.length > 3)
                  GestureDetector(
                    onTap: () => setState(() => _showAllTasks = !_showAllTasks),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showAllTasks
                                ? 'Show less'
                                : '${todayTasks.length - 3} more tasks',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _showAllTasks
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, ThemeData theme, int index) {
    final bool isCompleted = task['isCompleted'];
    final Color tagColor = _tagColor(task['tag'] ?? 'General');

    return Dismissible(
      key: Key(task['id'] ?? task.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() {
          _allTasks.removeWhere((t) => t['id'] == task['id']);
          _saveTasks();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onTap: () => setState(() {
            task['isCompleted'] = !task['isCompleted'];
            _saveTasks();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: isCompleted
                    ? Colors.green.withOpacity(0.2)
                    : theme.colorScheme.onSurface.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => setState(() {
                    task['isCompleted'] = !task['isCompleted'];
                    _saveTasks();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green
                            : theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + tag
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task['tag'] ?? 'General',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? tagColor.withOpacity(0.4) : tagColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          if (!isCompleted)
                            Icon(Icons.calendar_today_rounded, size: 10,
                                color: Colors.white.withOpacity(0.5)),
                          if (!isCompleted) const SizedBox(width: 4),
                          Text(
                            task['time'] ?? '10:00 AM',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(isCompleted ? 0.2 : 0.4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
