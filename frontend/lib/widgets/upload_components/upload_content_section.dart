import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/post_provider.dart';
import '../../services/api_service.dart';

class UploadContentSection extends StatefulWidget {
  const UploadContentSection({Key? key}) : super(key: key);

  @override
  State<UploadContentSection> createState() => _UploadContentSectionState();
}

class _UploadContentSectionState extends State<UploadContentSection> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final activePost = provider.activePost;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isUploading ? null : () => _pickMedia(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: activePost.mediaPaths.isEmpty ? Colors.grey.shade900 : Colors.black87,
          ),
          child: _isUploading 
              ? const Center(child: CircularProgressIndicator())
              : activePost.mediaPaths.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload_file, size: 48, color: Colors.blueAccent),
                    SizedBox(height: 8),
                    Text(
                      'Upload Content',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Tap to select video or image',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: activePost.mediaPaths.first.toLowerCase().endsWith('.mp4') || 
                             activePost.mediaPaths.first.toLowerCase().endsWith('.mov') ||
                             activePost.mediaPaths.first.toLowerCase().endsWith('.webm')
                          ? const Center(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam, size: 48, color: Colors.white54),
                                  Text('Video Selected', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                                ],
                              ))
                          : Image.network(
                              activePost.mediaPaths.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 40, color: Colors.greenAccent),
                                  SizedBox(height: 8),
                                  Text('Media Hosted on S3', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              )),
                            ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        onPressed: () {
                          context.read<PostProvider>().setMedia([]);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pickMedia(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Pick Video or Image'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ImagePicker picker = ImagePicker();
                  try {
                    final XFile? media = await picker.pickMedia(imageQuality: 70);
                    if (media != null && context.mounted) {
                      setState(() => _isUploading = true);
                      
                      // Convert to bytes compatible with Web/Desktop/Mobile
                      final bytes = await media.readAsBytes();
                      
                      // Call backend API to store in S3 directly
                      final uploadResult = await ApiService.uploadFile(bytes, media.name);
                      
                      if (mounted && uploadResult.containsKey('url')) {
                        final secureUrl = uploadResult['url'] as String;
                        context.read<PostProvider>().setMedia([secureUrl]);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media uploaded to S3 successfully!')));
                      }
                    }
                  } catch (e) {
                    debugPrint('Error picking/uploading media: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload media: $e')));
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isUploading = false);
                    }
                  }
                },
              ),
              ListTile(
                 title: const Text('Cancel'),
                 onTap: () => Navigator.pop(ctx),
              )
            ],
          ),
        );
      },
    );
  }
}
