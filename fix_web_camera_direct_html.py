from pathlib import Path

base = Path(r"lib\app\modules\scan_denah\views")
page_path = base / "scan_camera_capture_page.dart"

if not page_path.exists():
    raise SystemExit("ERROR: scan_camera_capture_page.dart tidak ditemukan.")

# ============================================================
# 1. Buat stub untuk non-web / mobile
# ============================================================

stub_code = r'''
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
'''

(base / "scan_web_camera_capture_widget_stub.dart").write_text(
    stub_code.strip() + "\n",
    encoding="utf-8",
)

# ============================================================
# 2. Buat kamera web khusus browser Chrome/Edge
# ============================================================

web_code = r'''
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class ScanWebCameraCaptureWidget extends StatefulWidget {
  final void Function(Uint8List bytes, String filename) onCaptured;

  const ScanWebCameraCaptureWidget({
    super.key,
    required this.onCaptured,
  });

  @override
  State<ScanWebCameraCaptureWidget> createState() =>
      _ScanWebCameraCaptureWidgetState();
}

class _ScanWebCameraCaptureWidgetState
    extends State<ScanWebCameraCaptureWidget> {
  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);

  late final String _viewType;
  late final html.VideoElement _videoElement;

  html.MediaStream? _stream;

  bool _isLoading = true;
  bool _isTakingPicture = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _viewType = 'scan-web-camera-${DateTime.now().millisecondsSinceEpoch}';

    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.borderRadius = '22px'
      ..style.backgroundColor = 'black';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement,
    );

    _startCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  Future<void> _startCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _stopCamera();

      final html.MediaDevices? mediaDevices =
          html.window.navigator.mediaDevices;

      if (mediaDevices == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Browser tidak mendukung akses kamera.';
        });
        return;
      }

      final Map<String, dynamic> constraints = {
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'facingMode': 'environment',
        },
        'audio': false,
      };

      final html.MediaStream stream =
          await mediaDevices.getUserMedia(constraints);

      _stream = stream;
      _videoElement.srcObject = stream;

      await _videoElement.play();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Gagal membuka kamera web. Pastikan pilih Allow dan kamera tidak diblokir browser. Error: $e';
      });
    }
  }

  void _stopCamera() {
    final html.MediaStream? stream = _stream;

    if (stream != null) {
      for (final html.MediaStreamTrack track in stream.getTracks()) {
        track.stop();
      }
    }

    _stream = null;
    _videoElement.srcObject = null;
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final int width = _videoElement.videoWidth > 0
          ? _videoElement.videoWidth
          : 1280;
      final int height = _videoElement.videoHeight > 0
          ? _videoElement.videoHeight
          : 720;

      final html.CanvasElement canvas = html.CanvasElement(
        width: width,
        height: height,
      );

      canvas.context2D.drawImageScaled(
        _videoElement,
        0,
        0,
        width,
        height,
      );

      final html.Blob blob = await canvas.toBlob('image/jpeg', 0.95);
      final html.FileReader reader = html.FileReader();

      reader.readAsArrayBuffer(blob);

      await reader.onLoad.first;

      final Object? result = reader.result;

      if (result is! ByteBuffer) {
        throw Exception('Gagal membaca hasil foto kamera.');
      }

      final Uint8List bytes = result.asUint8List();

      widget.onCaptured(
        bytes,
        'scan_camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal mengambil foto: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: orange,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: orange,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: navy,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _startCamera,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: HtmlElementView(
              viewType: _viewType,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Text(
            'Arahkan kamera ke denah kosong. Usahakan garis dinding tebal, terang, dan tidak miring.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTakingPicture ? null : _takePicture,
                icon: _isTakingPicture
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt_rounded),
                label: Text(
                  _isTakingPicture
                      ? 'Mengambil Foto...'
                      : 'Ambil Foto Denah',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildScanWebCameraCapture({
  required void Function(Uint8List bytes, String filename) onCaptured,
}) {
  return ScanWebCameraCaptureWidget(
    onCaptured: onCaptured,
  );
}
'''

(base / "scan_web_camera_capture_widget_web.dart").write_text(
    web_code.strip() + "\n",
    encoding="utf-8",
)

# ============================================================
# 3. Patch halaman camera utama agar web pakai kamera HTML
# ============================================================

text = page_path.read_text(encoding="utf-8").replace("\r\n", "\n")
backup = page_path.with_suffix(page_path.suffix + ".before-web-html-camera.bak")
backup.write_text(text, encoding="utf-8")

if "package:flutter/foundation.dart" not in text:
    text = text.replace(
        "import 'package:camera/camera.dart';",
        "import 'package:camera/camera.dart';\nimport 'package:flutter/foundation.dart';",
    )

if "scan_web_camera_capture_widget_stub.dart" not in text:
    text = text.replace(
        "import 'package:get/get.dart';",
        "import 'package:get/get.dart';\n\nimport 'scan_web_camera_capture_widget_stub.dart'\n    if (dart.library.html) 'scan_web_camera_capture_widget_web.dart';",
    )

old = """  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScanCameraCapturePage.background,
      appBar: AppBar(
"""

new = """  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: ScanCameraCapturePage.background,
        appBar: AppBar(
          backgroundColor: ScanCameraCapturePage.navy,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Ambil Foto Denah',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: buildScanWebCameraCapture(
            onCaptured: (Uint8List bytes, String filename) {
              Get.back(
                result: {
                  'bytes': bytes,
                  'filename': filename,
                },
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ScanCameraCapturePage.background,
      appBar: AppBar(
"""

if old not in text:
    raise SystemExit("ERROR: bagian build Scaffold tidak ketemu.")

text = text.replace(old, new, 1)

page_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: Web/laptop sekarang pakai kamera browser langsung, Android tetap pakai camera package.")
