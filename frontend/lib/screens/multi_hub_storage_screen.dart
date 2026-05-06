import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../utils/web_helper.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

// ── Type helpers ──────────────────────────────────────────────────────────────
String detectFileType(String fileName) {
  final ext = p.extension(fileName).toLowerCase();
  if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext)) return 'video';
  if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.bmp'].contains(ext)) return 'image';
  if (['.mp3', '.wav', '.m4a', '.ogg', '.aac', '.flac'].contains(ext)) return 'sound';
  return 'edit';
}

IconData iconForType(String type) {
  switch (type) {
    case 'video': return Icons.videocam_rounded;
    case 'image': return Icons.image_rounded;
    case 'sound': return Icons.audiotrack_rounded;
    default: return Icons.insert_drive_file_rounded;
  }
}

Color colorForType(String type) {
  switch (type) {
    case 'video': return const Color(0xFF1565C0);
    case 'image': return const Color(0xFF2E7D32);
    case 'sound': return const Color(0xFFC62828);
    default: return const Color(0xFF6A1B9A);
  }
}

bool _isCloud(String storage) =>
    storage == 'S3-Temp' || storage == 'S3-Final' ||
    storage.toLowerCase() == 'cloud' || storage.toLowerCase() == 's3';

// ─────────────────────────────────────────────────────────────────────────────

class MultiHubStorageScreen extends StatefulWidget {
  final String type;  // 'Videos', 'Images', 'Sounds', 'Edits', 'All'
  final String mode;  // 'All', 'Local', 'Cloud'
  final List<dynamic> allFiles;

  const MultiHubStorageScreen({
    super.key,
    required this.type,
    required this.mode,
    required this.allFiles,
  });

  @override
  State<MultiHubStorageScreen> createState() => _MultiHubStorageScreenState();
}

class _MultiHubStorageScreenState extends State<MultiHubStorageScreen> {
  late List<dynamic> _files;
  String _activeMode = 'All';
  bool _isGridView = true;
  bool _selectMode = false;
  final Set<String> _selectedKeys = {};
  bool _isBulkDeleting = false;

  @override
  void initState() {
    super.initState();
    _files = List<dynamic>.from(widget.allFiles);
    _activeMode = widget.mode;
  }

  // ── Unique key per file ───────────────────────────────────────────────────────
  String _fileKey(dynamic f) => '${f['name']}_${f['storage']}';

  // ── TypeKey mapping ──────────────────────────────────────────────────────────
  String get _typeKey {
    switch (widget.type.toLowerCase()) {
      case 'videos': return 'video';
      case 'images': return 'image';
      case 'sounds': return 'sound';
      case 'edits': return 'edit';
      default: return 'all';
    }
  }

  // ── Filtering + sort ─────────────────────────────────────────────────────────
  List<dynamic> get _filtered {
    var result = List<dynamic>.from(_files);
    if (_activeMode == 'Cloud') {
      result = result.where((f) => _isCloud(f['storage'] ?? '')).toList();
    } else if (_activeMode == 'Local') {
      result = result.where((f) => (f['storage'] ?? '').toString().toLowerCase() == 'local').toList();
    }
    if (_typeKey != 'all') {
      result = result.where((f) => detectFileType(f['name'] ?? '') == _typeKey).toList();
    }
    result.sort((a, b) {
      try {
        return DateTime.parse(b['lastModified'].toString())
            .compareTo(DateTime.parse(a['lastModified'].toString()));
      } catch (_) { return 0; }
    });
    return result;
  }

  // ── Get media URL for a file ─────────────────────────────────────────────────
  Future<String> _getMediaUrl(Map<String, dynamic> file) async {
    if (_isCloud(file['storage'] ?? '')) {
      return ApiService.getStorageDownloadUrl(file['name'], file['storage']);
    }
    return file['url'] ?? 'http://localhost:3000/uploads/${file['name']}';
  }

