import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/employee_controller.dart';
import '../../../models/employee_model.dart';

class EmployeeFormPage extends StatefulWidget {
  final EmployeeModel? employee; // null = mode tambah

  const EmployeeFormPage({super.key, this.employee});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage>
    with SingleTickerProviderStateMixin {
  late final EmployeeController _ctrl;
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();

  // ── Text controllers ──────────────────────────────
  final _employeeCode = TextEditingController();
  final _nik = TextEditingController();
  final _ktpNumber = TextEditingController();
  final _fullName = TextEditingController();
  final _nickname = TextEditingController();
  final _placeOfBirth = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _postalCode = TextEditingController();
  final _npwp = TextEditingController();
  final _bpjsKes = TextEditingController();
  final _bpjsTK = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccNum = TextEditingController();
  final _bankAccName = TextEditingController();
  final _lastEduMajor = TextEditingController();
  final _lastEduInst = TextEditingController();
  final _emergName = TextEditingController();
  final _emergPhone = TextEditingController();
  final _emergRel = TextEditingController();

  // ── Dropdown / date values ────────────────────────
  int? _companyId,
      _departmentId,
      _positionId,
      _jobLevelId,
      _jobGradeId,
      _statusId;

  /// Sesuai enum migration: 'male' | 'female'
  String? _gender;

  /// Sesuai enum migration: 'single' | 'married' | 'divorced' | 'widowed'
  String? _maritalStatus;

  String? _religion;
  String? _bloodType;

  /// Sesuai enum migration: 'permanent' | 'contract' | 'intern' | 'freelance'
  String? _employmentType;

  /// Sesuai enum migration: 'sd'|'smp'|'sma'|'d1'|'d2'|'d3'|'d4'|'s1'|'s2'|'s3'
  String? _lastEducation;

  DateTime? _dateOfBirth, _joinDate, _contractEnd, _resignDate;

  // ── Create account ────────────────────────────────
  bool _createAccount = false;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  String? _role = 'employee';

  // ── State ─────────────────────────────────────────
  bool _optionsLoaded = false;

  bool get isEdit => widget.employee != null;

  // ── Enum maps ─────────────────────────────────────

  static const _genderOptions = {'male': 'Laki-laki', 'female': 'Perempuan'};

  static const _maritalOptions = {
    'single': 'Belum Menikah',
    'married': 'Menikah',
    'divorced': 'Cerai',
    'widowed': 'Janda/Duda',
  };

  static const _religionOptions = {
    'Islam': 'Islam',
    'Kristen': 'Kristen',
    'Katolik': 'Katolik',
    'Hindu': 'Hindu',
    'Budha': 'Budha',
    'Konghucu': 'Konghucu',
  };

  static const _bloodTypeOptions = {'A': 'A', 'B': 'B', 'AB': 'AB', 'O': 'O'};

  /// employment_type — HARUS sesuai enum migration (tidak ada 'outsource')
  static const _employmentTypeOptions = {
    'permanent': 'Tetap',
    'contract': 'Kontrak',
    'intern': 'Magang',
    'freelance': 'Freelance',
  };

  /// last_education — sesuai enum migration
  static const _educationOptions = {
    'sd': 'SD',
    'smp': 'SMP',
    'sma': 'SMA / SMK',
    'd1': 'D1',
    'd2': 'D2',
    'd3': 'D3',
    'd4': 'D4',
    's1': 'S1',
    's2': 'S2',
    's3': 'S3',
  };

  static const _roleOptions = {
    'employee': 'Karyawan',
    'admin': 'Admin',
    'hrd': 'HRD',
    'manager': 'Manager',
  };

  // ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<EmployeeController>();
    _tabs = TabController(length: 4, vsync: this);
    _loadOptions();
    if (isEdit) _fillForm(widget.employee!);
  }

  Future<void> _loadOptions() async {
    await _ctrl.fetchOptions();
    if (mounted) setState(() => _optionsLoaded = true);
  }

