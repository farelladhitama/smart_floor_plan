class MaterialItem {
  final String id;
  final String kategori;
  final String namaMaterial;
  final String satuan;
  final double hargaMinimum;
  final double hargaRataRata;
  final double hargaMaksimum;
  final int jumlahData;
  final String sumber;
  final String metodePengambilan;
  final bool isActive;
  final DateTime updatedAt;
  final double? hargaRab;
  final String? satuanRab;
  final String? catatanSatuan;

  MaterialItem({
    required this.id,
    required this.kategori,
    required this.namaMaterial,
    required this.satuan,
    required this.hargaMinimum,
    required this.hargaRataRata,
    required this.hargaMaksimum,
    required this.jumlahData,
    required this.sumber,
    required this.metodePengambilan,
    required this.isActive,
    required this.updatedAt,
    this.hargaRab,
    this.satuanRab,
    this.catatanSatuan,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] ?? '',
      kategori: json['kategori'] ?? '',
      namaMaterial: json['nama_material'] ?? '',
      satuan: json['satuan'] ?? '',
      hargaMinimum: (json['harga_minimum'] ?? 0).toDouble(),
      hargaRataRata: (json['harga_rata_rata'] ?? 0).toDouble(),
      hargaMaksimum: (json['harga_maksimum'] ?? 0).toDouble(),
      jumlahData: (json['jumlah_data'] ?? 0).toInt(),
      sumber: json['sumber'] ?? 'Bhinneka',
      metodePengambilan: json['metode_pengambilan'] ?? 'scraping_crawling',
      isActive: json['is_active'] ?? true,
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      hargaRab: json['harga_rab']?.toDouble(),
      satuanRab: json['satuan_rab'],
      catatanSatuan: json['catatan_satuan'],
    );
  }

  // Untuk tampilan harga utama (pakai harga_rata_rata)
  double get hargaUtama => hargaRataRata;
}