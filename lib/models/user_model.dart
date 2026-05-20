/// Model untuk data User (credentials only).
/// Source: User.php — hanya menyimpan: id, name, email, role, is_active
/// Field lama (nik, nama_stempel, jabatan, kantor, jk, nomor_telp, tgl_masuk, dll)
/// sudah DIPINDAH ke Employee.php dan tidak ada lagi di tabel users.
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'is_active': isActive,
  };
}

/// Model untuk data Employee yang dikirim di response login.
/// Source: AuthController@login — field 'employee' dalam response
///
/// {
///   "id": 1,
///   "employee_code": "EMP001",
///   "nik": "3404...",
///   "full_name": "Budi Santoso",
///   "nickname": "Budi",
///   "gender": "L",
///   "photo_url": "http://...",
///   "wajah_terdaftar": true,
///   "phone": "08123...",
///   "join_date": "2023-01-01",
///   "employment_type": "permanent",
///   "department": "IT",     ← nama string (bukan object)
///   "position": "Backend",  ← nama string (bukan object)
///   "company": "PT. ABC"    ← nama string (bukan object)
/// }
class LoginEmployeeModel {
  final int id;
  final String? employeeCode;
  final String? nik;
  final String fullName;
  final String? nickname;
  final String? gender;
  final String? photoUrl;
  final bool wajahTerdaftar;
  final String? phone;
  final String? joinDate;
  final String? employmentType;
  final String? department; // nama string langsung
  final String? position; // nama string langsung
  final String? company; // nama string langsung

  LoginEmployeeModel({
    required this.id,
    this.employeeCode,
    this.nik,
    required this.fullName,
    this.nickname,
    this.gender,
    this.photoUrl,
    required this.wajahTerdaftar,
    this.phone,
    this.joinDate,
    this.employmentType,
    this.department,
    this.position,
    this.company,
  });

  factory LoginEmployeeModel.fromJson(Map<String, dynamic> json) {
    return LoginEmployeeModel(
      id: json['id'],
      employeeCode: json['employee_code'],
      nik: json['nik'],
      fullName: json['full_name'] ?? '',
      nickname: json['nickname'],
      gender: json['gender'],
      photoUrl: json['photo_url'],
      wajahTerdaftar:
          json['wajah_terdaftar'] == true || json['wajah_terdaftar'] == 1,
      phone: json['phone'],
      joinDate: json['join_date'],
      employmentType: json['employment_type'],
      // department, position, company dikirim sebagai nama string langsung
      department: json['department'],
      position: json['position'],
      company: json['company'],
    );
  }

  /// Nama tampilan: nickname jika ada, fallback ke fullName
  String get displayName => nickname ?? fullName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_code': employeeCode,
    'nik': nik,
    'full_name': fullName,
    'nickname': nickname,
    'gender': gender,
    'photo_url': photoUrl,
    'wajah_terdaftar': wajahTerdaftar,
    'phone': phone,
    'join_date': joinDate,
    'employment_type': employmentType,
    'department': department,
    'position': position,
    'company': company,
  };
}
