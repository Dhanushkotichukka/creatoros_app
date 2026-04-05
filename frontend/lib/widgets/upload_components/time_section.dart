import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/post_provider.dart';

class TimeSection extends StatelessWidget {
  const TimeSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final activePost = provider.activePost;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () {
                    context.read<PostProvider>().setScheduledTime(null);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: activePost.scheduledTime == null
                        ? Colors.blueAccent.withAlpha(Theme.of(context).brightness == Brightness.dark ? 50 : 30)
                        : null,
                    side: BorderSide(
                      color: activePost.scheduledTime == null
                          ? Colors.blueAccent
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Publish now'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _pickDateTime(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: activePost.scheduledTime != null
                        ? Colors.blueAccent.withAlpha(Theme.of(context).brightness == Brightness.dark ? 50 : 30)
                        : null,
                    side: BorderSide(
                      color: activePost.scheduledTime != null
                          ? Colors.blueAccent
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    activePost.scheduledTime != null
                        ? DateFormat('MMM dd, HH:mm').format(activePost.scheduledTime!)
                        : 'Schedule',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && context.mounted) {
        final scheduled = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        context.read<PostProvider>().setScheduledTime(scheduled);
      }
    }
  }
}
