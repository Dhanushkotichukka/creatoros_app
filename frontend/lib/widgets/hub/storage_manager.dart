import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import 'package:path/path.dart' as p;

class StorageManager extends StatefulWidget {
  const StorageManager({super.key});

  @override
  State<StorageManager> createState() => _StorageManagerState();
}

class _StorageManagerState extends State<StorageManager> {
  List<dynamic> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await ApiService.getStorageFiles();
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading storage: $e');
    }
  }

  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true, // Required for web/mobile memory upload
      type: FileType.any,
    );

    if (result != null) {
      final file = result.files.first;
      if (file.bytes == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading file...')),
      );

      try {
        await ApiService.uploadFile(file.bytes!, file.name);
        _loadFiles(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${file.name} successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Storage Manager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.upload, color: Colors.deepPurpleAccent, size: 20),
              onPressed: _pickAndUpload,
              tooltip: 'Upload to S3/Local',
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No files in storage yet', style: TextStyle(color: Colors.grey))),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final ext = p.extension(file['name']).toLowerCase();
                IconData icon = Icons.insert_drive_file;
                Color color = Colors.grey;

                if (['.mp4', '.mov', '.avi'].contains(ext)) { icon = Icons.movie; color = Colors.blue; }
                else if (['.jpg', '.jpeg', '.png', '.gif'].contains(ext)) { icon = Icons.image; color = Colors.green; }
                else if (['.mp3', '.wav', '.m4a'].contains(ext)) { icon = Icons.audiotrack; color = Colors.red; }

                return ListTile(
                  dense: true,
                  leading: Icon(icon, color: color),
                  title: Text(file['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  subtitle: Text('${(file['size'] / 1024).toStringAsFixed(1)} KB • ${file['storage']}', style: const TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.more_vert, size: 16),
                  onTap: () {
                    // Could open URL or preview
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        const LinearProgressIndicator(value: 0.15, backgroundColor: Colors.grey, color: Colors.deepPurpleAccent),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_files.length} active assets', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const Text('Manage Cloud S3', style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent)),
          ],
        ),
      ],
    );
  }
}
