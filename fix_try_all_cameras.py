from pathlib import Path

path = Path(r"lib\app\modules\scan_denah\views\scan_camera_capture_page.dart")

if not path.exists():
    raise SystemExit("ERROR: scan_camera_capture_page.dart tidak ditemukan.")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

backup = path.with_suffix(path.suffix + ".before-try-all-cameras.bak")
backup.write_text(text, encoding="utf-8")

start = text.find("  Future<void> _initCamera() async {")
end = text.find("  Future<void> _switchCamera() async {", start)

if start == -1 or end == -1:
    raise SystemExit("ERROR: method _initCamera / _switchCamera tidak ditemukan.")

new_init = r'''  Future<void> _initCamera() async {
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

'''

text = text[:start] + new_init + text[end:]

path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: aplikasi sekarang mencoba semua kamera yang tersedia.")
