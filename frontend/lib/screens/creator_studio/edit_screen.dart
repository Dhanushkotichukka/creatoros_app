import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../video_editor_screen.dart';
import 'image_editor_screen.dart';
import 's3_image_picker_screen.dart';

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
                  // ── Video → opens OpenCut editor (blank) ──────────────────
              _QuickAction(
                icon: Icons.video_call,
                label: 'Video',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (ctx, anim, _) => const VideoEditorScreen(),
                    transitionsBuilder: (ctx, anim, _, child) {
                      return FadeTransition(opacity: anim, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 220),
                  ),
                ),
              ),
              _QuickAction(
                icon: Icons.image,
                label: 'Image',
                color: Colors.green,
                onTap: () => _showImageSourcePicker(context),
              ),
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
                  Expanded(child: _PlanningCard(icon: Icons.notes, title: 'Notes', subtitle: '3 Drafts', onTap: () => _showComingSoon(context, 'Notes'))),
                  const SizedBox(width: 16),
                  Expanded(child: _PlanningCard(icon: Icons.chat, title: 'AI Chat', subtitle: 'Brainstorm', onTap: () => Navigator.pushNamed(context, '/ai-chat'))),
                  const SizedBox(width: 16),
                  Expanded(child: _PlanningCard(icon: Icons.calendar_month, title: 'Planner', subtitle: 'Schedule', onTap: () => _showComingSoon(context, 'Planner'))),
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!'), duration: const Duration(seconds: 2)),
    );
  }

  void _showImageSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Cloud Data (S3)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final bytes = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const S3ImagePickerScreen()),
                  );
                  if (bytes != null && context.mounted) {
                    final editedBytes = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ImageEditorScreen(memoryImage: bytes)),
                    );
                    if (editedBytes != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image saved successfully!')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Local Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null && context.mounted) {
                    final bytes = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ImageEditorScreen(file: File(pickedFile.path))),
                    );
                    if (bytes != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image saved successfully!')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }


}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  /// Optional tap handler. If null, button renders but does nothing.
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(onTap != null ? 0.18 : 0.10),
              shape: BoxShape.circle,
              border: onTap != null
                  ? Border.all(color: color.withOpacity(0.35), width: 1)
                  : null,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: onTap != null ? null : Colors.white38,
            ),
          ),
        ],
      ),
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
  final VoidCallback? onTap;

  const _PlanningCard({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
