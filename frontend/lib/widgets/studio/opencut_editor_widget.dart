// ─────────────────────────────────────────────────────────────────────────────
// opencut_editor_widget.dart
//
// Conditional import router:
//   • On Flutter Web  → opencut_editor_widget_web.dart   (HtmlElementView iframe)
//   • On Mobile/Desktop → opencut_editor_widget_mobile.dart (webview_flutter)
//
// Usage:
//   import 'opencut_editor_widget.dart';
//   OpenCutEditorWidget(videoUrl: 'https://...')
// ─────────────────────────────────────────────────────────────────────────────

export 'opencut_editor_widget_mobile.dart'
    if (dart.library.html) 'opencut_editor_widget_web.dart';