  void _fillForm(EmployeeModel e) {
    _employeeCode.text = e.employeeCode ?? '';
    _nik.text = e.nik ?? '';
    _fullName.text = e.fullName;
    _nickname.text = e.nickname ?? '';
    _placeOfBirth.text = e.placeOfBirth ?? '';
    _phone.text = e.phone ?? '';
    _companyId = e.companyId;
    _departmentId = e.departmentId;
    _positionId = e.positionId;
    _jobLevelId = e.jobLevelId;
    _jobGradeId = e.jobGradeId;
    _statusId = e.employeeStatusId;
    _gender = e.gender;
    _employmentType = e.employmentType;
    _lastEducation = e.lastEducation;
    _dateOfBirth = e.dateOfBirth;
    _joinDate = e.joinDate;
    _contractEnd = e.contractEndDate;
    _resignDate = e.resignDate;
    _maritalStatus = e.maritalStatus;
    _religion = e.religion;
    _bloodType = e.bloodType;
    _address.text = e.address ?? '';
    _city.text = e.city ?? '';
    _province.text = e.province ?? '';
    _postalCode.text = e.postalCode ?? '';
    _npwp.text = e.npwp ?? '';
    _bpjsKes.text = e.bpjsKesehatan ?? '';
    _bpjsTK.text = e.bpjsKetenagakerjaan ?? '';
    _bankName.text = e.bankName ?? '';
    _bankAccNum.text = e.bankAccountNumber ?? '';
    _bankAccName.text = e.bankAccountName ?? '';
    _lastEduMajor.text = e.lastEducationMajor ?? '';
    _lastEduInst.text = e.lastEducationInstitution ?? '';
    _emergName.text = e.emergencyContactName ?? '';
    _emergPhone.text = e.emergencyContactPhone ?? '';
    _emergRel.text = e.emergencyContactRelation ?? '';
    _ktpNumber.text = e.ktpNumber ?? '';
    // Jika karyawan sudah punya akun, aktifkan switch & isi field
    if (e.hasAccount) {
      _createAccount = true;
      _email.text = e.userEmail ?? '';
      _role = e.userRole ?? 'employee';
      // Password dikosongkan — hanya diisi jika ingin menggantinya
    }
  }

