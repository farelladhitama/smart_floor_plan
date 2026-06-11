from pathlib import Path

path = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")

if not path.exists():
    raise SystemExit(f"ERROR: File tidak ditemukan: {path}")

backup = path.with_suffix(path.suffix + ".before-fix-selected.bak")
backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

target = "      final Map<String, dynamic> payload = {"

insert = """      final Map<String, String> selected = _effectiveSelectedMaterials();

"""

payload_index = text.find(target)

if payload_index == -1:
    raise SystemExit("ERROR: Marker payload tidak ditemukan di HasilDenahController.")

before_payload = text[max(0, payload_index - 700):payload_index]

if "final Map<String, String> selected = _effectiveSelectedMaterials();" not in before_payload:
    text = text.replace(target, insert + target, 1)

path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: selected sudah ditambahkan sebelum payload simpan denah.")
