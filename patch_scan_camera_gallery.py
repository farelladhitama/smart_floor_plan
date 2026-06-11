from pathlib import Path

controller_path = Path(r"lib\app\modules\scan_denah\controllers\scan_denah_controller.dart")
page_path = Path(r"lib\app\modules\scan_denah\views\scan_denah_page.dart")
manifest_path = Path(r"android\app\src\main\AndroidManifest.xml")

if not controller_path.exists():
    raise SystemExit("ERROR: scan_denah_controller.dart tidak ditemukan.")

if not page_path.exists():
    raise SystemExit("ERROR: scan_denah_page.dart tidak ditemukan.")

controller_text = controller_path.read_text(encoding="utf-8").replace("\r\n", "\n")
page_text = page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

controller_path.with_suffix(controller_path.suffix + ".before-camera-source.bak").write_text(controller_text, encoding="utf-8")
page_path.with_suffix(page_path.suffix + ".before-camera-source.bak").write_text(page_text, encoding="utf-8")

def replace_method(text, signature, new_method):
    start = text.find(signature)

    if start == -1:
        raise SystemExit(f"ERROR: method tidak ditemukan: {signature}")

    brace_start = text.find("{", start)

    if brace_start == -1:
        raise SystemExit(f"ERROR: body method tidak ditemukan: {signature}")

    depth = 0
    end = None

    for i in range(brace_start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1

            if depth == 0:
                end = i + 1
                break

    if end is None:
        raise SystemExit(f"ERROR: akhir method tidak ditemukan: {signature}")

    return text[:start] + new_method + text[end:]

# ============================================================
# 1. Controller: ganti pickImage jadi bisa galeri + kamera
# ============================================================

new_pick_methods = r'''  Future<void> pickImage() async {
    await pickImageFromGallery();
  }

  Future<void> pickImageFromGallery() async {
    await _pickImageFromSource(ImageSource.gallery);
  }

  Future<void> pickImageFromCamera() async {
    await _pickImageFromSource(ImageSource.camera);
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2400,
        maxHeight: 2400,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes = await image.readAsBytes();

      selectedImageBytes.value = bytes;
      selectedImageName.value = image.name;
      detectedRooms.clear();

      if (source == ImageSource.camera) {
        message.value = 'Foto dari kamera berhasil diambil. Memproses scan...';
      } else {
        message.value = 'Gambar berhasil dipilih. Memproses scan...';
      }

      await scanImageWithOpenCV(bytes);
    } catch (e) {
      message.value = 'Gagal mengambil gambar: $e';
      Get.snackbar(
        'Gagal',
        'Gagal mengambil gambar. Pastikan izin kamera/file sudah diberikan.',
      );
    }
  }'''

controller_text = replace_method(
    controller_text,
    "  Future<void> pickImage() async {",
    new_pick_methods,
)

controller_path.write_text(controller_text, encoding="utf-8")

# ============================================================
# 2. Page: tombol pilih gambar diarahkan ke bottom sheet sumber gambar
# ============================================================

page_text = page_text.replace(
    "controller.pickImage()",
    "_showImageSourceSheet(controller)",
)

# Tambah helper bottom sheet sebelum penutup class terakhir
if "void _showImageSourceSheet(ScanDenahController controller)" not in page_text:
    insert_at = page_text.rfind("\n}")

    if insert_at == -1:
        raise SystemExit("ERROR: penutup class ScanDenahPage tidak ditemukan.")

    helper = r'''

  void _showImageSourceSheet(ScanDenahController controller) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Sumber Denah',
                  style: TextStyle(
                    color: navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gunakan kamera atau pilih gambar denah kosong dari galeri/file.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _imageSourceButton(
                icon: Icons.camera_alt_rounded,
                title: 'Ambil dari Kamera',
                subtitle: 'Buka kamera HP atau kamera laptop/browser',
                onTap: () {
                  Get.back();
                  controller.pickImageFromCamera();
                },
              ),
              const SizedBox(height: 12),
              _imageSourceButton(
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari Galeri / File',
                subtitle: 'Ambil gambar denah kosong yang sudah tersimpan',
                onTap: () {
                  Get.back();
                  controller.pickImageFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _imageSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.withOpacity(0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: orange,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
'''
    page_text = page_text[:insert_at] + helper + page_text[insert_at:]

page_path.write_text(page_text, encoding="utf-8")

# ============================================================
# 3. Android permission kamera
# ============================================================

if manifest_path.exists():
    manifest_text = manifest_path.read_text(encoding="utf-8").replace("\r\n", "\n")
    manifest_path.with_suffix(manifest_path.suffix + ".before-camera-permission.bak").write_text(manifest_text, encoding="utf-8")

    if "android.permission.CAMERA" not in manifest_text:
        manifest_text = manifest_text.replace(
            "<manifest",
            '<manifest',
            1,
        )

        app_index = manifest_text.find("<application")

        if app_index != -1:
            manifest_text = (
                manifest_text[:app_index]
                + '    <uses-permission android:name="android.permission.CAMERA" />\n\n'
                + manifest_text[app_index:]
            )

            manifest_path.write_text(manifest_text, encoding="utf-8")

print("PATCH BERHASIL: Scan Denah sekarang bisa pilih Kamera atau Galeri/File.")
