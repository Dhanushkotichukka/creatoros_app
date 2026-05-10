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
            Row(
              children: [
                const Icon(Icons.video_camera_back_rounded, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text('Storage Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                if (_isLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Text(
                    '${allFiltered.length} files',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Category Cards ──────────────────────────────────────────────────────
        Row(
          children: [
            _buildGridItem('Videos', Icons.videocam_rounded, const Color(0xFF1565C0), theme),
            const SizedBox(width: 8),
            _buildGridItem('Images', Icons.image_rounded, const Color(0xFF2E7D32), theme),
            const SizedBox(width: 8),
            _buildGridItem('Sounds', Icons.audiotrack_rounded, const Color(0xFFC62828), theme),
            const SizedBox(width: 8),
            _buildGridItem('Edits', Icons.edit_document, const Color(0xFF6A1B9A), theme),
          ],
        ),
        const SizedBox(height: 24),

        // ── Upload Container ────────────────────────────────────────────────────
        GestureDetector(
          onTap: _pickAndUpload,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.8),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_upload_outlined, color: theme.colorScheme.primary, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upload Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Drag & drop files here or tap to browse', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Latest Files List ───────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: ['All', 'Local', 'Cloud'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.transparent : theme.colorScheme.onSurface.withOpacity(0.2)),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('Recent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Latest Storage Files', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('View all', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 16),

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
                  Icon(Icons.folder_off_outlined, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.2)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(isCloud ? Icons.cloud_outlined : Icons.folder_outlined, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text('$sizeKb KB',
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                const SizedBox(width: 8),
                                if (dateStr.isNotEmpty) ...[
                                  Container(width: 4, height: 4, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.3), shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(dateStr, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.more_vert, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    ],
                  ),
                ),
              );
            },
          ),
        if (allFiltered.length > 6)
          Center(
            child: TextButton(
              onPressed: () => _openCategory('All'),
              child: const Text('View All Files'),
            ),
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
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 12, right: 8),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.clip),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text('$count\nFiles', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.2)),
                    ),
                    Text('1.2 GB', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
