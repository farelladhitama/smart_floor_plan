import 'dart:async';
import 'dart:convert';
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
        _isTakingPicture = false;
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
