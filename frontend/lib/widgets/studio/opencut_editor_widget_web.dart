// ─────────────────────────────────────────────────────────────────────────────
// opencut_editor_widget_web.dart  (Flutter Web / Chrome)
// Uses HtmlElementView + dart:html IFrameElement to embed OpenCut.
// This file is only compiled on the web target.
// ─────────────────────────────────────────────────────────────────────────────

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

/// Base URL of your self-hosted OpenCut fork on Cloudflare Pages.
/// UPDATE FOR LOCAL TESTING: Using localhost:3001 (Next.js usually runs here if backend is on 3000)
const String _kOpenCutBaseUrl = 'http://127.0.0.1:3001';

class OpenCutEditorWidget extends StatefulWidget {
  /// Optional S3/local video URL to pre-load into the editor timeline.
  final String? videoUrl;

  /// Called when OpenCut fires an export-complete postMessage.
  final ValueChanged<String>? onExportComplete;

  const OpenCutEditorWidget({
    super.key,
    this.videoUrl,
    this.onExportComplete,
  });

  @override
  State<OpenCutEditorWidget> createState() => _OpenCutEditorWidgetState();
}

class _OpenCutEditorWidgetState extends State<OpenCutEditorWidget> {
  late final String _viewType;
  late final html.IFrameElement _iframe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Unique view type per instance to avoid conflicts
    _viewType = 'opencut-editor-${DateTime.now().microsecondsSinceEpoch}';

    _iframe = html.IFrameElement()
      ..src = _buildEditorUrl()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.background = '#0a0a0a'
      ..allow = 'camera *; microphone *; clipboard-read *; clipboard-write *; '
          'accelerometer; autoplay; encrypted-media; gyroscope'
      ..setAttribute('allowfullscreen', 'true');

    // Listen for load event → hide spinner
    _iframe.onLoad.listen((_) {
      if (mounted) setState(() => _isLoading = false);
      // Inject postMessage listener for export events
      _injectPostMessageBridge();
    });

    // Register the iframe factory ONCE per viewType
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    // Listen for postMessages from OpenCut (export events)
    html.window.onMessage.listen(_handleWindowMessage);
  }

  /// Build the full editor URL with query params.
  String _buildEditorUrl() {
    final params = <String, String>{
      'hideNav': 'true',
      'theme': 'dark',
      'embed': 'true',
    };
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      params['videoUrl'] = widget.videoUrl!;
    }
    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$_kOpenCutBaseUrl/editor?$query';
  }

  /// Inject a JS listener inside the iframe to relay export postMessages.
  void _injectPostMessageBridge() {
    try {
      _iframe.contentWindow?.postMessage({'type': 'CREATOROS_INIT'}, '*');
    } catch (_) {}
  }

  /// Handle messages posted from the OpenCut iframe.
  void _handleWindowMessage(html.MessageEvent event) {
    try {
      final data = event.data;
      if (data is Map && data['type'] == 'OPENCUT_EXPORT') {
        final url = data['exportUrl'] as String?;
        if (url != null && url.isNotEmpty) {
          widget.onExportComplete?.call(url);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── iframe via HtmlElementView ────────────────────────────────────────
        HtmlElementView(viewType: _viewType),

        // ── Loading spinner ───────────────────────────────────────────────────
        if (_isLoading)
          Container(
            color: const Color(0xFF0A0A0A),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Editor…',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
