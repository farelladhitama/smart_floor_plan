import 'dart:typed_data';

import 'package:flutter/material.dart';

Widget buildScanWebCameraCapture({
  required void Function(Uint8List bytes, String filename) onCaptured,
}) {
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Kamera web hanya aktif saat aplikasi dibuka lewat browser.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
