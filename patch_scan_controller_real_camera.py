from pathlib import Path

path = Path(r"lib\app\modules\scan_denah\controllers\scan_denah_controller.dart")

if not path.exists():
    raise SystemExit("ERROR: scan_denah_controller.dart tidak ditemukan.")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

backup = path.with_suffix(path.suffix + ".before-real-camera-method.bak")
backup.write_text(text, encoding="utf-8")

if "Future<void> scanPickedImageBytes({" not in text:
    marker = "  Future<void> scanImageWithOpenCV(\n"

    if marker not in text:
        raise SystemExit("ERROR: marker scanImageWithOpenCV tidak ditemukan.")

    method = r'''  Future<void> scanPickedImageBytes({
    required Uint8List bytes,
    required String filename,
    bool fromCamera = false,
  }) async {
    selectedImageBytes.value = bytes;
    selectedImageName.value = filename;
    detectedRooms.clear();

    if (fromCamera) {
      message.value = 'Foto dari kamera berhasil diambil. Memproses scan...';
    } else {
      message.value = 'Gambar berhasil dipilih. Memproses scan...';
    }

    await scanImageWithOpenCV(bytes, filename);
  }

'''

    text = text.replace(marker, method + marker, 1)

path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: controller bisa menerima foto dari kamera.")
