import 'package:flutter/material.dart';

class AILabScreen extends StatelessWidget {
  const AILabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('AI Lab'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(context, 'Image AI Tools', [
                      _AIToolCard(title: 'AI Generate', icon: Icons.image, color: Colors.blue),
                      _AIToolCard(title: 'Background Remove', icon: Icons.person_remove, color: Colors.blue),
                      _AIToolCard(title: 'Enhance', icon: Icons.auto_fix_high, color: Colors.blue),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Video AI Tools', [
                      _AIToolCard(title: 'Auto Captions', icon: Icons.closed_caption, color: Colors.purple),
                      _AIToolCard(title: 'Smart Cut', icon: Icons.content_cut, color: Colors.purple),
                      _AIToolCard(title: 'Color Grade', icon: Icons.color_lens, color: Colors.purple),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Text AI Tools', [
                      _AIToolCard(title: 'Script Writer', icon: Icons.edit_document, color: Colors.green),
                      _AIToolCard(title: 'Hashtags Generator', icon: Icons.tag, color: Colors.green),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Voice AI Tools', [
                      _AIToolCard(title: 'Voice Clone', icon: Icons.mic, color: Colors.orange),
                      _AIToolCard(title: 'Noise Reduction', icon: Icons.hearing_disabled, color: Colors.orange),
                    ]),
                  ],
                ),
              ),
            ),
            // Smart Prompt Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Describe what you want to create...',
                          border: InputBorder.none,
                          icon: Icon(Icons.auto_awesome, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tools) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: tools.map((tool) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: tool,
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _AIToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _AIToolCard({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
