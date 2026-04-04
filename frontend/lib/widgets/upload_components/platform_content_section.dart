import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/multi_post/platform_type.dart';
import '../../models/multi_post/platform_content.dart';
import '../../providers/post_provider.dart';

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
  const PlatformContentSection({Key? key}) : super(key: key);

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
    final selectedPlatform = provider.selectedPlatform;

    if (connectedPlatforms.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ensure selectedPlatform is a connected one, or default to the first connected
    final platformToDisplay = connectedPlatforms.contains(selectedPlatform)
        ? selectedPlatform
        : connectedPlatforms.first;

    // Use a post frame callback if state needs to sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedPlatform != platformToDisplay && context.mounted) {
        context.read<PostProvider>().setSelectedPlatform(platformToDisplay);
      }
    });

    final currentPlatformContent = activePost.platformData[platformToDisplay] ?? PlatformContent();
    if (_titleController.text != currentPlatformContent.title) {
      _titleController.text = currentPlatformContent.title;
      _titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: _titleController.text.length),
      );
    }
    if (_captionController.text != currentPlatformContent.description) {
      _captionController.text = currentPlatformContent.description;
      _captionController.selection = TextSelection.fromPosition(
        TextPosition(offset: _captionController.text.length),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Selected Platform (Left) and Connected Icons (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Selected Platform Name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.transparent,
                      child: Icon(_getPlatformIcon(platformToDisplay), size: 24, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      platformToDisplay.name.replaceFirst(
                        platformToDisplay.name[0],
                        platformToDisplay.name[0].toUpperCase(),
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Right: Connected Platform Tabs
                Row(
                  children: connectedPlatforms.map((platform) {
                    final isSelected = platform == platformToDisplay;
                    return GestureDetector(
                      onTap: () => context.read<PostProvider>().setSelectedPlatform(platform),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.redAccent, width: 2) : Border.all(color: Colors.grey.shade800, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            _getPlatformIcon(platform),
                            size: 14,
                            color: isSelected ? Colors.redAccent : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content Type Selector
            Wrap(
              spacing: 8,
              children: ['Post', 'Reel', 'Story'].map((type) {
                final isSelected = currentPlatformContent.contentType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<PostProvider>().updateContent(
                            platformToDisplay,
                            currentPlatformContent.copyWith(contentType: type),
                          );
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey.shade800),
                  backgroundColor: Colors.transparent,
                  selectedColor: Colors.blueAccent.withAlpha(50),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Privacy Status Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentPlatformContent.privacyStatus,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                  dropdownColor: Colors.grey.shade900,
                  items: ['public', 'unlisted', 'private'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value[0].toUpperCase() + value.substring(1),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context.read<PostProvider>().updateContent(
                            platformToDisplay,
                            currentPlatformContent.copyWith(privacyStatus: newValue),
                          );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Audience (Made for Kids)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.public, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('Audience', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Set by you', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<bool>(
                    title: const Text("Yes, it's Made for Kids", style: TextStyle(fontSize: 14, color: Colors.white70)),
                    value: true,
                    groupValue: currentPlatformContent.madeForKids,
                    onChanged: (bool? value) {
                      if (value != null) {
                        context.read<PostProvider>().updateContent(platformToDisplay, currentPlatformContent.copyWith(madeForKids: value));
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    dense: true,
                    activeColor: Colors.blueAccent,
                  ),
                  RadioListTile<bool>(
                    title: const Text("No, it's not 'Made for Kids'", style: TextStyle(fontSize: 14, color: Colors.white70)),
                    value: false,
                    groupValue: currentPlatformContent.madeForKids,
                    onChanged: (bool? value) {
                      if (value != null) {
                        context.read<PostProvider>().updateContent(platformToDisplay, currentPlatformContent.copyWith(madeForKids: value));
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    dense: true,
                    activeColor: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Title Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Add a title...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (val) {
                context.read<PostProvider>().updateContent(
                      platformToDisplay,
                      currentPlatformContent.copyWith(title: val),
                    );
              },
            ),
            const SizedBox(height: 12),
            // Caption Input
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (val) {
                context.read<PostProvider>().updateContent(
                      platformToDisplay,
                      currentPlatformContent.copyWith(description: val),
                    );
              },
            ),
            if (currentPlatformContent.hashtags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 4,
                  children: currentPlatformContent.hashtags.map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.blueAccent.withAlpha(50),
                      onDeleted: () {
                        final newTags = List<String>.from(currentPlatformContent.hashtags)
                          ..remove(tag);
                        context.read<PostProvider>().updateContent(
                              platformToDisplay,
                              currentPlatformContent.copyWith(hashtags: newTags),
                            );
                      },
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
            // AI Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _isGeneratingCaption
                      ? null
                      : () async {
                          setState(() => _isGeneratingCaption = true);
                          final caption = await AIService.generateCaption(
                            activePost.title,
                            currentPlatformContent.description,
                          );
                          if (context.mounted) {
                            context.read<PostProvider>().updateContent(
                                  platformToDisplay,
                                  currentPlatformContent.copyWith(description: caption),
                                );
                          }
                          setState(() => _isGeneratingCaption = false);
                        },
                  icon: _isGeneratingCaption
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const SizedBox.shrink(),
                  label: const Text('write Caption'),
                  style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isGeneratingTags
                      ? null
                      : () async {
                          setState(() => _isGeneratingTags = true);
                          final tags = await AIService.generateHashtags(
                            activePost.title,
                            currentPlatformContent.description,
                          );
                          if (context.mounted) {
                            context.read<PostProvider>().updateContent(
                                  platformToDisplay,
                                  currentPlatformContent.copyWith(hashtags: tags),
                                );
                          }
                          setState(() => _isGeneratingTags = false);
                        },
                  icon: _isGeneratingTags
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const SizedBox.shrink(),
                  label: const Text('#tags'),
                  style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.youtube:
        return Icons.play_arrow;
      case PlatformType.instagram:
        return Icons.camera_alt;
      case PlatformType.facebook:
        return Icons.facebook;
      case PlatformType.linkedin:
        return Icons.work;
    }
  }
}
