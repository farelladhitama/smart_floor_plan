import 'dart:typed_data';

import 'package:printing/printing.dart';

class PdfDownloadHelper {
  static Future<void> saveOrShare({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }
}
