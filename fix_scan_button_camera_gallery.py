from pathlib import Path
import re

path = Path(r"lib\app\modules\scan_denah\views\scan_denah_page.dart")

if not path.exists():
    raise SystemExit("ERROR: scan_denah_page.dart tidak ditemukan.")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

backup = path.with_suffix(path.suffix + ".before-fix-camera-button.bak")
backup.write_text(text, encoding="utf-8")

# Ganti semua kemungkinan pemanggilan tombol lama
patterns = [
    r"onPressed:\s*\(\)\s*=>\s*controller\.pickImage\(\)",
    r"onTap:\s*\(\)\s*=>\s*controller\.pickImage\(\)",
    r"onPressed:\s*controller\.pickImage",
    r"onTap:\s*controller\.pickImage",
    r"controller\.pickImage\(\);",
]

for pattern in patterns:
    text = re.sub(pattern, lambda m: m.group(0)
                  .replace("controller.pickImage()", "_showImageSourceSheet(controller)")
                  .replace("controller.pickImage", "() => _showImageSourceSheet(controller)")
                  .replace("controller.pickImage();", "_showImageSourceSheet(controller);"), text)

# Fix kalau ada hasil replace dobel/aneh
text = text.replace("() => _showImageSourceSheet(controller)()", "() => _showImageSourceSheet(controller)")
text = text.replace("_showImageSourceSheet(controller);", "_showImageSourceSheet(controller);")

# Ganti teks tombol agar jelas
text = text.replace("Pilih Gambar Denah", "Pilih Kamera / Galeri")
text = text.replace("Pilih gambar sketsa denah dari galeri.", "Ambil dari kamera atau pilih gambar dari galeri/file.")

# Pastikan helper bottom sheet ada
if "void _showImageSourceSheet(ScanDenahController controller)" not in text:
    insert_at = text.rfind("\n}")

    if insert_at == -1:
        raise SystemExit("ERROR: penutup class tidak ditemukan.")

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
    text = text[:insert_at] + helper + text[insert_at:]

path.write_text(text, encoding="utf-8")

print("FIX BERHASIL: tombol Scan sekarang diarahkan ke pilihan Kamera / Galeri.")
