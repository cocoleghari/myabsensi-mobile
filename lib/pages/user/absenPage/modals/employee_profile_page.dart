import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/models/employee_model.dart';
import 'package:http/http.dart' as http;
import 'package:myabsensi_mobile/pages/user/absenPage/modals/search_employee_modal.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage>
    with SingleTickerProviderStateMixin {
  late EmployeeModel _emp;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── Color palette ────────────────────────────────────────────────────────
  static const Color _gradientStart = Color(0xFF1565C0);
  static const Color _gradientMid = Color(0xFF1E88E5);
  static const Color _gradientEnd = Color(0xFF42A5F5);
  static const Color _bg = Color(0xFFF2F4F7);
  static const Color _chipBg = Color(0xFFE3EDF8);
  static const Color _cardBorder = Color(0xFFDAE8F7);
  static const Color _textPri = Color(0xFF0D1B2A);
  static const Color _textSec = Color(0xFF6B85A0);
  static const Color _iconGreen = Color(0xFF16A34A);
  static const Color _iconPurple = Color(0xFF7C3AED);
  static const Color _iconPink = Color(0xFFDB2777);
  static const Color _iconAmber = Color(0xFFD97706);
  static const Color _iconRed = Color(0xFFDC2626);
  static const Color _iconTeal = Color(0xFF0D9488);
  static const Color _iconOrange = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    _emp = Get.arguments as EmployeeModel;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _fetchDetail();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  // FETCH DETAIL
  // GET /admin/employees/{id}
  // Response: { data: { ...semua field employee + relasi user, company,
  //             department, position, status, pusatLokasis } }
  // =========================================================================

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final auth = Get.find<AuthController>();

      // ← GANTI: pakai endpoint employee, bukan admin
      final res = await http.get(
        Uri.parse('$baseUrl/user/karyawan/${_emp.id}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${auth.token.value}',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        // UserController@show return: { status, data: { ...user + employee nested } }
        final raw = json['data'] ?? json;

        // Flatten karena structure dari UserController@show adalah User + employee nested
        final flattened = _flattenUserDetail(raw);

        if (flattened['id'] != null) {
          setState(() => _emp = EmployeeModel.fromJson(flattened));
        }
        _animCtrl.forward();
      } else {
        // Gagal fetch detail — tetap tampilkan data dari arguments
        _animCtrl.forward();
      }
    } catch (_) {
      _animCtrl.forward();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// UserController@show return:
  /// {
  ///   id, name, email, role, is_active,
  ///   employee: {
  ///     id, full_name, nickname, employee_code, nik, photo_url,
  ///     phone, address, city, province, postal_code,
  ///     gender, place_of_birth, date_of_birth,
  ///     marital_status, religion, blood_type, ktp_number,
  ///     employment_type, join_date, contract_end_date, resign_date,
  ///     npwp, bpjs_kesehatan, bpjs_ketenagakerjaan,
  ///     bank_name, bank_account_number, bank_account_name,
  ///     last_education, last_education_major, last_education_institution,
  ///     emergency_contact_name, emergency_contact_phone, emergency_contact_relation,
  ///     department: { id, name },
  ///     position:   { id, name },
  ///     company:    { id, name },
  ///     status:     { id, label }
  ///   }
  /// }
  Map<String, dynamic> _flattenUserDetail(Map<String, dynamic> json) {
    final employee = json['employee'] as Map<String, dynamic>? ?? {};

    return {
      'id': employee['id'] ?? json['id'],
      'user_id': json['id'],

      // Identitas
      'full_name': employee['full_name'] ?? json['name'] ?? '',
      'nickname': employee['nickname'],
      'employee_code': employee['employee_code'],
      'nik': employee['nik'],
      'ktp_number': employee['ktp_number'],
      'photo_url': employee['photo_url'],
      'gender': employee['gender'],
      'place_of_birth': employee['place_of_birth'],
      'date_of_birth': employee['date_of_birth'],
      'marital_status': employee['marital_status'],
      'religion': employee['religion'],
      'blood_type': employee['blood_type'],

      // Kontak
      'phone': employee['phone'],
      'emergency_contact_name': employee['emergency_contact_name'],
      'emergency_contact_phone': employee['emergency_contact_phone'],
      'emergency_contact_relation': employee['emergency_contact_relation'],

      // Alamat
      'address': employee['address'],
      'city': employee['city'],
      'province': employee['province'],
      'postal_code': employee['postal_code'],

      // Kepegawaian
      'employment_type': employee['employment_type'],
      'join_date': employee['join_date'],
      'contract_end_date': employee['contract_end_date'],
      'resign_date': employee['resign_date'],

      // Finansial & Legal
      'npwp': employee['npwp'],
      'bpjs_kesehatan': employee['bpjs_kesehatan'],
      'bpjs_ketenagakerjaan': employee['bpjs_ketenagakerjaan'],
      'bank_name': employee['bank_name'],
      'bank_account_number': employee['bank_account_number'],
      'bank_account_name': employee['bank_account_name'],

      // Pendidikan
      'last_education': employee['last_education'],
      'last_education_major': employee['last_education_major'],
      'last_education_institution': employee['last_education_institution'],

      // foto wajah
      'foto_wajah_path': employee['foto_wajah_path'],
      'wajah_terdaftar': employee['wajah_terdaftar'],

      // Relations nested
      'department': employee['department'],
      'position': employee['position'],
      'company': employee['company'],
      // EmployeeStatus dari UserController@show pakai 'employeeStatus' (camelCase)
      'status': employee['status'] ?? employee['employeeStatus'],

      // Akun login
      'user': {'email': json['email'], 'role': json['role']},
    };
  }

  void _goBack() {
    Get.back();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Get.context;
      if (ctx != null) SearchEmployeeModal.show(ctx);
    });
  }

  void _openPhoto(String photoUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: _isLoading ? _buildLoader() : _buildBody(),
      ),
    );
  }

  Widget _buildLoader() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_gradientStart, _gradientMid, _gradientEnd],
      ),
    ),
    child: const Center(
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    ),
  );

  Widget _buildBody() {
    final photoUrl = (_emp.photoUrl ?? '').toString();

    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header biru ──
          SliverToBoxAdapter(child: _buildHeader(photoUrl)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Informasi Pribadi ──
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnim,
              child: _buildCard(
                icon: Icons.person_outline_rounded,
                label: 'Informasi Pribadi',
                child: _buildPersonalRows(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Alamat ──
          if (_hasAlamat)
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: _buildCard(
                  icon: Icons.home_outlined,
                  label: 'Alamat',
                  child: _buildAlamatRows(),
                ),
              ),
            ),
          if (_hasAlamat) const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Info Pekerjaan ──
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnim,
              child: _buildCard(
                icon: Icons.work_outline_rounded,
                label: 'Info Pekerjaan',
                child: _buildWorkRows(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Pendidikan ──
          if (_hasPendidikan)
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: _buildCard(
                  icon: Icons.school_outlined,
                  label: 'Pendidikan',
                  child: _buildPendidikanRows(),
                ),
              ),
            ),
          if (_hasPendidikan)
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Kontak Darurat ──
          if (_hasKontakDarurat)
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: _buildCard(
                  icon: Icons.emergency_outlined,
                  label: 'Kontak Darurat',
                  child: _buildKontakDaruratRows(),
                ),
              ),
            ),
          if (_hasKontakDarurat)
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Data Keuangan & Legal ──
          if (_hasKeuangan)
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: _buildCard(
                  icon: Icons.account_balance_outlined,
                  label: 'Keuangan & Legal',
                  child: _buildKeuanganRows(),
                ),
              ),
            ),
          if (_hasKeuangan)
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Akun Login ──
          if (_hasAkun)
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: _buildCard(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Akun Login',
                  child: _buildAkunRows(),
                ),
              ),
            ),
          if (_hasAkun) const SliverToBoxAdapter(child: SizedBox(height: 12)),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // =========================================================================
  // HEADER
  // =========================================================================

  Widget _buildHeader(String photoUrl) {
    final nik = _notEmpty(_emp.nik) ?? '—';
    final company = _notEmpty(_emp.companyName) ?? '—';
    final joinDate = _formatDate(_emp.joinDate) ?? '—';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientMid, _gradientEnd],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Stack(
            children: [
              // Dekorasi circle
              Positioned(
                right: -20,
                top: -10,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: 0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              Column(
                children: [
                  // AppBar row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _goBack,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Profil Karyawan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Avatar
                  GestureDetector(
                    onTap: photoUrl.isNotEmpty
                        ? () => _openPhoto(photoUrl)
                        : null,
                    child: Hero(
                      tag: 'emp_photo_${_emp.id}',
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: _buildAvatar(photoUrl, 82),
                          ),
                          if (photoUrl.isNotEmpty)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _gradientMid,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.zoom_in_rounded,
                                  size: 13,
                                  color: _gradientMid,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Nama
                  Text(
                    _emp.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Badge posisi
                  if (_notEmpty(_emp.positionName) != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _emp.positionName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],

                  // Badge status karyawan
                  if (_notEmpty(_emp.statusName) != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _emp.statusName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 20),

                  // Stat chips: NIK | Perusahaan | Tgl Masuk
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _headerChip(
                            icon: Icons.badge_outlined,
                            label: 'NIK',
                            value: nik,
                          ),
                          _chipDivider(),
                          Expanded(
                            child: _headerChip(
                              icon: Icons.business_outlined,
                              label: 'Perusahaan',
                              value: company,
                            ),
                          ),
                          _chipDivider(),
                          _headerChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Tgl Masuk',
                            value: joinDate,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerChip({
    required IconData icon,
    required String label,
    required String value,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Column(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.85)),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.65),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _chipDivider() => VerticalDivider(
    width: 1,
    thickness: 1,
    color: Colors.white.withOpacity(0.2),
    indent: 10,
    endIndent: 10,
  );

  // =========================================================================
  // CARDS
  // =========================================================================

  Widget _buildCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: _chipBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _gradientMid.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: _gradientStart),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _gradientStart,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: _cardBorder),
          child,
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION: Informasi Pribadi
  // Field: phone, gender (enum: 'male'|'female'), place_of_birth,
  //        date_of_birth, marital_status, religion, blood_type
  // =========================================================================

  Widget _buildPersonalRows() {
    // gender enum dari backend: 'male' | 'female' (bukan 'L'/'P')
    final gender = _emp.gender;
    String genderLabel = '';
    IconData genderIcon = Icons.person;
    Color genderColor = _gradientMid;
    if (gender == 'male') {
      genderLabel = 'Laki-laki';
      genderIcon = Icons.male_rounded;
      genderColor = _gradientMid;
    } else if (gender == 'female') {
      genderLabel = 'Perempuan';
      genderIcon = Icons.female_rounded;
      genderColor = _iconPink;
    }

    // Gabung tempat & tanggal lahir
    final placeOfBirth = _notEmpty(_emp.placeOfBirth) ?? '';
    final dateOfBirthStr = _formatDate(_emp.dateOfBirth) ?? '';
    final birthInfo = [
      if (placeOfBirth.isNotEmpty) placeOfBirth,
      if (dateOfBirthStr.isNotEmpty) dateOfBirthStr,
    ].join(', ');

    // marital_status: label yang lebih ramah
    final maritalRaw = _notEmpty(_emp.maritalStatus) ?? '';
    final maritalLabel = _maritalLabel(maritalRaw);

    final rows = <_RowData>[
      if (_notEmpty(_emp.phone) != null)
        _RowData(Icons.phone_rounded, 'No. Telepon', _emp.phone!, _iconGreen),
      if (genderLabel.isNotEmpty)
        _RowData(genderIcon, 'Jenis Kelamin', genderLabel, genderColor),
      if (birthInfo.isNotEmpty)
        _RowData(
          Icons.cake_rounded,
          'Tempat, Tgl Lahir',
          birthInfo,
          _iconPurple,
        ),
      if (maritalLabel.isNotEmpty)
        _RowData(
          Icons.favorite_border_rounded,
          'Status Pernikahan',
          maritalLabel,
          _iconPink,
        ),
      if (_notEmpty(_emp.religion) != null)
        _RowData(
          Icons.auto_awesome_outlined,
          'Agama',
          _emp.religion!,
          _iconAmber,
        ),
      if (_notEmpty(_emp.bloodType) != null)
        _RowData(
          Icons.bloodtype_outlined,
          'Golongan Darah',
          _emp.bloodType!,
          _iconRed,
        ),
    ];

    if (rows.isEmpty) return _emptyState('Tidak ada data pribadi');
    return _buildRows(rows);
  }

  // =========================================================================
  // SECTION: Alamat
  // Field: address, city, province, postal_code
  // =========================================================================

  bool get _hasAlamat =>
      _notEmpty(_emp.address) != null ||
      _notEmpty(_emp.city) != null ||
      _notEmpty(_emp.province) != null ||
      _notEmpty(_emp.postalCode) != null;

  Widget _buildAlamatRows() {
    // Baris pertama: alamat lengkap (address)
    // Baris kedua: kota, provinsi, kode pos
    final cityProvince = [
      if (_notEmpty(_emp.city) != null) _emp.city!,
      if (_notEmpty(_emp.province) != null) _emp.province!,
    ].join(', ');

    final rows = <_RowData>[
      if (_notEmpty(_emp.address) != null)
        _RowData(Icons.home_outlined, 'Alamat', _emp.address!, _iconTeal),
      if (cityProvince.isNotEmpty)
        _RowData(
          Icons.location_city_outlined,
          'Kota / Provinsi',
          cityProvince,
          _iconTeal,
        ),
      if (_notEmpty(_emp.postalCode) != null)
        _RowData(
          Icons.markunread_mailbox_outlined,
          'Kode Pos',
          _emp.postalCode!,
          _textSec,
        ),
    ];

    if (rows.isEmpty) return _emptyState('Tidak ada data alamat');
    return _buildRows(rows);
  }

  // =========================================================================
  // SECTION: Info Pekerjaan
  // Field: employee_code, position, department, company, employment_type,
  //        join_date, contract_end_date, resign_date, employee_status
  // =========================================================================

  Widget _buildWorkRows() {
    // employment_type enum: 'permanent'|'contract'|'intern'|'freelance'
    final empTypeRaw = _notEmpty(_emp.employmentType) ?? '';
    final empTypeLabel = _employmentTypeLabel(empTypeRaw);

    final rows = <_RowData>[
      if (_notEmpty(_emp.employeeCode) != null)
        _RowData(
          Icons.qr_code_rounded,
          'Kode Karyawan',
          _emp.employeeCode!,
          _gradientStart,
        ),
      if (_notEmpty(_emp.positionName) != null)
        _RowData(
          Icons.work_outline_rounded,
          'Jabatan',
          _emp.positionName!,
          _gradientStart,
        ),
      if (_notEmpty(_emp.departmentName) != null)
        _RowData(
          Icons.group_work_outlined,
          'Departemen',
          _emp.departmentName!,
          _gradientMid,
        ),
      if (_notEmpty(_emp.companyName) != null)
        _RowData(
          Icons.apartment_rounded,
          'Perusahaan',
          _emp.companyName!,
          _gradientMid,
        ),
      if (empTypeLabel.isNotEmpty)
        _RowData(
          Icons.badge_outlined,
          'Tipe Karyawan',
          empTypeLabel,
          _iconAmber,
        ),
      if (_notEmpty(_emp.statusName) != null)
        _RowData(
          Icons.verified_outlined,
          'Status',
          _emp.statusName!,
          _iconGreen,
        ),
      if (_emp.joinDate != null)
        _RowData(
          Icons.event_available_outlined,
          'Tanggal Masuk',
          _formatDate(_emp.joinDate)!,
          _iconGreen,
        ),
      if (_emp.contractEndDate != null)
        _RowData(
          Icons.event_busy_outlined,
          'Akhir Kontrak',
          _formatDate(_emp.contractEndDate)!,
          _iconOrange,
        ),
      if (_emp.resignDate != null)
        _RowData(
          Icons.exit_to_app_outlined,
          'Tanggal Resign',
          _formatDate(_emp.resignDate)!,
          _iconRed,
        ),
    ];

    if (rows.isEmpty) return _emptyState('Tidak ada data pekerjaan');
    return _buildRows(rows);
  }

  // =========================================================================
  // SECTION: Pendidikan
  // Field: last_education, last_education_major, last_education_institution
  // last_education enum: 'sd'|'smp'|'sma'|'d1'|'d2'|'d3'|'d4'|'s1'|'s2'|'s3'
  // =========================================================================

  bool get _hasPendidikan =>
      _notEmpty(_emp.lastEducation) != null ||
      _notEmpty(_emp.lastEducationMajor) != null ||
      _notEmpty(_emp.lastEducationInstitution) != null;

  Widget _buildPendidikanRows() {
    final eduRaw = _notEmpty(_emp.lastEducation) ?? '';
    final eduLabel = _educationLabel(eduRaw);

    final rows = <_RowData>[
      if (eduLabel.isNotEmpty)
        _RowData(
          Icons.school_outlined,
          'Jenjang Pendidikan',
          eduLabel,
          _iconPurple,
        ),
      if (_notEmpty(_emp.lastEducationMajor) != null)
        _RowData(
          Icons.menu_book_outlined,
          'Jurusan',
          _emp.lastEducationMajor!,
          _iconPurple,
        ),
      if (_notEmpty(_emp.lastEducationInstitution) != null)
        _RowData(
          Icons.account_balance_outlined,
          'Institusi',
          _emp.lastEducationInstitution!,
          _iconPurple,
        ),
    ];

    if (rows.isEmpty) return _emptyState('Tidak ada data pendidikan');
    return _buildRows(rows);
  }

  // =========================================================================
  // SECTION: Kontak Darurat
  // Field: emergency_contact_name, emergency_contact_phone,
  //        emergency_contact_relation
  // =========================================================================

  bool get _hasKontakDarurat =>
      _notEmpty(_emp.emergencyContactName) != null ||
      _notEmpty(_emp.emergencyContactPhone) != null;

  Widget _buildKontakDaruratRows() {
    final rows = <_RowData>[
      if (_notEmpty(_emp.emergencyContactName) != null)
        _RowData(
          Icons.person_pin_outlined,
          'Nama',
          _emp.emergencyContactName!,
          _iconRed,
        ),
      if (_notEmpty(_emp.emergencyContactPhone) != null)
        _RowData(
          Icons.phone_in_talk_outlined,
          'No. Telepon',
          _emp.emergencyContactPhone!,
          _iconRed,
        ),
      if (_notEmpty(_emp.emergencyContactRelation) != null)
        _RowData(
          Icons.family_restroom_outlined,
          'Hubungan',
          _emp.emergencyContactRelation!,
          _iconRed,
        ),
    ];

    if (rows.isEmpty) return _emptyState('Tidak ada kontak darurat');
    return _buildRows(rows);
  }

  // =========================================================================
  // SECTION: Keuangan & Legal
  // Field: npwp, bpjs_kesehatan, bpjs_ketenagakerjaan,
  //        bank_name, bank_account_number, bank_account_name
  // =========================================================================

  bool get _hasKeuangan =>
      _notEmpty(_emp.npwp) != null ||
      _notEmpty(_emp.bpjsKesehatan) != null ||
      _notEmpty(_emp.bpjsKetenagakerjaan) != null ||
      _notEmpty(_emp.bankName) != null ||
      _notEmpty(_emp.bankAccountNumber) != null;

  Widget _buildKeuanganRows() {
    final rows = <_RowData>[
      if (_notEmpty(_emp.npwp) != null)
        _RowData(Icons.receipt_long_outlined, 'NPWP', _emp.npwp!, _iconTeal),
      if (_notEmpty(_emp.bpjsKesehatan) != null)
        _RowData(
          Icons.health_and_safety_outlined,
          'BPJS Kesehatan',
          _emp.bpjsKesehatan!,
          _iconGreen,
        ),
      if (_notEmpty(_emp.bpjsKetenagakerjaan) != null)
        _RowData(
          Icons.security_outlined,
          'BPJS Ketenagakerjaan',
          _emp.bpjsKetenagakerjaan!,
          _iconGreen,
        ),
      if (_notEmpty(_emp.bankName) != null)
        _RowData(
          Icons.account_balance_outlined,
          'Bank',
          _emp.bankName!,
          _iconAmber,
        ),
      if (_notEmpty(_emp.bankAccountNumber) != null)
        _RowData(
          Icons.credit_card_outlined,
          'No. Rekening',
          _emp.bankAccountNumber!,
          _iconAmber,
        ),
      if (_notEmpty(_emp.bankAccountName) != null)
        _RowData(
          Icons.person_outline_rounded,
          'Atas Nama',
          _emp.bankAccountName!,
          _iconAmber,
        ),
    ];

    if (rows.isEmpty) return _emptyState('Tidak ada data keuangan');
    return _buildRows(rows);
  }

  // =========================================================================
  // SECTION: Akun Login
  // Field: user_email, user_role (dari relasi user di EmployeeModel)
  // =========================================================================

  bool get _hasAkun =>
      _notEmpty(_emp.userEmail) != null || _notEmpty(_emp.userRole) != null;

  Widget _buildAkunRows() {
    final roleRaw = _notEmpty(_emp.userRole) ?? '';
    final roleLabel = _roleLabel(roleRaw);

    final rows = <_RowData>[
      if (_notEmpty(_emp.userEmail) != null)
        _RowData(Icons.email_outlined, 'Email', _emp.userEmail!, _gradientMid),
      if (roleLabel.isNotEmpty)
        _RowData(Icons.shield_outlined, 'Role', roleLabel, _gradientStart),
      _RowData(
        _emp.hasAccount ? Icons.check_circle_outline : Icons.cancel_outlined,
        'Status Akun',
        _emp.hasAccount ? 'Sudah punya akun' : 'Belum punya akun',
        _emp.hasAccount ? _iconGreen : _textSec,
      ),
    ];

    return _buildRows(rows);
  }

  // =========================================================================
  // ROW BUILDER
  // =========================================================================

  Widget _buildRows(List<_RowData> rows) {
    return Column(
      children: rows.asMap().entries.map((e) {
        final isLast = e.key == rows.length - 1;
        final row = e.value;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _chipBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(row.icon, size: 18, color: row.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textSec,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          row.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPri,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                thickness: 1,
                color: _cardBorder,
                indent: 66,
                endIndent: 16,
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(msg, style: const TextStyle(fontSize: 13, color: _textSec)),
    ),
  );

  // =========================================================================
  // AVATAR
  // =========================================================================

  Widget _buildAvatar(String photoUrl, double size) {
    final initial = _emp.displayName.isNotEmpty
        ? _emp.displayName[0].toUpperCase()
        : '?';
    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialAvatar(initial, size),
        ),
      );
    }
    return _initialAvatar(initial, size);
  }

  Widget _initialAvatar(String initial, double size) {
    const palettes = [
      [Color(0xFF1E88E5), Color(0xFF1565C0)],
      [Color(0xFF1565C0), Color(0xFF0D47A1)],
      [Color(0xFF42A5F5), Color(0xFF1E88E5)],
      [Color(0xFF1E88E5), Color(0xFF0D47A1)],
      [Color(0xFF1565C0), Color(0xFF1E88E5)],
    ];
    final idx = initial.isEmpty ? 0 : initial.codeUnitAt(0) % palettes.length;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palettes[idx],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // UTILS
  // =========================================================================

  /// Kembalikan null jika string kosong atau hanya whitespace.
  String? _notEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  /// Format DateTime ke DD/MM/YYYY.
  String? _formatDate(DateTime? dt) {
    if (dt == null) return null;
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  /// Label gender dari enum backend: 'male' | 'female'.
  // (dipakai langsung di _buildPersonalRows, tidak perlu method terpisah)

  /// Label marital status.
  String _maritalLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'single':
        return 'Belum Menikah';
      case 'married':
        return 'Menikah';
      case 'divorced':
        return 'Bercerai';
      case 'widowed':
        return 'Janda/Duda';
      default:
        return raw;
    }
  }

  /// Label employment type dari enum backend.
  String _employmentTypeLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'permanent':
        return 'Karyawan Tetap';
      case 'contract':
        return 'Kontrak';
      case 'intern':
        return 'Magang';
      case 'freelance':
        return 'Freelance';
      default:
        return raw;
    }
  }

  /// Label pendidikan dari enum backend.
  String _educationLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'sd':
        return 'SD';
      case 'smp':
        return 'SMP';
      case 'sma':
        return 'SMA / SMK';
      case 'd1':
        return 'D1';
      case 'd2':
        return 'D2';
      case 'd3':
        return 'D3';
      case 'd4':
        return 'D4';
      case 's1':
        return 'S1 (Sarjana)';
      case 's2':
        return 'S2 (Magister)';
      case 's3':
        return 'S3 (Doktor)';
      default:
        return raw.toUpperCase();
    }
  }

  /// Label role dari enum backend.
  String _roleLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'hrd':
        return 'HRD';
      case 'manager':
        return 'Manager';
      case 'employee':
        return 'Karyawan';
      default:
        return raw;
    }
  }
}

// ─── Data class ──────────────────────────────────────────────────────────────

class _RowData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _RowData(this.icon, this.label, this.value, this.color);
}
