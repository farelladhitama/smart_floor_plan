import 'dart:html' as html;
import 'dart:typed_data';

class PdfDownloadHelper {
  static Future<void> saveOrShare({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final html.Blob blob = html.Blob(
      <Object>[bytes],
      'application/pdf',
    );

    final String url = html.Url.createObjectUrlFromBlob(blob);

    final html.AnchorElement anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);
  }
}
