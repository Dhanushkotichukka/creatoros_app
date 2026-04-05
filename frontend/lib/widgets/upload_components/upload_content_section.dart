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
    final mediaPaths = activePost.mediaPaths;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _isUploading ? null : () => _pickMedia(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: mediaPaths.isEmpty ? 150 : 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: mediaPaths.isEmpty ? Colors.grey.shade900 : Colors.black87,
              ),
              child: _isUploading 
                  ? const Center(child: CircularProgressIndicator())
                  : mediaPaths.isEmpty
                  ? _buildEmptyState()
                  : _buildMediaPreview(mediaPaths),
            ),
          ),
          if (mediaPaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${mediaPaths.length} item(s) selected',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.blueAccent),
        SizedBox(height: 8),
        Text(
          'Upload Content',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          'Select up to 10 images or 1 video',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMediaPreview(List<String> paths) {
    return Stack(
      children: [
        ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          itemCount: paths.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final path = paths[index];
            final isVid = path.toLowerCase().contains('.mp4') || path.toLowerCase().contains('.mov');
            
            return SizedBox(
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isVid 
                    ? Container(
                        color: Colors.grey.shade800,
                        child: const Center(child: Icon(Icons.videocam, color: Colors.white54, size: 40)),
                      )
                    : Image.network(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade800, child: const Icon(Icons.image)),
                      ),
              ),
            );
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
            onPressed: () => context.read<PostProvider>().setMedia([]),
          ),
        ),
      ],
    );
  }

  Future<void> _pickMedia(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
                title: const Text('Pick Image(s)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Select up to 10 photos for a Carousel', style: TextStyle(color: Colors.white54)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ImagePicker picker = ImagePicker();
                  try {
                    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70, limit: 10);
                    if (images.isNotEmpty) {
                      await _uploadMultiple(images);
                    }
                  } catch (e) {
                    _showError('Error picking images: $e');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.redAccent),
                title: const Text('Pick Video', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ImagePicker picker = ImagePicker();
                  try {
                    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                    if (video != null) {
                      await _uploadMultiple([video]);
                    }
                  } catch (e) {
                    _showError('Error picking video: $e');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadMultiple(List<XFile> files) async {
    setState(() => _isUploading = true);
    final List<String> uploadedUrls = [];
    
    try {
      for (var file in files) {
        final bytes = await file.readAsBytes();
        final result = await ApiService.uploadFile(bytes, file.name);
        if (result.containsKey('url')) {
          uploadedUrls.add(result['url'] as String);
        }
      }
      
      if (mounted && uploadedUrls.isNotEmpty) {
        context.read<PostProvider>().setMedia(uploadedUrls);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${uploadedUrls.length} file(s) successfully!'))
        );
      }
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
    }
  }
}
