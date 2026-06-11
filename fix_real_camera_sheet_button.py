from pathlib import Path

path = Path(r"lib\app\modules\scan_denah\views\scan_denah_page.dart")

if not path.exists():
    raise SystemExit("ERROR: scan_denah_page.dart tidak ditemukan.")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

backup = path.with_suffix(path.suffix + ".before-fix-real-camera-sheet.bak")
backup.write_text(text, encoding="utf-8")

old = """                onPressed:
                    controller.isProcessing.value ? null : controller.pickImage,
"""

new = """                onPressed: controller.isProcessing.value
                    ? null
                    : () => _showImageSourceSheet(controller),
"""

if old not in text:
    raise SystemExit("ERROR: pola tombol lama tidak ketemu. Kirim ulang bagian tombol ElevatedButton.icon.")

text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")

print("FIX BERHASIL: tombol sekarang buka pilihan Kamera / Galeri.")
