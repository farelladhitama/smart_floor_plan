from pathlib import Path

path = Path(r"lib\app\modules\scan_denah\views\scan_denah_page.dart")

if not path.exists():
    raise SystemExit("ERROR: scan_denah_page.dart tidak ditemukan.")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

backup = path.with_suffix(path.suffix + ".before-real-camera-web-mobile.bak")
backup.write_text(text, encoding="utf-8")

if "dart:typed_data" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';",
        "import 'dart:typed_data';\n\nimport 'package:flutter/material.dart';",
    )

if "scan_camera_capture_page.dart" not in text:
    text = text.replace(
        "import '../controllers/scan_denah_controller.dart';",
        "import '../controllers/scan_denah_controller.dart';\nimport 'scan_camera_capture_page.dart';",
    )

old = """                onTap: () {
                  Get.back();
                  controller.pickImageFromCamera();
                },
"""

new = """                onTap: () async {
                  Get.back();

                  final result = await Get.to<Map<String, dynamic>>(
                    () => const ScanCameraCapturePage(),
                  );

                  if (result == null) return;

                  final dynamic bytes = result['bytes'];
                  final String filename =
                      (result['filename'] ?? 'scan_camera.jpg').toString();

                  if (bytes is Uint8List) {
                    await controller.scanPickedImageBytes(
                      bytes: bytes,
                      filename: filename,
                      fromCamera: true,
                    );
                  }
                },
"""

if old not in text:
    raise SystemExit("ERROR: bagian onTap kamera lama tidak ditemukan.")

text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: tombol kamera sekarang pakai CameraPreview, bukan file picker.")
