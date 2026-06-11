# ============================================================
# PATCH FLUTTER - RAB PAKAI harga_rab DAN satuan_rab
# Jalankan dari root project smart_floor_plan
# ============================================================

$path = "lib\app\modules\rab\controllers\rab_controller.dart"

if (!(Test-Path $path)) {
  Write-Host "ERROR: File tidak ditemukan: $path" -ForegroundColor Red
  exit 1
}

Copy-Item $path "$path.before-harga-rab.bak" -Force

$text = Get-Content $path -Raw

$text = $text.Replace(
"final satuan = item?['satuan']?.toString() ?? fallbackSatuan;",
"final satuan = item?['satuan_rab']?.toString() ?? item?['satuan']?.toString() ?? fallbackSatuan;"
)

$text = $text.Replace(
"final hargaValue = item?['harga_rata_rata'];",
"final hargaValue = item?['harga_rab'] ?? item?['harga_rata_rata'];"
)

$text = $text.Replace(
"final value = item?['harga_rata_rata'];",
"final value = item?['harga_rab'] ?? item?['harga_rata_rata'];"
)

Set-Content $path $text -Encoding UTF8

flutter analyze 2>&1 | Select-String -Pattern "error -|Error:"
