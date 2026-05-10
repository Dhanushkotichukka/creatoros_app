import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../widgets/studio/opencut_editor_widget.dart';

/// Full-screen OpenCut editor screen.
///
/// Can be opened in two modes:
///   1. Blank editor  → no arguments
///   2. Pre-loaded    → pass [videoUrl] (S3 signed URL or local URL)
///
/// Navigation:
///   • Direct push:  Navigator.push(context, MaterialPageRoute(builder: (_) => VideoEditorScreen()))
///   • Named route:  Navigator.pushNamed(context, '/editor', arguments: {'videoUrl': url, 'title': 'My Video'})
class VideoEditorScreen extends StatefulWidget {
  /// Optional video URL to pre-load into OpenCut (S3 signed URL or local).
  final String? videoUrl;

  /// Optional display title shown in the "Back" bar.
  final String? projectTitle;

  const VideoEditorScreen({
    super.key,
    this.videoUrl,
    this.projectTitle,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  String? _exportedUrl;
  bool _showExportBanner = false;

  /// Called when the user exports from OpenCut.
  void _onExportComplete(String exportUrl) {
    if (!mounted) return;
    setState(() {
      _exportedUrl = exportUrl;
      _showExportBanner = true;
    });
    // Auto-dismiss banner after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showExportBanner = false);
    });
    _saveExportedVideo(exportUrl);
  }

  /// Stores the exported video URL to the backend (saves to storage list).
  Future<void> _saveExportedVideo(String exportUrl) async {
    try {
      await http.post(
        Uri.parse('https://creatoros-backend-rb5b.onrender.com/api/media/save-export'),
        headers: ApiService.authHeaders,
        body: jsonEncode({
          'exportUrl': exportUrl,
          'title': widget.projectTitle ?? 'Edited Video',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Export save warning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── OpenCut Editor (full screen) ──────────────────────────────────
            OpenCutEditorWidget(
              videoUrl: widget.videoUrl,
              onExportComplete: _onExportComplete,
            ),

            // ── "Back to Studio" overlay button ──────────────────────────────
            Positioned(
              top: 12,
              left: 12,
              child: _BackToStudioButton(
                onTap: () => Navigator.of(context).pop(),
              ),
            ),

            // ── Project title chip (top-center) ───────────────────────────────
            if (widget.projectTitle != null)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      widget.projectTitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Export success banner ─────────────────────────────────────────
            if (_showExportBanner)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: _ExportSuccessBanner(
                  exportUrl: _exportedUrl!,
                  onDismiss: () => setState(() => _showExportBanner = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back to Studio Button
// ─────────────────────────────────────────────────────────────────────────────
class _BackToStudioButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackToStudioButton({required this.onTap});

  @override
  State<_BackToStudioButton> createState() => _BackToStudioButtonState();
}

class _BackToStudioButtonState extends State<_BackToStudioButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 6),
              const Text(
                'Studio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export Success Banner
// ─────────────────────────────────────────────────────────────────────────────
class _ExportSuccessBanner extends StatelessWidget {
  final String exportUrl;
  final VoidCallback onDismiss;

  const _ExportSuccessBanner({
    required this.exportUrl,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Export Complete!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Video saved to your Storage',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
