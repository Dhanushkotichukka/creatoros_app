import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'Trending'),
                Tab(text: 'Downloaded'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTemplateFeed(context),
                  const Center(child: Text('Downloaded Templates')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateFeed(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return _TemplateCard(index: index);
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final int index;
  const _TemplateCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = index % 2 == 0 ? Colors.purple : Colors.orange;

    return Container(
      height: 480, // Feed like height
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1611162617474-5b21e879e113?q=80&w=600'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          // Content info bottom
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                  child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                const Text('Cinematic Vlog Intro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('@creator_templates', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          // Actions right
          Positioned(
            right: 16,
            bottom: 32,
            child: Column(
              children: [
                _buildAction(Icons.favorite_border, '1.2k'),
                const SizedBox(height: 24),
                _buildAction(Icons.comment_outlined, '45'),
                const SizedBox(height: 24),
                _buildAction(Icons.file_download_outlined, 'Download'),
                const SizedBox(height: 24),
                _buildAction(Icons.import_export, 'Use'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
