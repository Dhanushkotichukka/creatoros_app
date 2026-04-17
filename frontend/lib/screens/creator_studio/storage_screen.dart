import 'package:flutter/material.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Storage'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage Usage Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cloud Storage', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('45 GB / 100 GB', style: TextStyle(color: theme.colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.45,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _storageIndicatorBlock('Videos', Colors.blue),
                      _storageIndicatorBlock('Images', Colors.green),
                      _storageIndicatorBlock('Other', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            Text('Quick Access', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _CategoryCard(icon: Icons.video_file, title: 'Videos', color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _CategoryCard(icon: Icons.image, title: 'Images', color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _CategoryCard(icon: Icons.mic, title: 'Voices', color: Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _CategoryCard(icon: Icons.notes, title: 'Notes', color: Colors.purple)),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Files
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Files', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: Text('See All', style: TextStyle(color: theme.colorScheme.primary))),
              ],
            ),
            const SizedBox(height: 12),
            _FileItem(name: 'intro_sequence_v2.mp4', size: '14.2 MB', date: 'Oct 12', icon: Icons.video_file, color: Colors.blue),
            _FileItem(name: 'thumbnail_final.jpg', size: '2.4 MB', date: 'Oct 11', icon: Icons.image, color: Colors.green),
            _FileItem(name: 'voiceover_draft.wav', size: '5.1 MB', date: 'Oct 10', icon: Icons.mic, color: Colors.orange),
            _FileItem(name: 'script_notes.txt', size: '12 KB', date: 'Oct 09', icon: Icons.notes, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _storageIndicatorBlock(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _CategoryCard({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FileItem extends StatelessWidget {
  final String name;
  final String size;
  final String date;
  final IconData icon;
  final Color color;

  const _FileItem({required this.name, required this.size, required this.date, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text('$size • $date', style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ),
    );
  }
}
