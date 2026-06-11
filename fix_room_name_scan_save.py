from pathlib import Path
import re

hasil = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")

if not hasil.exists():
    raise SystemExit("ERROR: hasil_denah_controller.dart tidak ditemukan.")

text = hasil.read_text(encoding="utf-8").replace("\r\n", "\n")
backup = hasil.with_suffix(hasil.suffix + ".before-fix-room-name.bak")
backup.write_text(text, encoding="utf-8")

# Cari file RoomModel
room_model_files = list(Path("lib").rglob("*.dart"))
room_model_text = ""
room_model_path = None

for p in room_model_files:
    t = p.read_text(encoding="utf-8", errors="ignore")
    if "class RoomModel" in t:
        room_model_text = t
        room_model_path = p
        break

if room_model_path is None:
    raise SystemExit("ERROR: class RoomModel tidak ditemukan di folder lib.")

# Deteksi nama field yang tersedia
candidates = [
    "roomName",
    "nama",
    "namaRuang",
    "label",
    "title",
    "type",
    "category",
]

field = None

for c in candidates:
    if re.search(r"\b" + re.escape(c) + r"\b", room_model_text):
        field = c
        break

if field is None:
    print("WARNING: field nama ruangan tidak ketemu, pakai fallback string 'Ruang'.")
    replacement = "'name': 'Ruang',"
else:
    print(f"RoomModel ditemukan di: {room_model_path}")
    print(f"Field nama ruangan terdeteksi: {field}")
    replacement = f"'name': room.{field},"

text = text.replace("'name': room.name,", replacement)

hasil.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: error room.name sudah diperbaiki.")
