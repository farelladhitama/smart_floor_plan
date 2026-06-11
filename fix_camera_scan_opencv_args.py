from pathlib import Path

path = Path(r"lib\app\modules\scan_denah\controllers\scan_denah_controller.dart")

if not path.exists():
    raise SystemExit("ERROR: scan_denah_controller.dart tidak ditemukan.")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

backup = path.with_suffix(path.suffix + ".before-fix-camera-opencv-args.bak")
backup.write_text(text, encoding="utf-8")

text = text.replace(
    "await scanImageWithOpenCV(bytes);",
    "await scanImageWithOpenCV(bytes, image.name);"
)

path.write_text(text, encoding="utf-8")

print("FIX BERHASIL: parameter scanImageWithOpenCV sudah diperbaiki.")
