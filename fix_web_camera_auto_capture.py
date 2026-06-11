from pathlib import Path

path = Path(r"lib\app\modules\scan_denah\views\scan_web_camera_capture_widget_web.dart")

if not path.exists():
    raise SystemExit("ERROR: scan_web_camera_capture_widget_web.dart tidak ditemukan.")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

backup = path.with_suffix(path.suffix + ".before-fix-auto-capture-web.bak")
backup.write_text(text, encoding="utf-8")

# Pastikan import base64 ada
if "import 'dart:convert';" not in text:
    text = text.replace(
        "import 'dart:async';",
        "import 'dart:async';\nimport 'dart:convert';",
    )

# Reset status saat kamera dibuka ulang
text = text.replace(
"""      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
""",
"""      setState(() {
        _isLoading = true;
        _isTakingPicture = false;
        _errorMessage = null;
      });
""",
1
)

# Ganti method _takePicture supaya tidak auto dan hasil foto aman
start = text.find("  Future<void> _takePicture() async {")
end = text.find("  @override\n  Widget build(BuildContext context)", start)

if start == -1 or end == -1:
    raise SystemExit("ERROR: method _takePicture tidak ditemukan.")

new_method = r'''  Future<void> _takePicture() async {
    if (_isTakingPicture) {
      return;
    }

    if (_videoElement.videoWidth <= 0 || _videoElement.videoHeight <= 0) {
      setState(() {
        _errorMessage =
            'Kamera belum siap mengambil gambar. Tunggu preview muncul lalu coba lagi.';
      });
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
        _errorMessage = null;
      });

      await Future.delayed(const Duration(milliseconds: 250));

      final int width = _videoElement.videoWidth;
      final int height = _videoElement.videoHeight;

      final html.CanvasElement canvas = html.CanvasElement(
        width: width,
        height: height,
      );

      final html.CanvasRenderingContext2D context = canvas.context2D;

      context.drawImageScaled(
        _videoElement,
        0,
        0,
        width,
        height,
      );

      final String dataUrl = canvas.toDataUrl('image/jpeg', 0.95);

      if (!dataUrl.contains(',')) {
        throw Exception('Format hasil foto kamera tidak valid.');
      }

      final String base64Image = dataUrl.split(',').last;
      final Uint8List bytes = base64Decode(base64Image);

      if (bytes.isEmpty) {
        throw Exception('Hasil foto kamera kosong.');
      }

      if (!mounted) return;

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

'''

text = text[:start] + new_method + text[end:]

path.write_text(text, encoding="utf-8")

print("FIX BERHASIL: kamera web tidak auto cekrek dan hasil foto dibaca pakai base64.")
