class PusatLokasiModel {
  final int id;
  final int? companyId; // FIXED: tambah company_id dari backend
  final String namaLokasi;
  final String titikKordinat;
  final String? keterangan;
  final bool isActive; // FIXED: tambah is_active dari backend
  final DateTime createdAt;
  final DateTime updatedAt;

  PusatLokasiModel({
    required this.id,
    this.companyId,
    required this.namaLokasi,
    required this.titikKordinat,
    this.keterangan,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PusatLokasiModel.fromJson(Map<String, dynamic> json) {
    return PusatLokasiModel(
      id: json['id'],
      companyId: json['company_id'],
      namaLokasi: json['nama_lokasi'],
      titikKordinat: json['titik_kordinat'],
      keterangan: json['keterangan'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  double? get latitude {
    try {
      final parts = titikKordinat.split(',');
      if (parts.length == 2) return double.tryParse(parts[0].trim());
    } catch (_) {}
    return null;
  }

  double? get longitude {
    try {
      final parts = titikKordinat.split(',');
      if (parts.length == 2) return double.tryParse(parts[1].trim());
    } catch (_) {}
    return null;
  }

  String get formattedKordinat {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
    }
    return titikKordinat;
  }

  bool get isKordinatValid => latitude != null && longitude != null;

  @override
  String toString() =>
      'PusatLokasi{id: $id, nama: $namaLokasi, aktif: $isActive}';
}