  @override
  void dispose() {
    for (final c in [
      _employeeCode,
      _nik,
      _ktpNumber,
      _fullName,
      _nickname,
      _placeOfBirth,
      _phone,
      _address,
      _city,
      _province,
      _postalCode,
      _npwp,
      _bpjsKes,
      _bpjsTK,
      _bankName,
      _bankAccNum,
      _bankAccName,
      _lastEduMajor,
      _lastEduInst,
      _emergName,
      _emergPhone,
      _emergRel,
      _email,
      _password,
    ]) {
      c.dispose();
    }
    _tabs.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Periksa Form',
        'Isi semua field yang wajib diisi',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // company_id NOT NULL di DB — wajib dipilih
    if (_companyId == null) {
      _tabs.animateTo(1);
      Get.snackbar(
        'Periksa Form',
        'Perusahaan wajib dipilih',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final payload = <String, dynamic>{
      'employee_code': _employeeCode.text.trim().nullIfEmpty,
      // nik wajib — validator sudah handle
      'nik': _nik.text.trim(),
      'ktp_number': _ktpNumber.text.trim().nullIfEmpty,
      'full_name': _fullName.text.trim(),
      'nickname': _nickname.text.trim().nullIfEmpty,
      // gender wajib — dicek di atas
      'gender': _gender,
      'place_of_birth': _placeOfBirth.text.trim().nullIfEmpty,
      'date_of_birth': _dateOfBirth?.toIso8601String().substring(0, 10),
      'marital_status': _maritalStatus,
      'religion': _religion,
      'blood_type': _bloodType,
      // company_id wajib — dicek di atas
      'company_id': _companyId,
      'department_id': _departmentId,
      'position_id': _positionId,
      'job_level_id': _jobLevelId,
      'job_grade_id': _jobGradeId,
      'employee_status_id': _statusId,
      // employment_type enum: permanent|contract|intern|freelance
      'employment_type': _employmentType,
      'join_date': _joinDate?.toIso8601String().substring(0, 10),
      'contract_end_date': _contractEnd?.toIso8601String().substring(0, 10),
      'resign_date': _resignDate?.toIso8601String().substring(0, 10),
      'phone': _phone.text.trim().nullIfEmpty,
      'address': _address.text.trim().nullIfEmpty,
      'city': _city.text.trim().nullIfEmpty,
      'province': _province.text.trim().nullIfEmpty,
      'postal_code': _postalCode.text.trim().nullIfEmpty,
      'npwp': _npwp.text.trim().nullIfEmpty,
      'bpjs_kesehatan': _bpjsKes.text.trim().nullIfEmpty,
      'bpjs_ketenagakerjaan': _bpjsTK.text.trim().nullIfEmpty,
      'bank_name': _bankName.text.trim().nullIfEmpty,
      'bank_account_number': _bankAccNum.text.trim().nullIfEmpty,
      'bank_account_name': _bankAccName.text.trim().nullIfEmpty,
      // last_education enum: sd|smp|sma|d1|d2|d3|d4|s1|s2|s3
      'last_education': _lastEducation,
      'last_education_major': _lastEduMajor.text.trim().nullIfEmpty,
      'last_education_institution': _lastEduInst.text.trim().nullIfEmpty,
      'emergency_contact_name': _emergName.text.trim().nullIfEmpty,
      'emergency_contact_phone': _emergPhone.text.trim().nullIfEmpty,
      'emergency_contact_relation': _emergRel.text.trim().nullIfEmpty,
      if (_createAccount) ...{
        'create_account': true,
        'email': _email.text.trim(),
        'password': _password.text,
        'role': _role ?? 'employee',
      },
    }..removeWhere((_, v) => v == null);

    final ok = isEdit
        ? await _ctrl.updateEmployee(widget.employee!.id, payload)
        : await _ctrl.createEmployee(payload);

    if (ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context, rootNavigator: true).pop(true);
      });
    }
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Karyawan' : 'Tambah Karyawan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Identitas'),
            Tab(text: 'Kepegawaian'),
            Tab(text: 'Kontak'),
            Tab(text: 'Lainnya'),
          ],
        ),
        actions: [
          Obx(
            () => _ctrl.isSubmitting.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _submit,
                    child: const Text(
                      'Simpan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildIdentitasTab(),
            _buildKepegawaianTab(),
            _buildKontakTab(),
            _buildLainnyaTab(),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: IDENTITAS ──────────────────────────────

  Widget _buildIdentitasTab() {
    return _scrolled([
      _field('Nama Lengkap *', _fullName, required: true),
      _field(
        'Nama Panggilan *',
        _nickname,
        required: true,
        hint: 'Harus unik antar karyawan',
      ),
      // nik unique & NOT NULL di DB
      _field(
        'NIK *',
        _nik,
        required: true,
        hint: 'Nomor Induk Karyawan, harus unik',
      ),
      _field('No. KTP', _ktpNumber),
      _field('Kode Karyawan', _employeeCode),
      _dropdown(
        'Jenis Kelamin',
        _gender,
        _genderOptions,
        (v) => setState(() => _gender = v),
      ),
      _field('Tempat Lahir', _placeOfBirth),
      _datePicker(
        'Tanggal Lahir',
        _dateOfBirth,
        (d) => setState(() => _dateOfBirth = d),
      ),
      _dropdown(
        'Status Pernikahan',
        _maritalStatus,
        _maritalOptions,
        (v) => setState(() => _maritalStatus = v),
      ),
      _dropdown(
        'Agama',
        _religion,
        _religionOptions,
        (v) => setState(() => _religion = v),
      ),
      _dropdown(
        'Golongan Darah',
        _bloodType,
        _bloodTypeOptions,
        (v) => setState(() => _bloodType = v),
      ),
      const Divider(height: 32),
      SwitchListTile(
        title: const Text('Buatkan akun login'),
        subtitle: const Text('Karyawan dapat login ke aplikasi'),
        value: _createAccount,
        onChanged: (v) => setState(() => _createAccount = v),
        activeColor: Colors.blue,
      ),
      if (_createAccount) ...[
        const SizedBox(height: 8),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => _createAccount && (v == null || v.isEmpty)
              ? 'Email wajib diisi'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _password,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: isEdit
                ? 'Password Baru (kosongkan jika tidak diganti)'
                : 'Password *',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) {
            if (!_createAccount) return null;
            // Saat tambah baru: password wajib
            if (!isEdit && (v == null || v.length < 6)) {
              return 'Password minimal 6 karakter';
            }
            // Saat edit: password boleh kosong, tapi jika diisi harus >= 6
            if (isEdit && v != null && v.isNotEmpty && v.length < 6) {
              return 'Password minimal 6 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _dropdown(
          'Role Akun',
          _role,
          _roleOptions,
          (v) => setState(() => _role = v),
        ),
      ],
    ]);
  }

  // ── TAB 2: KEPEGAWAIAN ────────────────────────────

  Widget _buildKepegawaianTab() {
    if (!_optionsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return _scrolled([
      // Perusahaan tetap pakai DropdownButtonFormField (biasanya sedikit)
      DropdownButtonFormField<int>(
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Perusahaan *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        value: _companyId,
        validator: (v) => v == null ? 'Perusahaan wajib dipilih' : null,
        items: [
          const DropdownMenuItem(value: null, child: Text('Pilih Perusahaan')),
          ..._ctrl.companies.map(
            (e) => DropdownMenuItem(
              value: e['id'] as int,
              child: Text(
                e['name'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (v) => setState(() => _companyId = v),
      ),

      // ── Departemen — searchable ──────────────────────────────
      _SearchableDropdown(
        label: 'Departemen',
        value: _departmentId,
        items: _ctrl.departments,
        onChanged: (v) => setState(() => _departmentId = v),
      ),

      // ── Jabatan / Posisi — searchable ────────────────────────
      _SearchableDropdown(
        label: 'Jabatan / Posisi',
        value: _positionId,
        items: _ctrl.positions,
        onChanged: (v) => setState(() => _positionId = v),
      ),

      // ── Job Level — searchable ───────────────────────────────
      _SearchableDropdown(
        label: 'Job Level',
        value: _jobLevelId,
        items: _ctrl.jobLevels,
        onChanged: (v) => setState(() => _jobLevelId = v),
      ),

      // ── Job Grade — searchable, tampilkan code sebagai subtitle
      _SearchableDropdown(
        label: 'Job Grade',
        value: _jobGradeId,
        items: _ctrl.jobGrades,
        displayText: (e) {
          final name = e['name']?.toString() ?? '';
          final code = e['code']?.toString() ?? '';
          return code.isNotEmpty ? '$name ($code)' : name;
        },
        subtitleText: (e) => e['code']?.toString() ?? '',
        onChanged: (v) => setState(() => _jobGradeId = v),
      ),

      _dropdownFromList(
        'Status Karyawan',
        _statusId,
        _ctrl.statuses,
        (v) => setState(() => _statusId = v),
      ),
      _dropdown(
        'Tipe Kepegawaian',
        _employmentType,
        _employmentTypeOptions,
        (v) => setState(() => _employmentType = v),
      ),
      _datePicker(
        'Tanggal Bergabung',
        _joinDate,
        (d) => setState(() => _joinDate = d),
      ),
      _datePicker(
        'Akhir Kontrak',
        _contractEnd,
        (d) => setState(() => _contractEnd = d),
      ),
      _datePicker(
        'Tanggal Resign',
        _resignDate,
        (d) => setState(() => _resignDate = d),
      ),
    ]);
  }

  // ── TAB 3: KONTAK ─────────────────────────────────

  Widget _buildKontakTab() {
    return _scrolled([
      _field('No. Telepon', _phone, inputType: TextInputType.phone),
      _field('Alamat', _address, maxLines: 3),
      _field('Kota', _city),
      _field('Provinsi', _province),
      _field('Kode Pos', _postalCode, inputType: TextInputType.number),
      const Divider(height: 32),
      const Text(
        'Kontak Darurat',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      const SizedBox(height: 8),
      _field('Nama Kontak Darurat', _emergName),
      _field(
        'Telepon Kontak Darurat',
        _emergPhone,
        inputType: TextInputType.phone,
      ),
      _field('Hubungan', _emergRel),
    ]);
  }

  // ── TAB 4: LAINNYA ────────────────────────────────

  Widget _buildLainnyaTab() {
    return _scrolled([
      _field('NPWP', _npwp),
      _field('BPJS Kesehatan', _bpjsKes),
      _field('BPJS Ketenagakerjaan', _bpjsTK),
      const Divider(height: 32),
      const Text(
        'Rekening Bank',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      const SizedBox(height: 8),
      _field('Nama Bank', _bankName),
      _field('No. Rekening', _bankAccNum, inputType: TextInputType.number),
      _field('Nama Pemilik Rekening', _bankAccName),
      const Divider(height: 32),
      const Text(
        'Pendidikan Terakhir',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      const SizedBox(height: 8),
      // last_education adalah enum — pakai dropdown, bukan text field
      _dropdown(
        'Jenjang Pendidikan',
        _lastEducation,
        _educationOptions,
        (v) => setState(() => _lastEducation = v),
      ),
      _field('Jurusan', _lastEduMajor),
      _field('Nama Institusi', _lastEduInst),
    ]);
  }

  // ── HELPERS ───────────────────────────────────────

  Widget _scrolled(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children.expand((w) => [w, const SizedBox(height: 12)]),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType? inputType,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
          : null,
    );
  }

  /// Dropdown biasa (nullable, tidak ada validator).
  Widget _dropdown(
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      value: value,
      items: [
        DropdownMenuItem(value: null, child: Text('Pilih $label')),
        ...options.entries.map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  /// Dropdown dengan validator (untuk field NOT NULL di DB).
  Widget _dropdownRequired(
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      value: value,
      validator: required
          ? (v) => v == null ? '$label wajib dipilih' : null
          : null,
      items: [
        DropdownMenuItem(value: null, child: Text('Pilih $label')),
        ...options.entries.map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _dropdownFromList(
    String label,
    int? value,
    List<Map<String, dynamic>> items,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      value: value,
      items: [
        DropdownMenuItem(value: null, child: Text('Pilih $label')),
        ...items.map(
          (e) => DropdownMenuItem(
            value: e['id'] as int,
            child: Text(e['name'].toString(), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _dropdownFromListWithSub(
    String label,
    int? value,
    List<Map<String, dynamic>> items,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      value: value,
      items: [
        DropdownMenuItem(value: null, child: Text('Pilih $label')),
        ...items.map((e) {
          final name = e['name']?.toString() ?? '';
          final code = e['code']?.toString() ?? '';
          final label = code.isNotEmpty ? '$name ($code)' : name;
          return DropdownMenuItem(
            value: e['id'] as int,
            child: Text(label, overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }

  Widget _datePicker(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/'
                    '${value.month.toString().padLeft(2, '0')}/'
                    '${value.year}'
              : 'Pilih tanggal',
          style: TextStyle(color: value != null ? null : Colors.grey),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCHABLE DROPDOWN DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _SearchableDropdown extends StatefulWidget {
  final String label;
  final int? value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<int?> onChanged;
  final String Function(Map<String, dynamic>)? displayText;
  final String Function(Map<String, dynamic>)? subtitleText;

  const _SearchableDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.displayText,
    this.subtitleText,
  });

  @override
  State<_SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<_SearchableDropdown> {
  String _getLabel(Map<String, dynamic> item) {
    if (widget.displayText != null) return widget.displayText!(item);
    return item['name']?.toString() ?? '';
  }

  String? _getSelectedLabel() {
    if (widget.value == null) return null;
    try {
      final found = widget.items.firstWhere(
        (e) => e['id'] == widget.value,
        orElse: () => {},
      );
      return found.isEmpty ? null : _getLabel(found);
    } catch (_) {
      return null;
    }
  }

  // Di _SearchableDropdownState._openDialog()
  // Di _SearchableDropdownState
  void _openDialog() async {
    final result = await showDialog<int?>(
      context: context,
      useSafeArea: false, // ← penting!
      builder: (ctx) => _KeyboardAwareDialog(
        // ← wrapper baru
        child: _SearchableDropdownDialog(
          label: widget.label,
          value: widget.value,
          items: widget.items,
          displayText: widget.displayText ?? (e) => e['name']?.toString() ?? '',
          subtitleText: widget.subtitleText,
        ),
      ),
    );
    if (result == -1) {
      widget.onChanged(null);
    } else if (result != null) {
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _getSelectedLabel();
    final hasValue = selectedLabel != null;

    return InkWell(
      onTap: _openDialog,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasValue)
                GestureDetector(
                  onTap: () => widget.onChanged(null),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              const SizedBox(width: 4),
            ],
          ),
        ),
        child: Text(
          selectedLabel ?? 'Pilih ${widget.label}',
          style: TextStyle(
            fontSize: 14,
            color: hasValue ? Colors.black87 : Colors.grey.shade500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SearchableDropdownDialog extends StatefulWidget {
  final String label;
  final int? value;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) displayText;
  final String Function(Map<String, dynamic>)? subtitleText;

  const _SearchableDropdownDialog({
    required this.label,
    required this.value,
    required this.items,
    required this.displayText,
    this.subtitleText,
  });

  @override
  State<_SearchableDropdownDialog> createState() =>
      _SearchableDropdownDialogState();
}

class _SearchableDropdownDialogState extends State<_SearchableDropdownDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((e) {
      final main = widget.displayText(e).toLowerCase();
      final sub = widget.subtitleText?.call(e).toLowerCase() ?? '';
      return main.contains(q) || sub.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          color: Colors.blue,
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pilih ${widget.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // ── Search bar ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari ${widget.label.toLowerCase()}...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: Colors.grey.shade400,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              isDense: true,
            ),
          ),
        ),

        // ── Info jumlah ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} hasil',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const Spacer(),
              if (_selected != null)
                GestureDetector(
                  onTap: () => Navigator.pop(context, -1),
                  child: Text(
                    'Kosongkan pilihan',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── List — pakai Flexible agar tidak overflow ────
        Flexible(
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tidak ada hasil untuk "$_query"',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final id = item['id'] as int;
                    final isSelected = id == _selected;
                    final subtitle = widget.subtitleText?.call(item);

                    return InkWell(
                      onTap: () => Navigator.pop(context, id),
                      child: Container(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.06)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.displayText(item),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (subtitle != null &&
                                      subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Wrapper yang memastikan dialog naik saat keyboard muncul
class _KeyboardAwareDialog extends StatelessWidget {
  final Widget child;
  const _KeyboardAwareDialog({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + 40,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
