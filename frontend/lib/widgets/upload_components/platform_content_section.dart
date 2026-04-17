import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/multi_post/platform_type.dart';
import '../../models/multi_post/platform_content.dart';
import '../../providers/post_provider.dart';
import '../../utils/app_colors.dart';

// Mock AIService since the actual one is not fully provided
class AIService {
  static Future<String> generateCaption(String title, String description) async {
    await Future.delayed(const Duration(seconds: 1));
    return "This is a great generated caption for ${title.isEmpty ? 'this post' : title}!";
  }

  static Future<List<String>> generateHashtags(String title, String description) async {
    await Future.delayed(const Duration(seconds: 1));
    return ['#creatorOS', '#post', '#trending'];
  }
}

class PlatformContentSection extends StatefulWidget {
  PlatformContentSection({Key? key}) : super(key: key);

  @override
  State<PlatformContentSection> createState() => _PlatformContentSectionState();
}

class _PlatformContentSectionState extends State<PlatformContentSection> {
  late TextEditingController _titleController;
  late TextEditingController _captionController;
  bool _isGeneratingCaption = false;
  bool _isGeneratingTags = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final activePost = provider.activePost;
    final connectedPlatforms = provider.connectedPlatforms;
    final targetPlatforms = provider.targetPlatforms;
    final selectedPlatform = provider.selectedPlatform;

    if (connectedPlatforms.isEmpty) {
      return _buildNoConnectionsState();
    }

    // Ensure selectedPlatform is in targetPlatforms if possible
    final platformToDisplay = targetPlatforms.contains(selectedPlatform)
        ? selectedPlatform
        : (targetPlatforms.isNotEmpty ? targetPlatforms.first : connectedPlatforms.first);

    // Sync controllers with current platform metadata
    final currentPlatformContent = activePost.platformData[platformToDisplay] ?? PlatformContent();
    if (_titleController.text != currentPlatformContent.title) {
      _titleController.text = currentPlatformContent.title;
      _titleController.selection = TextSelection.fromPosition(TextPosition(offset: _titleController.text.length));
    }
    if (_captionController.text != currentPlatformContent.description) {
      _captionController.text = currentPlatformContent.description;
      _captionController.selection = TextSelection.fromPosition(TextPosition(offset: _captionController.text.length));
    }

    final c = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlatformSelector(context, targetPlatforms, connectedPlatforms, platformToDisplay),
            Divider(height: 32, color: isDark ? Colors.white10 : Colors.grey[200]),
            
            if (targetPlatforms.contains(platformToDisplay)) ...[
              _buildPostTypeSelector(context, platformToDisplay, currentPlatformContent),
              const SizedBox(height: 20),
              _buildMetadataEditor(context, platformToDisplay, currentPlatformContent, activePost),
            ] else 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Select or Add a platform above to start editing content', 
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13)
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnectionsState() {
    final c = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        children: [
          Icon(Icons.link_off, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No Social Platforms Connected', 
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
          ),
          Text(
            'Connect your accounts in Settings to start posting', 
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 12)
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector(BuildContext context, Set<PlatformType> targets, Set<PlatformType> connected, PlatformType active) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post to these platforms:', 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...targets.map((platform) => _buildPlatformIcon(context, platform, platform == active)),
              _buildAddPlatformButton(context, targets, connected),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformIcon(BuildContext context, PlatformType platform, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.read<PostProvider>().setSelectedPlatform(platform),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withAlpha(30) : (isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : (isDark ? Colors.white10 : Colors.grey.shade200), 
            width: 2
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                _getPlatformIcon(platform), 
                size: 28, 
                color: isSelected ? Colors.blueAccent : (isDark ? Colors.white60 : Colors.grey.shade400)
              )
            ),
            Positioned(
              right: -2,
              top: -2,
              child: GestureDetector(
                onTap: () => context.read<PostProvider>().toggleTargetPlatform(platform),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: isDark ? Colors.black54 : Colors.grey.shade300, shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 10, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPlatformButton(BuildContext context, Set<PlatformType> targets, Set<PlatformType> connected) {
    final remaining = connected.where((p) => !targets.contains(p)).toList();
    if (remaining.isEmpty) return const SizedBox.shrink();

    return IconButton(
      onPressed: () => _showAddPlatformModal(context, remaining),
      icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 32),
      padding: const EdgeInsets.all(12),
    );
  }

  Widget _buildPostTypeSelector(BuildContext context, PlatformType platform, PlatformContent content) {
    final List<String> types = ['Post', 'Reel', 'Story'];
    if (platform == PlatformType.youtube) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Content Type', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 11)),
        const SizedBox(height: 8),
        Row(
          children: types.map((type) {
            final isSelected = content.contentType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (val) {
                  if (val) context.read<PostProvider>().updateContent(platform, content.copyWith(contentType: type));
                },
                backgroundColor: isDark ? Colors.transparent : Colors.grey.shade50,
                selectedColor: Colors.blueAccent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), 
                  fontSize: 13
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetadataEditor(BuildContext context, PlatformType platform, PlatformContent content, dynamic activePost) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        TextField(
          controller: _titleController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Enter title (Platform specific)',
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
            prefixIcon: Icon(Icons.title, color: isDark ? Colors.white24 : Colors.grey.shade400),
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => context.read<PostProvider>().updateContent(platform, content.copyWith(title: val)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _captionController,
          maxLines: 5,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Write caption...',
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => context.read<PostProvider>().updateContent(platform, content.copyWith(description: val)),
        ),
        const SizedBox(height: 12),
        _buildAIButtons(context, platform, content, activePost),
      ],
    );
  }

  Widget _buildAIButtons(BuildContext context, PlatformType platform, PlatformContent content, dynamic activePost) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _isGeneratingCaption ? null : () => _generateCaption(context, platform, content, activePost),
          icon: _isGeneratingCaption ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 16),
          label: const Text('AI Caption', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: Colors.purpleAccent),
        ),
        TextButton.icon(
          onPressed: _isGeneratingTags ? null : () => _generateTags(context, platform, content, activePost),
          icon: _isGeneratingTags ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.tag, size: 16),
          label: const Text('AI Tags', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
        ),
      ],
    );
  }

  void _showAddPlatformModal(BuildContext context, List<PlatformType> platforms) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to this post', 
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            ...platforms.map((p) => ListTile(
              leading: Icon(_getPlatformIcon(p), color: Colors.blueAccent),
              title: Text(p.name.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                context.read<PostProvider>().toggleTargetPlatform(p);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _generateCaption(BuildContext context, PlatformType p, PlatformContent c, dynamic post) async {
    setState(() => _isGeneratingCaption = true);
    final text = await AIService.generateCaption(post.title, c.description);
    if (context.mounted) context.read<PostProvider>().updateContent(p, c.copyWith(description: text));
    setState(() => _isGeneratingCaption = false);
  }

  Future<void> _generateTags(BuildContext context, PlatformType p, PlatformContent c, dynamic post) async {
    setState(() => _isGeneratingTags = true);
    final tags = await AIService.generateHashtags(post.title, c.description);
    if (context.mounted) context.read<PostProvider>().updateContent(p, c.copyWith(hashtags: tags));
    setState(() => _isGeneratingTags = false);
  }

  IconData _getPlatformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube: return Icons.play_arrow;
      case PlatformType.instagram: return Icons.camera_alt;
      case PlatformType.linkedin: return Icons.work;
      case PlatformType.facebook: return Icons.facebook;
    }
  }
}
