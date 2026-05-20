class OfflineAbsensiModel {
  final String id; // UUID lokal
  final String tipe; // masuk / pulang
  final String fotoPath; // path file foto lokal
  final double latitude;
  final double longitude;
  final DateTime waktuAbsen;
  final String status; // pending / syncing / failed
  final String? errorMessage;

  OfflineAbsensiModel({
    required this.id,
    required this.tipe,
    required this.fotoPath,
    required this.latitude,
    required this.longitude,
    required this.waktuAbsen,
    this.status = 'pending',
    this.errorMessage,
  });

  factory OfflineAbsensiModel.fromJson(Map<String, dynamic> json) {
    return OfflineAbsensiModel(
      id: json['id'],
      tipe: json['tipe'],
      fotoPath: json['foto_path'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      waktuAbsen: DateTime.parse(json['waktu_absen']),
      status: json['status'] ?? 'pending',
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipe': tipe,
    'foto_path': fotoPath,
    'latitude': latitude,
    'longitude': longitude,
    'waktu_absen': waktuAbsen.toIso8601String(),
    'status': status,
    'error_message': errorMessage,
  };

  OfflineAbsensiModel copyWith({String? status, String? errorMessage}) {
    return OfflineAbsensiModel(
      id: id,
      tipe: tipe,
      fotoPath: fotoPath,
      latitude: latitude,
      longitude: longitude,
      waktuAbsen: waktuAbsen,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