  // ── Open media viewer ─────────────────────────────────────────────────────────
  Future<void> _openMedia(Map<String, dynamic> file) async {
    final fileType = detectFileType(file['name'] ?? '');
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = await _getMediaUrl(file);
      if (!mounted) return;
      Navigator.pop(context); // close loading

      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (ctx) => _MediaViewerDialog(
          fileName: file['name'] ?? '',
          fileType: fileType,
          url: url,
          storage: file['storage'] ?? '',
          sizeKb: ((file['size'] ?? 0) / 1024).toStringAsFixed(1),
          onDelete: () {
            Navigator.pop(ctx);
            _deleteFile(file);
          },
          onDownload: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load media: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Delete single ────────────────────────────────────────────────────────────
  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final confirmed = await _confirmDelete(
      'Delete "${file['name']}"?',
      _isCloud(file['storage'] ?? ''),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiService.deleteStorageFile(file['name'], file['storage']);
      setState(() => _files.removeWhere((f) => _fileKey(f) == _fileKey(file)));
      _showSnack('Deleted ${file['name']}', Colors.red.shade700);
    } catch (e) {
      _showSnack('Delete failed: $e', Colors.red);
    }
  }

  // ── Bulk delete ──────────────────────────────────────────────────────────────
  Future<void> _bulkDelete() async {
    if (_selectedKeys.isEmpty) return;
    final count = _selectedKeys.length;
    final hasCloud = _filtered.any((f) => _selectedKeys.contains(_fileKey(f)) && _isCloud(f['storage'] ?? ''));
    
    final confirmed = await _confirmDelete(
      'Delete $count selected file${count == 1 ? '' : 's'}?',
      hasCloud,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBulkDeleting = true);
    int deleted = 0;
    int failed = 0;

    for (final key in _selectedKeys.toList()) {
      final file = _files.firstWhere(
        (f) => _fileKey(f) == key,
        orElse: () => null,
      );
      if (file == null) continue;
      try {
        await ApiService.deleteStorageFile(file['name'], file['storage']);
        setState(() => _files.removeWhere((f) => _fileKey(f) == key));
        deleted++;
      } catch (_) {
        failed++;
      }
    }

    setState(() {
      _selectedKeys.clear();
      _selectMode = false;
      _isBulkDeleting = false;
    });

    _showSnack(
      failed == 0 ? 'Deleted $deleted files' : 'Deleted $deleted, failed $failed',
      failed == 0 ? Colors.red.shade700 : Colors.orange,
    );
  }

  Future<bool?> _confirmDelete(String message, bool isCloud) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (isCloud) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red.shade400, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Permanently deletes from S3 cloud storage.',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _toggleSelect(dynamic file) {
    final key = _fileKey(file);
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
        if (_selectedKeys.isEmpty) _selectMode = false;
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _startSelectMode(dynamic file) {
    setState(() {
      _selectMode = true;
      _selectedKeys.add(_fileKey(file));
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final r = Responsive.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectMode = false;
                  _selectedKeys.clear();
                }),
              )
            : null,
        title: _selectMode
            ? Text('${_selectedKeys.length} selected',
                style: const TextStyle(fontWeight: FontWeight.bold))
            : Text(
                widget.type == 'All' ? 'All Storage' : widget.type,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          if (_selectMode) ...[
            if (_isBulkDeleting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              TextButton.icon(
                onPressed: () {
                  final allKeys = filtered.map(_fileKey).toSet();
                  setState(() => _selectedKeys.addAll(allKeys));
                },
                icon: const Icon(Icons.select_all, size: 18),
                label: const Text('All'),
              ),
              IconButton(
                icon: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                onPressed: _bulkDelete,
                tooltip: 'Delete selected',
              ),
            ],
          ] else ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'List view' : 'Grid view',
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                ...['All', 'Local', 'Cloud'].map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _activeMode == filter,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (v) { if (v) setState(() => _activeMode = filter); },
                    visualDensity: VisualDensity.compact,
                  ),
                )),
                const Spacer(),
                Text(
                  '${filtered.length} file${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? _buildEmptyState(theme)
          : _isGridView
              ? _buildGridView(filtered, theme, r)
              : _buildListView(filtered, theme),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          'https://raw.githubusercontent.com/nikhitadasari26/multihub/main/assets/images/empty_octopus.png',
          height: 120,
          errorBuilder: (_, __, ___) => Icon(Icons.folder_open_rounded, size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.15)),
        ),
        const SizedBox(height: 16),
        Text('No ${widget.type} found in $_activeMode',
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.5))),
      ],
    ),
  );

  // ── GRID VIEW ────────────────────────────────────────────────────────────────
  Widget _buildGridView(List<dynamic> files, ThemeData theme, Responsive r) {
    final cols = r.isWeb ? 5 : r.isTablet ? 4 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: files.length,
      itemBuilder: (_, i) => _buildGridCell(files[i], theme),
    );
  }

  Widget _buildGridCell(dynamic file, ThemeData theme) {
    final name = file['name'] ?? '';
    final fileType = detectFileType(name);
    final fileColor = colorForType(fileType);
    final isSelected = _selectedKeys.contains(_fileKey(file));
    final isCloud = _isCloud(file['storage'] ?? '');
    final url = file['url'];  // may be null for cloud items; loaded on tap

    return GestureDetector(
      onTap: () => _selectMode ? _toggleSelect(file) : _openMedia(file),
      onLongPress: () => _selectMode ? null : _startSelectMode(file),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.08),
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surface,
        ),
        child: Stack(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox.expand(
                child: fileType == 'image' && url != null
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackThumb(fileType, fileColor),
                      )
                    : _fallbackThumb(fileType, fileColor),
              ),
            ),

            // Video play overlay
            if (fileType == 'video')
              Center(
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                ),
              ),

            // Cloud badge
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isCloud ? Colors.blue.shade900.withOpacity(0.75) : Colors.green.shade900.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isCloud ? '☁' : '📁',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),

            // Selection overlay
            if (_selectMode)
              Positioned(
                top: 6, left: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? theme.colorScheme.primary : Colors.white.withOpacity(0.8),
                    border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),

            // Bottom file name
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                ),
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumb(String fileType, Color color) => Container(
    color: color.withOpacity(0.12),
    child: Center(
      child: Icon(iconForType(fileType), color: color.withOpacity(0.7), size: 40),
    ),
  );

  // ── LIST VIEW ────────────────────────────────────────────────────────────────
  Widget _buildListView(List<dynamic> files, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: files.length,
      itemBuilder: (_, i) => _buildListTile(files[i], theme),
    );
  }

  Widget _buildListTile(dynamic file, ThemeData theme) {
    final name = file['name'] ?? 'Unknown';
    final storage = file['storage'] ?? '';
    final sizeKb = ((file['size'] ?? 0) / 1024).toStringAsFixed(1);
    final isCloud = _isCloud(storage);
    final fileType = detectFileType(name);
    final fileColor = colorForType(fileType);
    final isSelected = _selectedKeys.contains(_fileKey(file));
    final url = file['url'];

    String dateStr = '';
    try {
      final raw = file['lastModified'];
      if (raw != null) dateStr = DateFormat('dd MMM yy, HH:mm').format(DateTime.parse(raw.toString()));
    } catch (_) {}

    return GestureDetector(
      onTap: () => _selectMode ? _toggleSelect(file) : _openMedia(file),
      onLongPress: () => _selectMode ? null : _startSelectMode(file),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.07),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection or thumbnail
            if (_selectMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
              ),

            // Icon or thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52, height: 52,
                child: fileType == 'image' && url != null
                    ? Image.network(url, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: fileColor.withOpacity(0.12),
                          child: Icon(iconForType(fileType), color: fileColor),
                        ))
                    : Container(
                        color: fileColor.withOpacity(0.12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(iconForType(fileType), color: fileColor, size: 24),
                            if (fileType == 'video')
                              const Icon(Icons.play_circle_outline, color: Colors.white70, size: 18),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(isCloud ? '☁ ${storage}' : '📁 Local',
                          isCloud ? Colors.blue : Colors.green),
                      const SizedBox(width: 6),
                      _badge(fileType.toUpperCase(), fileColor),
                      const SizedBox(width: 6),
                      Text('$sizeKb KB',
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    ],
                  ),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.35))),
                ],
              ),
            ),

            if (!_selectMode) ...[
              IconButton(
                icon: Icon(Icons.open_in_new_rounded, size: 18, color: theme.colorScheme.primary),
                onPressed: () => _openMedia(file),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                onPressed: () => _deleteFile(file),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDIA VIEWER DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _MediaViewerDialog extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String url;
  final String storage;
  final String sizeKb;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _MediaViewerDialog({
    required this.fileName,
    required this.fileType,
    required this.url,
    required this.storage,
    required this.sizeKb,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  State<_MediaViewerDialog> createState() => _MediaViewerDialogState();
}

class _MediaViewerDialogState extends State<_MediaViewerDialog> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    // Use url hashCode so same resource reuses the same factory
    _viewId = 'media-${widget.fileType}-${widget.url.hashCode.abs()}';
    _registerHtmlElement();
  }

  void _registerHtmlElement() {
    registerWebViewFactory(_viewId, widget.url, widget.fileType);
  }

  Widget _mobileMediaFallback(Color fileColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_camera_back_rounded, size: 64, color: fileColor.withOpacity(0.4)),
        const SizedBox(height: 16),
        const Text('In-app media playback is currently supported on Web.\nPlease click "Download" to open in supported app.', 
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: widget.onDownload,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download / Open File'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCloud = _isCloud(widget.storage);
    final fileColor = colorForType(widget.fileType);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Toolbar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: fileColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(iconForType(widget.fileType), color: fileColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${widget.sizeKb} KB • ${widget.storage}',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  // Download
                  IconButton(
                    icon: Icon(Icons.download_rounded, color: theme.colorScheme.primary),
                    tooltip: isCloud ? 'Download from S3' : 'Open file',
                    onPressed: widget.onDownload,
                  ),
                  // Delete
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                    tooltip: 'Delete',
                    onPressed: widget.onDelete,
                  ),
                  // Close
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Media area ───────────────────────────────────────────────────
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMediaContent(theme, fileColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(ThemeData theme, Color fileColor) {
    switch (widget.fileType) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null),
                        const SizedBox(height: 12),
                        const Text('Loading image...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
            errorBuilder: (_, __, ___) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, size: 64, color: fileColor.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('Could not load image.\nThe S3 bucket may require CORS config.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.onDownload,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open in Browser'),
                ),
              ],
            ),
          ),
        );

      case 'video':
        if (!kIsWeb) return _mobileMediaFallback(fileColor);
        return SizedBox(
          height: 420,
          child: HtmlElementView(viewType: _viewId),
        );

      case 'sound':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fileColor.withOpacity(0.1),
              ),
              child: Icon(Icons.audiotrack_rounded, size: 60, color: fileColor),
            ),
            const SizedBox(height: 24),
            Text(widget.fileName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (kIsWeb)
              SizedBox(
                height: 60,
                child: HtmlElementView(viewType: _viewId),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Audio preview requires Web. Please download file to listen.', 
                  style: TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              ),
          ],
        );

      default: // edits / docs
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fileColor.withOpacity(0.1),
              ),
              child: Icon(iconForType(widget.fileType), size: 52, color: fileColor),
            ),
            const SizedBox(height: 20),
            Text(widget.fileName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('${widget.sizeKb} KB',
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: fileColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: widget.onDownload,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download File'),
            ),
          ],
        );
    }
  }
}
