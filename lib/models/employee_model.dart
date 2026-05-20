class EmployeeModel {
  final int id;
  final int? userId;
  final int? companyId;
  final int? departmentId;
  final int? positionId;
  final int? jobLevelId;
  final int? jobGradeId;
  final int? employeeStatusId;

  final String? employeeCode;
  final String? nik;
  final String? ktpNumber;
  final String fullName;
  final String? nickname;
  final String? gender;
  final String? placeOfBirth;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final String? religion;
  final String? bloodType;
  final String? photoUrl;
  final String? fotoWajahPath;
  final bool wajahTerdaftar;
  final String? phone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? employmentType;
  final DateTime? joinDate;
  final DateTime? contractEndDate;
  final DateTime? resignDate;
  final String? npwp;
  final String? bpjsKesehatan;
  final String? bpjsKetenagakerjaan;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? lastEducation;
  final String? lastEducationMajor;
  final String? lastEducationInstitution;

  // Relations
  final String? departmentName;
  final String? positionName;
  final String? companyName;
  final String? statusName;
  final String? jobLevelName;
  final String? jobGradeName;
  final String? jobGradeCode;

  // Akun login
  final String? userEmail;
  final String? userRole;

  EmployeeModel({
    required this.id,
    this.userId,
    this.companyId,
    this.departmentId,
    this.positionId,
    this.jobLevelId,
    this.jobGradeId,
    this.employeeStatusId,
    this.employeeCode,
    this.nik,
    this.ktpNumber,
    required this.fullName,
    this.nickname,
    this.gender,
    this.placeOfBirth,
    this.dateOfBirth,
    this.maritalStatus,
    this.religion,
    this.bloodType,
    this.photoUrl,
    this.fotoWajahPath,
    this.wajahTerdaftar = false,
    this.phone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    this.employmentType,
    this.joinDate,
    this.contractEndDate,
    this.resignDate,
    this.npwp,
    this.bpjsKesehatan,
    this.bpjsKetenagakerjaan,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.lastEducation,
    this.lastEducationMajor,
    this.lastEducationInstitution,
    this.departmentName,
    this.positionName,
    this.companyName,
    this.statusName,
    this.jobLevelName,
    this.jobGradeName,
    this.jobGradeCode,
    this.userEmail,
    this.userRole,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      userId: json['user_id'],
      companyId: json['company_id'],
      departmentId: json['department_id'],
      positionId: json['position_id'],
      jobLevelId: json['job_level_id'],
      jobGradeId: json['job_grade_id'],
      employeeStatusId: json['employee_status_id'],
      employeeCode: json['employee_code'],
      nik: json['nik'],
      ktpNumber: json['ktp_number'],
      fullName: json['full_name'] ?? '',
      nickname: json['nickname'],
      gender: json['gender'],
      placeOfBirth: json['place_of_birth'],
      dateOfBirth: _parseDate(json['date_of_birth']),
      maritalStatus: json['marital_status'],
      religion: json['religion'],
      bloodType: json['blood_type'],
      photoUrl: json['photo_url'],
      fotoWajahPath: json['foto_wajah_path'],
      wajahTerdaftar:
          json['wajah_terdaftar'] == true || json['wajah_terdaftar'] == 1,
      phone: json['phone'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      emergencyContactRelation: json['emergency_contact_relation'],
      address: json['address'],
      city: json['city'],
      province: json['province'],
      postalCode: json['postal_code'],
      employmentType: json['employment_type'],
      joinDate: _parseDate(json['join_date']),
      contractEndDate: _parseDate(json['contract_end_date']),
      resignDate: _parseDate(json['resign_date']),
      npwp: json['npwp'],
      bpjsKesehatan: json['bpjs_kesehatan'],
      bpjsKetenagakerjaan: json['bpjs_ketenagakerjaan'],
      bankName: json['bank_name'],
      bankAccountNumber: json['bank_account_number'],
      bankAccountName: json['bank_account_name'],
      lastEducation: json['last_education'],
      lastEducationMajor: json['last_education_major'],
      lastEducationInstitution: json['last_education_institution'],
      departmentName: json['department']?['name'],
      positionName: json['position']?['name'],
      companyName: json['company']?['name'],
      statusName: json['status']?['label'] ?? json['status']?['name'],
      jobLevelName: json['job_level']?['name'],
      jobGradeName: json['job_grade']?['name'],
      jobGradeCode: json['job_grade']?['code'],
      userEmail: json['user']?['email'],
      userRole: json['user']?['role'],
    );
  }

  String get displayName => nickname ?? fullName;
  bool get hasAccount => userId != null;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
