/// Model untuk response GET /user/lokasi
/// Source: UserLokasiController@getUserLokasi
///
/// Response per item:
/// {
///   "id": 1,                    ← id pivot (employee_pusat_lokasi)
///   "pusat_lokasi_id": 3,
///   "nama_lokasi": "Kantor Pusat",
///   "titik_kordinat": "-7.797068,110.370529",
///   "latitude": -7.797068,      ← sudah diparsing oleh backend
///   "longitude": 110.370529,    ← sudah diparsing oleh backend
///   "radius_meter": 100,
///   "is_active": true
/// }
class LokasiModel {
  final int id; // id pivot employee_pusat_lokasi
  final int pusatLokasiId;
  final String namaLokasi;
  final String titikKordinat;
  final double latitude; // sudah diparsing, langsung pakai
  final double longitude; // sudah diparsing, langsung pakai
  final int radiusMeter;
  final bool isActive;

  LokasiModel({
    required this.id,
    required this.pusatLokasiId,
    required this.namaLokasi,
    required this.titikKordinat,
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
    required this.isActive,
  });

  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiModel(
      id: json['id'],
      pusatLokasiId: json['pusat_lokasi_id'],
      namaLokasi: json['nama_lokasi'] ?? '',
      titikKordinat: json['titik_kordinat'] ?? '',
      // Backend sudah mengirim latitude & longitude sebagai double
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeter: (json['radius_meter'] as num?)?.toInt() ?? 100,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pusat_lokasi_id': pusatLokasiId,
    'nama_lokasi': namaLokasi,
    'titik_kordinat': titikKordinat,
    'latitude': latitude,
    'longitude': longitude,
    'radius_meter': radiusMeter,
    'is_active': isActive,
  };
}
