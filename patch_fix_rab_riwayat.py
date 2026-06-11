from pathlib import Path
import re

rab_controller_path = Path(r"lib\app\modules\rab\controllers\rab_controller.dart")
rab_page_path = Path(r"lib\app\modules\rab\views\rab_page.dart")
riwayat_page_path = Path(r"lib\app\modules\riwayat\views\riwayat_page.dart")

for path in [rab_controller_path, rab_page_path, riwayat_page_path]:
    if not path.exists():
        raise SystemExit(f"ERROR: File tidak ditemukan: {path}")
    backup = path.with_suffix(path.suffix + ".before-fix-rab-riwayat.bak")
    backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

# ============================================================
# 1) PATCH RabController
# ============================================================

text = rab_controller_path.read_text(encoding="utf-8").replace("\r\n", "\n")

if "static Map<String, dynamic>? pendingArguments" not in text:
    text = text.replace(
        "class RabController extends GetxController {",
        """class RabController extends GetxController {
  static Map<String, dynamic>? pendingArguments;
  String _lastAppliedArgumentsSignature = '';"""
    )
elif "_lastAppliedArgumentsSignature" not in text:
    text = text.replace(
        "static Map<String, dynamic>? pendingArguments;",
        """static Map<String, dynamic>? pendingArguments;
  String _lastAppliedArgumentsSignature = '';"""
    )

new_read_args = """  void readArguments() {
    final dynamic routeArgs = Get.arguments;
    final dynamic args = routeArgs is Map ? routeArgs : pendingArguments;
    applyArgumentsFromPage(args);
  }

  void applyArgumentsFromPage(dynamic value) {
    final dynamic args = value is Map ? value : pendingArguments;

    if (args is! Map) {
      return;
    }

    final String signature = args.toString();

    if (_lastAppliedArgumentsSignature == signature) {
      return;
    }

    _lastAppliedArgumentsSignature = signature;
    pendingArguments = null;

    final selected = args['selectedMaterials'];

    if (selected is Map) {
      selected.forEach((key, value) {
        selectedMaterials[key.toString()] = value.toString();
      });
    }

    final singleMaterial = args['material'];
    if (singleMaterial != null &&
        singleMaterial.toString().trim().isNotEmpty) {
      selectedMaterials['Material Dinding'] = singleMaterial.toString();
    }

    final luas = args['luasBangunan'] ??
        args['totalLuas'] ??
        args['total_luas'] ??
        args['luasRuang'] ??
        args['totalLuasRuang'] ??
        args['inputLuas'];

    if (luas != null) {
      final parsed = double.tryParse(luas.toString().replaceAll(',', '.'));

      if (parsed != null && parsed > 0) {
        luasBangunan.value = parsed;
        luasController.text = parsed.toStringAsFixed(1);
      }
    }

    final lebar = args['inputLebarRumah'] ?? args['lebar_lahan'];
    final panjang = args['inputPanjangRumah'] ?? args['panjang_lahan'];

    if (lebar != null && panjang != null) {
      final w = double.tryParse(lebar.toString().replaceAll(',', '.'));
      final l = double.tryParse(panjang.toString().replaceAll(',', '.'));

      if (w != null && l != null && w > 0 && l > 0) {
        luasBangunan.value = w * l;
        luasController.text = luasBangunan.value.toStringAsFixed(1);
      }
    }

    if (rawMaterialOptions.isNotEmpty) {
      ensureDefaultSelectedMaterials();
      calculateRab();
    }
  }

  void setRooms(dynamic value) {"""

text, count = re.subn(
    r"  void readArguments\(\) \{.*?\n  void setRooms\(dynamic value\) \{",
    new_read_args,
    text,
    flags=re.S,
)

if count == 0:
    raise SystemExit("ERROR: Gagal patch RabController readArguments.")

rab_controller_path.write_text(text, encoding="utf-8")

# ============================================================
# 2) PATCH RabPage
# ============================================================

