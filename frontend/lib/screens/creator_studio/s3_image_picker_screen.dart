import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;

class S3ImagePickerScreen extends StatefulWidget {
  const S3ImagePickerScreen({super.key});

  @override
  State<S3ImagePickerScreen> createState() => _S3ImagePickerScreenState();
}

class _S3ImagePickerScreenState extends State<S3ImagePickerScreen> {
  List<dynamic> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final allFiles = await ApiService.getStorageFiles();
      // Filter for cloud images
      final images = allFiles.where((f) {
        final name = (f['name'] ?? '').toString().toLowerCase();
        final storage = (f['storage'] ?? '').toString().toLowerCase();
        final isImage = name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png') || name.endsWith('.webp');
        final isCloud = storage.contains('s3') || storage == 'cloud';
        return isImage && isCloud;
      }).toList();

      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load S3 images: $e')));
      }
    }
  }

  Future<void> _pickImage(dynamic file) async {
    try {
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final url = await ApiService.getStorageDownloadUrl(file['name'], file['storage']);
      final response = await http.get(Uri.parse(url));
      
      if (!mounted) return;
      Navigator.pop(context); // close progress dialog
      
      if (response.statusCode == 200) {
        Navigator.pop(context, response.bodyBytes);
      } else {
        throw Exception('Failed to download image data');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close progress dialog if error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Cloud Image')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _images.isEmpty 
          ? const Center(child: Text('No cloud images found. Upload some to S3 first!'))
          : ListView.builder(
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final file = _images[index];
                return ListTile(
                  leading: const Icon(Icons.cloud_done, color: Colors.blue),
                  title: Text(file['name'] ?? 'Unknown Image'),
                  subtitle: Text('${((file['size'] ?? 0) / 1024).toStringAsFixed(1)} KB'),
                  onTap: () => _pickImage(file),
                );
              },
            ),
    );
  }
}
