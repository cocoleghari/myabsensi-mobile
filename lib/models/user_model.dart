class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;

  final String? nik;
  final String? namaStempel;
  final DateTime? tglLahir;
  final String? jk;
  final String? alamat;
  final String? jabatan;
  final String? kantor;
  final DateTime? tglMasuk;
  final String? nomorTelp;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,

    required this.nik,
    required this.namaStempel,
    required this.tglLahir,
    required this.jk,
    required this.alamat,
    required this.jabatan,
    required this.kantor,
    required this.tglMasuk,
    required this.nomorTelp,
    required this.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],

      nik: json['nik'],
      namaStempel: json['nama_stempel'],
      tglLahir: json['tgl_lahir'] != null
          ? DateTime.parse(json['tgl_lahir'])
          : null,
      jk: json['jk'],
      alamat: json['alamat'],
      jabatan: json['jabatan'],
      kantor: json['kantor'],
      tglMasuk: json['tgl_masuk'] != null
          ? DateTime.parse(json['tgl_masuk'])
          : null,
      nomorTelp: json['nomor_telp'],
      photoUrl: json['photo_url'],
    );
  }
}
