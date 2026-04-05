import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/multi_post/post_model.dart';
import '../../providers/post_provider.dart';

class BottomSections extends StatelessWidget {
  const BottomSections({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Currently using empty list mocks for drafts and scheduled since Hive is removed
    final drafts = <PostModel>[];
    final scheduled = <PostModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: 'Last Scheduled Content',
          items: scheduled,
          emptyMessage: 'No scheduled posts yet.',
          isScheduled: true,
          context: context,
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: 'Last Drafts',
          items: drafts,
          emptyMessage: 'No drafts available.',
          isScheduled: false,
          context: context,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<PostModel> items,
    required String emptyMessage,
    required bool isScheduled,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('View all', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  emptyMessage, 
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey.shade600)
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.take(3).length,
                itemBuilder: (context, index) {
                  return const SizedBox.shrink(); // Placeholder
                },
              ),
          ],
        ),
      ),
    );
  }
}
