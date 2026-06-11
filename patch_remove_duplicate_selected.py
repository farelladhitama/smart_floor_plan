from pathlib import Path
import re

path = Path(r"lib\app\modules\hasil_denah\controllers\hasil_denah_controller.dart")

if not path.exists():
    raise SystemExit(f"ERROR: File tidak ditemukan: {path}")

backup = path.with_suffix(path.suffix + ".before-remove-duplicate-selected.bak")
backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

# Hapus deklarasi selected yang dobel berurutan
text = re.sub(
    r"(\n\s*final Map<String, String> selected = _effectiveSelectedMaterials\(\);\s*){2,}",
    "\n      final Map<String, String> selected = _effectiveSelectedMaterials();\n",
    text,
)

# Hapus deklarasi estimasiMaterialRab kalau dobel berurutan
text = re.sub(
    r"(\n\s*final double estimasiMaterialRab = await _calculateEstimasiMaterialRab\(\s*selectedMaterials: selected,\s*luasBangunan: totalLandArea,\s*\);\s*){2,}",
    "\n      final double estimasiMaterialRab = await _calculateEstimasiMaterialRab(\n        selectedMaterials: selected,\n        luasBangunan: totalLandArea,\n      );\n",
    text,
    flags=re.S,
)

path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: duplikat selected sudah dihapus.")
