// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;

void registerWebViewFactory(String viewId, String url, String fileType) {
  try {
    if (fileType == 'video') {
      ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        return html.VideoElement()
          ..src = url
          ..controls = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '12px'
          ..autoplay = false;
      });
    } else if (fileType == 'sound') {
      ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        final div = html.DivElement()
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.background = 'transparent';

        final audio = html.AudioElement()
          ..src = url
          ..controls = true
          ..style.width = '90%';

        div.append(audio);
        return div;
      });
    }
  } catch (_) {}
}
