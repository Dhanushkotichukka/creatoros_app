import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import '../../screens/multi_hub_storage_screen.dart';

class StorageManager extends StatefulWidget {
  const StorageManager({super.key});

  @override
  State<StorageManager> createState() => _StorageManagerState();
}

class _StorageManagerState extends State<StorageManager> {
  List<dynamic> _files = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Local', 'Cloud'

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await ApiService.getStorageFiles();
      if (!mounted) return;
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading storage: $e');
    }
  }

  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.any,
    );

    if (result == null) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading file…'), behavior: SnackBarBehavior.floating),
    );

    try {
      await ApiService.uploadFile(file.bytes!, file.name);
      await _loadFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded ${file.name} successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiHubStorageScreen(
          type: category,
          mode: _selectedFilter,
          allFiles: _files,
        ),
      ),
    ).then((_) => _loadFiles()); // refresh on return (in case user deleted something)
  }

  // Count files for a category under currently selected filter
  int _countFor(String category) {
    final typeKey = category.toLowerCase() == 'edits' ? 'edit'
        : category.toLowerCase() == 'videos' ? 'video'
        : category.toLowerCase() == 'images' ? 'image'
        : category.toLowerCase() == 'sounds' ? 'sound'
        : 'all';

    var base = _filteredFiles;
    if (typeKey == 'all') return base.length;
    return base.where((f) => detectFileType(f['name'] ?? '') == typeKey).length;
  }

  // Files visible under selected source filter
  List<dynamic> get _filteredFiles {
    if (_selectedFilter == 'Cloud') {
      return _files.where((f) => _isCloudStorage(f['storage'] ?? '')).toList();
    } else if (_selectedFilter == 'Local') {
      return _files.where((f) => (f['storage'] ?? '').toString().toLowerCase() == 'local').toList();
    }
    return List.from(_files);
  }

  bool _isCloudStorage(String s) =>
      s == 'S3-Temp' || s == 'S3-Final' || s.toLowerCase() == 'cloud' || s.toLowerCase() == 's3';

  // Latest N files to preview inline (newest first)
  List<dynamic> get _latestFiles {
    final sorted = List<dynamic>.from(_filteredFiles);
    sorted.sort((a, b) {
      try {
        final da = DateTime.parse(a['lastModified'].toString());
        final db = DateTime.parse(b['lastModified'].toString());
        return db.compareTo(da);
      } catch (_) {
        return 0;
      }
    });
    return sorted.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.08);
    final allFiltered = _filteredFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Storage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                if (_isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 20),
                    tooltip: 'Refresh',
                    onPressed: _loadFiles,
                  ),
                IconButton(
                  icon: Icon(Icons.upload_file_rounded, color: theme.colorScheme.primary),
                  tooltip: 'Upload file',
                  onPressed: _pickAndUpload,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Storage Box ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Filter chips + count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: ['All', 'Local', 'Cloud'].map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter, style: const TextStyle(fontSize: 12)),
                          selected: _selectedFilter == filter,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (v) {
                            if (v) setState(() => _selectedFilter = filter);
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                  Text(
                    '${allFiltered.length} files',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4-category grid
              Row(
                children: [
                  _buildGridItem('Videos', Icons.videocam_rounded, const Color(0xFF1565C0), theme),
                  _buildGridItem('Images', Icons.image_rounded, const Color(0xFF2E7D32), theme),
                  _buildGridItem('Sounds', Icons.audiotrack_rounded, const Color(0xFFC62828), theme),
                  _buildGridItem('Edits', Icons.edit_document, const Color(0xFF6A1B9A), theme),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Latest storage things ───────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Latest storage things',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
            ),
            if (allFiltered.length > 6)
              TextButton(
                onPressed: () => _openCategory('All'),
                child: Text('View all ${allFiltered.length}'),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ── File List ────────────────────────────────────────────────────────────
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_latestFiles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Image.network(
                    'https://raw.githubusercontent.com/nikhitadasari26/multihub/main/assets/images/empty_octopus.png',
                    height: 110,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  ),
                  const SizedBox(height: 14),
                  Text('No files found', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _latestFiles.length,
            itemBuilder: (_, i) {
              final file = _latestFiles[i];
              final name = file['name'] ?? 'Unknown';
              final storage = file['storage'] ?? '';
              final sizeKb = ((file['size'] ?? 0) / 1024).toStringAsFixed(1);
              final isCloud = _isCloudStorage(storage);
              final fileType = detectFileType(name);
              final fileColor = colorForType(fileType);
              final fileIcon = iconForType(fileType);

              String dateStr = '';
              try {
                final raw = file['lastModified'];
                if (raw != null) {
                  dateStr = DateFormat('dd MMM yy').format(DateTime.parse(raw.toString()));
                }
              } catch (_) {}

              return GestureDetector(
                onTap: () => _openCategory(
                  fileType == 'video' ? 'Videos'
                      : fileType == 'image' ? 'Images'
                      : fileType == 'sound' ? 'Sounds'
                      : 'Edits',
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: fileColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(fileIcon, color: fileColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isCloud ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(storage,
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                                          color: isCloud ? Colors.blue : Colors.green)),
                                ),
                                const SizedBox(width: 6),
                                Text('$sizeKb KB${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGridItem(String label, IconData icon, Color color, ThemeData theme) {
    final count = _isLoading ? 0 : _countFor(label);
    return Expanded(
      child: GestureDetector(
        onTap: () => _openCategory(label),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.18)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: color, size: 26),
                    if (count > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
