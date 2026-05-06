// ─────────────────────────────────────────────────────────────────────────────
// opencut_editor_widget_mobile.dart  (Android / iOS)
// Uses webview_flutter to embed the self-hosted OpenCut editor.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'dart:io' show Platform;

/// Base URL of your self-hosted OpenCut fork on Cloudflare Pages.
/// UPDATE FOR LOCAL TESTING: Using 10.0.2.2 for Android emulator, localhost for iOS.
String get _kOpenCutBaseUrl {
  if (Platform.isAndroid) return 'http://10.0.2.2:3001';
  return 'http://localhost:3001';
}

class OpenCutEditorWidget extends StatefulWidget {
  /// Optional S3/local video URL to pre-load into the editor timeline.
  final String? videoUrl;

  /// Called when OpenCut fires an export-complete postMessage.
  /// Receives the exported video URL as a string.
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
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _isLoading = true; _hasError = false; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            // Inject postMessage listener so Flutter can capture export events
            _controller.runJavaScript(_buildPostMessageBridge());
          },
          onWebResourceError: (_) {
            if (mounted) setState(() { _isLoading = false; _hasError = true; });
          },
        ),
      )
      // Capture postMessages from OpenCut (export events)
      ..addJavaScriptChannel(
        'CreatorOSBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(_buildEditorUrl()));
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
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$_kOpenCutBaseUrl/editor?$query';
  }

  /// JS code injected after page load to relay postMessages to Flutter.
  String _buildPostMessageBridge() => '''
    (function() {
      window.addEventListener('message', function(event) {
        try {
          var data = typeof event.data === 'string'
              ? JSON.parse(event.data) : event.data;
          if (data && data.type === 'OPENCUT_EXPORT' && data.exportUrl) {
            CreatorOSBridge.postMessage(data.exportUrl);
          }
        } catch(e) {}
      });
    })();
  ''';

  void _handleMessage(String exportUrl) {
    widget.onExportComplete?.call(exportUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── WebView ──────────────────────────────────────────────────────────
        WebViewWidget(controller: _controller),

        // ── Loading overlay ──────────────────────────────────────────────────
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

        // ── Error state ──────────────────────────────────────────────────────
        if (_hasError)
          Container(
            color: const Color(0xFF0A0A0A),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_rounded,
                      color: Colors.white38, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load editor',
                      style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() { _isLoading = true; _hasError = false; });
                      _controller.loadRequest(Uri.parse(_buildEditorUrl()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