text = rab_page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

old_build = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""
new_build = """  @override
  Widget build(BuildContext context) {
    controller.applyArgumentsFromPage(Get.arguments);

    if (rooms != null) {
      controller.setRooms(rooms);
    }

    return Scaffold("""

if "controller.applyArgumentsFromPage(Get.arguments);" not in text:
    if old_build not in text:
        raise SystemExit("ERROR: Marker build RabPage tidak ditemukan.")
    text = text.replace(old_build, new_build)

rab_page_path.write_text(text, encoding="utf-8")

# ============================================================
# 3) PATCH RiwayatPage
# ============================================================

text = riwayat_page_path.read_text(encoding="utf-8").replace("\r\n", "\n")

if "app/modules/rab/controllers/rab_controller.dart" not in text:
    text = text.replace(
        "import 'package:get/get.dart';",
        """import 'package:get/get.dart';
import 'package:smart_floor_plan/app/modules/rab/controllers/rab_controller.dart';
import 'package:smart_floor_plan/app/modules/rab/views/rab_page.dart';"""
    )

new_open_rab = """  void _openRabDirect(Map<String, dynamic> item) {
    final double luas = _readRabArea(item);
    final double lebar = _readNumberRab(item['lebar_lahan']);
    final double panjang = _readNumberRab(item['panjang_lahan']);
    final dynamic rawMaterial = item['material'] ??
        item['material_dinding'] ??
        item['nama_material'] ??
        item['selected_material'];

    final String material = rawMaterial == null ||
            rawMaterial.toString().trim().isEmpty
        ? 'batu bata merah'
        : rawMaterial.toString().trim();

    final Map<String, dynamic> rabArgs = {
      'luasBangunan': luas,
      'totalLuas': luas,
      'total_luas': luas,
      'inputLuas': luas,
      'inputLebarRumah': lebar,
      'inputPanjangRumah': panjang,
      'lebar_lahan': lebar,
      'panjang_lahan': panjang,
      'material': material,
      'selectedMaterials': {
        'Material Dinding': material,
      },
      'rooms_json': item['rooms_json'],
    };

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    if (Get.isRegistered<RabController>()) {
      Get.delete<RabController>(force: true);
    }

    RabController.pendingArguments = rabArgs;

    Get.to(
      () => const RabPage(),
      arguments: rabArgs,
      binding: BindingsBuilder(() {
        Get.put(RabController());
      }),
    );
  }

  double _readRabArea"""

text, count = re.subn(
    r"  void _openRabDirect\(Map<String, dynamic> item\) \{.*?\n  \}\n\n  double _readRabArea",
    new_open_rab,
    text,
    flags=re.S,
)

if count == 0:
    raise SystemExit("ERROR: Gagal patch _openRabDirect di riwayat_page.dart.")

new_read_area = """  double _readRabArea(Map<String, dynamic> item) {
    final double totalLuas = _readNumberRab(
      item['total_luas'] ??
          item['totalLuas'] ??
          item['luasBangunan'] ??
          item['luas_bangunan'] ??
          item['inputLuas'],
    );

    if (totalLuas > 0) {
      return totalLuas;
    }

    final double lebar = _readNumberRab(item['lebar_lahan']);
    final double panjang = _readNumberRab(item['panjang_lahan']);

    if (lebar > 0 && panjang > 0) {
      return lebar * panjang;
    }

    return 100;
  }

  double _readNumberRab"""

text, count = re.subn(
    r"  double _readRabArea\(Map<String, dynamic> item\) \{.*?\n  \}\n\n  double _readNumberRab",
    new_read_area,
    text,
    flags=re.S,
)

if count == 0:
    raise SystemExit("ERROR: Gagal patch _readRabArea di riwayat_page.dart.")

riwayat_page_path.write_text(text, encoding="utf-8")

print("PATCH BERHASIL: RAB dari Riwayat sekarang harus membaca luas/material dari data riwayat.")
