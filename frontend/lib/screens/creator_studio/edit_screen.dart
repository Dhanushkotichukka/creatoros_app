import 'package:flutter/material.dart';

class EditScreen extends StatelessWidget {
  const EditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                        child: Icon(Icons.person, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: theme.textTheme.bodySmall),
                          Text('Vasanth Kumar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
                      IconButton(
                        icon: const Icon(Icons.close), 
                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickAction(icon: Icons.video_call, label: 'Video', color: Colors.blue),
                  _QuickAction(icon: Icons.image, label: 'Image', color: Colors.green),
                  _QuickAction(icon: Icons.auto_awesome_mosaic, label: 'Template', color: Colors.orange),
                  _QuickAction(icon: Icons.camera_alt, label: 'Camera', color: Colors.purple),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Projects
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Projects', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: Text('View All', style: TextStyle(color: theme.colorScheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _RecentProjectCard(title: 'Bahubali Edit', time: '2 hours ago', icon: Icons.movie, color: Colors.blue),
                    _RecentProjectCard(title: 'AI Thumbnail', time: 'Yesterday', icon: Icons.image, color: Colors.green),
                    _RecentProjectCard(title: 'Vlog Intro', time: '2 days ago', icon: Icons.video_library, color: Colors.purple),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Planning Section
              Text('Planning', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _PlanningCard(icon: Icons.notes, title: 'Notes', subtitle: '3 Drafts')),
                  const SizedBox(width: 16),
                  Expanded(child: _PlanningCard(icon: Icons.chat, title: 'AI Chat', subtitle: 'Brainstorm')),
                  const SizedBox(width: 16),
                  Expanded(child: _PlanningCard(icon: Icons.calendar_month, title: 'Planner', subtitle: 'Schedule')),
                ],
              ),
              const SizedBox(height: 32),

              // Tools Grid
              Text('Tools', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _ToolItem(icon: Icons.cut, label: 'Trim'),
                  _ToolItem(icon: Icons.text_fields, label: 'Text'),
                  _ToolItem(icon: Icons.music_note, label: 'Audio'),
                  _ToolItem(icon: Icons.filter, label: 'Filters'),
                  _ToolItem(icon: Icons.speed, label: 'Speed'),
                  _ToolItem(icon: Icons.crop, label: 'Crop'),
                  _ToolItem(icon: Icons.animation, label: 'Animate'),
                  _ToolItem(icon: Icons.add_circle_outline, label: 'More'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickAction({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _RecentProjectCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _RecentProjectCard({required this.title, required this.time, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlanningCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ToolItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
