import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'scan_web_camera_capture_widget_stub.dart'
    if (dart.library.html) 'scan_web_camera_capture_widget_web.dart';

class ScanCameraCapturePage extends StatefulWidget {
  const ScanCameraCapturePage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);

  @override
  State<ScanCameraCapturePage> createState() => _ScanCameraCapturePageState();
}

class _ScanCameraCapturePageState extends State<ScanCameraCapturePage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = <CameraDescription>[];

  bool _isLoading = true;
  bool _isTakingPicture = false;
  String? _errorMessage;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kamera tidak ditemukan di perangkat ini.';
        });
        return;
      }

      await _cameraController?.dispose();
      _cameraController = null;

      CameraController? workingController;
      Object? lastError;

      final List<int> cameraOrder = <int>[
        _selectedCameraIndex,
        ...List<int>.generate(_cameras.length, (index) => index)
            .where((index) => index != _selectedCameraIndex),
      ];

      for (final int cameraIndex in cameraOrder) {
        for (final ResolutionPreset preset in <ResolutionPreset>[
          ResolutionPreset.medium,
          ResolutionPreset.low,
        ]) {
          try {
            final CameraController testController = CameraController(
              _cameras[cameraIndex],
              preset,
              enableAudio: false,
            );

            await testController.initialize();

            workingController = testController;
            _selectedCameraIndex = cameraIndex;
            break;
          } catch (e) {
            lastError = e;
          }
        }

        if (workingController != null) {
          break;
        }
      }

      if (workingController == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Kamera terdeteksi, tapi tidak bisa dibaca browser. Coba buka di Chrome, cek izin kamera pada ikon gembok URL, atau cek Camera Windows. Error: $lastError';
        });
        return;
      }

      _cameraController = workingController;

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
            'Gagal membuka kamera. Pastikan izin kamera browser/Windows aktif. Error: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1 || _isTakingPicture) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCamera();
  }

  Future<void> _takePicture() async {
    final CameraController? controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (_isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final XFile file = await controller.takePicture();
      final Uint8List bytes = await file.readAsBytes();

      if (!mounted) return;

      Get.back(
        result: {
          'bytes': bytes,
          'filename':
              'scan_camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTakingPicture = false;
        _errorMessage = 'Gagal mengambil foto: $e';
      });
    }
  }

  @override
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
        actions: [
          if (_cameras.length > 1)
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(Icons.cameraswitch_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed:
                  _isLoading || _errorMessage != null || _isTakingPicture
                      ? null
                      : _takePicture,
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
                _isTakingPicture ? 'Mengambil Foto...' : 'Ambil Foto Denah',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ScanCameraCapturePage.orange,
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
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ScanCameraCapturePage.orange,
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
                  color: ScanCameraCapturePage.orange,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ScanCameraCapturePage.navy,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initCamera,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScanCameraCapturePage.navy,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final CameraController? controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text('Kamera belum siap.'),
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
            child: CameraPreview(controller),
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
      ],
    );
  }
}
