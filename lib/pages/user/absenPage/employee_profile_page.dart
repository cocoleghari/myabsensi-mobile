import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/app_config.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:myabsensi_mobile/pages/user/absenPage/modals/search_employee_modal.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage>
    with SingleTickerProviderStateMixin {
  late UserModel _user;
  Map<String, dynamic> _detail = {};
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Palet warna — sama persis dgn RekamAktivitasDetailPage ────────────────
  static const Color _gradientStart = Color(0xFF1565C0);
  static const Color _gradientMid = Color(0xFF1E88E5);
  static const Color _gradientEnd = Color(0xFF42A5F5);
  static const Color _bg = Color(0xFFF2F4F7);

  // Helper turunan
  static const Color _chipBg = Color(0xFFE3EDF8); // latar chip/badge
  static const Color _cardBorder = Color(0xFFDAE8F7);
  static const Color _textPri = Color(0xFF0D1B2A);
  static const Color _textSec = Color(0xFF6B85A0);

  // Warna ikon per field
  static const Color _iconGreen = Color(0xFF16A34A);
  static const Color _iconPurple = Color(0xFF7C3AED);
  static const Color _iconPink = Color(0xFFDB2777);
  static const Color _iconAmber = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    _user = Get.arguments as UserModel;

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

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final auth = Get.find<AuthController>();
      final res = await http.get(
        Uri.parse('$baseUrl/user/karyawan/${_user.id}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${auth.token.value}',
        },
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() => _detail = json['data'] ?? {});
        _animCtrl.forward();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  // ─────────────────────────────────────────────────────────────────────────
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

  // ── Body utama ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    final photoUrl = (_detail['photo_url'] ?? _user.photoUrl ?? '').toString();

    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header biru — avatar + nama + jabatan + stat chips ─────────────
          SliverToBoxAdapter(child: _buildHeader(photoUrl)),

          // ── Jarak antara header dan cards ─────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Informasi Pribadi ─────────────────────────────────────────────
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

          // ── Info Pekerjaan ────────────────────────────────────────────────
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

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── Header biru ───────────────────────────────────────────────────────────
  Widget _buildHeader(String photoUrl) {
    final nik = (_user.nik ?? '').isNotEmpty ? _user.nik! : '—';
    final kantor = (_user.kantor ?? '').isNotEmpty ? _user.kantor! : '—';
    final tglMasuk = (_detail['tgl_masuk'] ?? _user.tglMasuk ?? '').toString();

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
              // Dekorasi circle — sama dengan RekamAktivitasDetailPage
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
                  // ── AppBar row ───────────────────────────────────────────
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

                  // ── Avatar ──────────────────────────────────────────────
                  GestureDetector(
                    onTap: photoUrl.isNotEmpty
                        ? () => _openPhoto(photoUrl)
                        : null,
                    child: Hero(
                      tag: 'emp_photo_${_user.id}',
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

                  // ── Nama ────────────────────────────────────────────────
                  Text(
                    _user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if ((_user.jabatan ?? '').isNotEmpty) ...[
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
                        _user.jabatan!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Garis separator tipis ────────────────────────────────
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  const SizedBox(height: 20),

                  // ── Stat chips — di DALAM header, tidak overlap ──────────
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
                              label: 'Kantor',
                              value: kantor,
                            ),
                          ),
                          _chipDivider(),
                          _headerChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Tgl Masuk',
                            value: tglMasuk.isNotEmpty ? tglMasuk : '—',
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

  // ── Card wrapper ──────────────────────────────────────────────────────────
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
          // Card header — latar _chipBg seperti badge tipe aktivitas
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: _chipBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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

  // ── Personal rows ─────────────────────────────────────────────────────────
  Widget _buildPersonalRows() {
    final jk = (_detail['jk'] ?? '').toString();
    final tglLahir = (_detail['tgl_lahir'] ?? '').toString();
    final alamat = (_detail['alamat'] ?? '').toString();
    final telp = (_detail['nomor_telp'] ?? _user.nomorTelp ?? '').toString();

    final rows = <_RowData>[
      if (_user.email.isNotEmpty)
        _RowData(
          Icons.alternate_email_rounded,
          'Email',
          _user.email,
          _gradientMid,
        ),
      if (telp.isNotEmpty)
        _RowData(Icons.phone_rounded, 'No. Telepon', telp, _iconGreen),
      if (jk.isNotEmpty)
        _RowData(
          jk == 'L' ? Icons.male_rounded : Icons.female_rounded,
          'Jenis Kelamin',
          jk == 'L' ? 'Laki-laki' : 'Perempuan',
          jk == 'L' ? _gradientMid : _iconPink,
        ),
      if (tglLahir.isNotEmpty)
        _RowData(Icons.cake_rounded, 'Tanggal Lahir', tglLahir, _iconPurple),
      if (alamat.isNotEmpty)
        _RowData(Icons.location_on_rounded, 'Alamat', alamat, _iconAmber),
    ];

    if (rows.isEmpty) return _emptyState('Tidak ada data pribadi');
    return _buildRows(rows);
  }

  // ── Work rows ─────────────────────────────────────────────────────────────
  Widget _buildWorkRows() {
    final jabatan = (_user.jabatan ?? '').isNotEmpty ? _user.jabatan! : '';
    final kantor = (_user.kantor ?? '').isNotEmpty ? _user.kantor! : '';
    final tglMasuk = (_detail['tgl_masuk'] ?? _user.tglMasuk ?? '').toString();
    final namaStempel = (_detail['nama_stempel'] ?? '').toString();

    final rows = <_RowData>[
      if (jabatan.isNotEmpty)
        _RowData(
          Icons.work_outline_rounded,
          'Jabatan',
          jabatan,
          _gradientStart,
        ),
      if (kantor.isNotEmpty)
        _RowData(Icons.apartment_rounded, 'Kantor', kantor, _gradientMid),
      if (tglMasuk.isNotEmpty)
        _RowData(
          Icons.event_available_outlined,
          'Tanggal Masuk',
          tglMasuk,
          _iconGreen,
        ),
      if (namaStempel.isNotEmpty)
        _RowData(
          Icons.verified_outlined,
          'Nama Stempel',
          namaStempel,
          _iconPurple,
        ),
    ];

    if (rows.isEmpty) return _emptyState('Tidak ada data pekerjaan');
    return _buildRows(rows);
  }

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
                  // Icon container — warna latar _chipBg sama dengan header card
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

  // ── Avatar ────────────────────────────────────────────────────────────────
  Widget _buildAvatar(String photoUrl, double size) {
    final initial = _user.name.isNotEmpty ? _user.name[0].toUpperCase() : '?';
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
    // Variasi dari palet gradien yang sama
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
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _RowData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _RowData(this.icon, this.label, this.value, this.color);
}
