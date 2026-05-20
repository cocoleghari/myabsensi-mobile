import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:myabsensi_mobile/controllers/auth_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class DetailKehadiranModel {
  // Info karyawan
  final String namaLengkap;
  final String jabatan;
  final String? photoUrl;
  final String initial;

  // Info kehadiran
  final String tanggal; // "11 Mar 2026"
  final String shift; // "Shift 07:30-17:00 (07:30 - 17:00)"
  final List<StatusChip> statusChips;
  final String keterangan;

  // Absen masuk
  final String? jamMasuk;
  final String? fotoMasukUrl;
  final String? wajahMasukLabel; // "Identifikasi Wajah: Lulus (91.16% Cocok)"
  final String? lokasiMasuk; // "-7.3877702,109.6903206"
  final double? confidenceMasuk;

  // Absen pulang
  final String? jamKeluar;
  final String? fotoPulangUrl;
  final String? wajahPulangLabel;
  final String? lokasiPulang;
  final double? confidencePulang;

  // Foto dasar (wajah terdaftar)
  final String? fotoDasarUrl;

  // Flags
  final bool kehadiranBelumLengkap;

  const DetailKehadiranModel({
    required this.namaLengkap,
    required this.jabatan,
    this.photoUrl,
    required this.initial,
    required this.tanggal,
    required this.shift,
    required this.statusChips,
    required this.keterangan,
    this.jamMasuk,
    this.fotoMasukUrl,
    this.wajahMasukLabel,
    this.lokasiMasuk,
    this.confidenceMasuk,
    this.jamKeluar,
    this.fotoPulangUrl,
    this.wajahPulangLabel,
    this.lokasiPulang,
    this.confidencePulang,
    this.fotoDasarUrl,
    required this.kehadiranBelumLengkap,
  });
}

class StatusChip {
  final String label;
  final Color bgColor;
  final Color textColor;

  const StatusChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  /// Parse dari string status API
  factory StatusChip.fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'EAI':
        return StatusChip(
          label: 'EAI',
          bgColor: const Color(0xFFE3F0FF),
          textColor: const Color(0xFF1976D2),
        );
      case 'EAO':
        return StatusChip(
          label: 'EAO',
          bgColor: const Color(0xFFE3F0FF),
          textColor: const Color(0xFF1976D2),
        );
      case 'PRS':
        return StatusChip(
          label: 'PRS',
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF388E3C),
        );
      case 'UNPR':
        return StatusChip(
          label: 'UNPR',
          bgColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFD32F2F),
        );
      case 'LATE':
        return StatusChip(
          label: 'LATE',
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
        );
      default:
        return StatusChip(
          label: code,
          bgColor: const Color(0xFFF5F5F5),
          textColor: const Color(0xFF616161),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class KehadiranSayaController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  var isLoading = false.obs;
  var model = Rxn<DetailKehadiranModel>();
  var showBasePhoto = false.obs;

  final DateTime tanggal;
  final Map<String, dynamic>? rawAbsensi; // data dari riwayat (opsional)

  KehadiranSayaController({required this.tanggal, this.rawAbsensi});

  @override
  void onInit() {
    super.onInit();
    _buildModel();
  }

  /// Build model dari rawAbsensi (data lokal) atau fetch dari API.
  Future<void> _buildModel() async {
    isLoading.value = true;
    try {
      if (rawAbsensi != null && rawAbsensi!.isNotEmpty) {
        _parseFromRaw(rawAbsensi!);
      } else {
        await _fetchFromApi();
      }
    } catch (e) {
      debugPrint('KehadiranSayaController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _parseFromRaw(Map<String, dynamic> raw) {
    final auth = _auth;

    // Nama & jabatan
    final namaLengkap = auth.employeeFullName.isNotEmpty
        ? auth.employeeFullName
        : auth.userName;
    final jabatan = auth.positionName.isNotEmpty
        ? auth.positionName
        : auth.departmentName.isNotEmpty
        ? auth.departmentName
        : auth.userRole;
    final initial = _buildInitial(namaLengkap);

    // Tanggal
    final tglRaw =
        raw['tanggal_absen']?.toString() ??
        raw['waktu_absen']?.toString() ??
        '';
    final tglFormatted = _formatTanggal(tglRaw);

    // Shift
    final shift = _buildShiftLabel(raw);

    // Status chips
    final statusList = <StatusChip>[];
    final statusRaw = raw['status_codes'] ?? raw['status_list'];
    if (statusRaw is List) {
      for (final s in statusRaw) {
        statusList.add(StatusChip.fromCode(s.toString()));
      }
    } else {
      // Fallback: buat chip dari status tunggal
      final s = raw['status']?.toString() ?? '';
      if (s == 'terlambat') statusList.add(StatusChip.fromCode('LATE'));
      if (s == 'tepat_waktu') statusList.add(StatusChip.fromCode('PRS'));
      // Default chips jika API belum kirim status_codes
      if (statusList.isEmpty) {
        statusList.addAll([
          StatusChip.fromCode('EAI'),
          StatusChip.fromCode('EAO'),
          StatusChip.fromCode('PRS'),
        ]);
      }
    }

    // Keterangan
    final keterangan = raw['keterangan']?.toString() ?? '-';

    // Masuk
    final masukData = raw['masuk'] as Map<String, dynamic>? ?? {};
    final jamMasuk = _parseWaktu(
      masukData['waktu_absen']?.toString() ?? raw['waktu_masuk']?.toString(),
    );
    final fotoMasukUrl = _resolveFotoUrl(masukData) ?? _resolveFotoUrl(raw);
    final wajahMasuk = _buildWajahLabel(masukData);
    final lokasiMasuk = _buildLokasiLabel(masukData);
    final confidenceMasuk = (masukData['confidence_score'] as num?)?.toDouble();

    // Pulang
    final pulangData = raw['pulang'] as Map<String, dynamic>? ?? {};
    final jamKeluar = _parseWaktu(
      pulangData['waktu_absen']?.toString() ?? raw['waktu_pulang']?.toString(),
    );
    final fotoPulangUrl = _resolveFotoUrl(pulangData);
    final wajahPulang = _buildWajahLabel(pulangData);
    final lokasiPulang = _buildLokasiLabel(pulangData);
    final confidencePulang = (pulangData['confidence_score'] as num?)
        ?.toDouble();

    // Foto dasar
    final fotoDasarUrl = auth.fotoWajahUrl.isNotEmpty
        ? auth.fotoWajahUrl
        : null;

    // Lengkap?
    final belumLengkap = jamMasuk == null || jamKeluar == null;

    model.value = DetailKehadiranModel(
      namaLengkap: namaLengkap,
      jabatan: jabatan,
      photoUrl: auth.photoUrl.isNotEmpty ? auth.photoUrl : null,
      initial: initial,
      tanggal: tglFormatted,
      shift: shift,
      statusChips: statusList,
      keterangan: keterangan,
      jamMasuk: jamMasuk,
      fotoMasukUrl: fotoMasukUrl,
      wajahMasukLabel: wajahMasuk,
      lokasiMasuk: lokasiMasuk,
      confidenceMasuk: confidenceMasuk,
      jamKeluar: jamKeluar,
      fotoPulangUrl: fotoPulangUrl,
      wajahPulangLabel: wajahPulang,
      lokasiPulang: lokasiPulang,
      confidencePulang: confidencePulang,
      fotoDasarUrl: fotoDasarUrl,
      kehadiranBelumLengkap: belumLengkap,
    );
  }

  Future<void> _fetchFromApi() async {
    try {
      final base = _auth.box.read('base_url')?.toString() ?? '';
      if (base.isEmpty) return;

      final tgl =
          '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('$base/user/kehadiran-detail?tanggal=$tgl');

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer ${_auth.token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _parseFromRaw(data['data'] ?? data);
      } else {
        // Fallback: buat model kosong dengan data auth
        _parseFromRaw({});
      }
    } catch (e) {
      _parseFromRaw({});
    }
  }

  void toggleBasePhoto() => showBasePhoto.value = !showBasePhoto.value;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _buildInitial(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatTanggal(String raw) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    try {
      DateTime dt;
      if (raw.contains('T') || (raw.contains('-') && raw.length > 10)) {
        dt = DateTime.parse(raw).toLocal();
      } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
        dt = DateTime.parse(raw);
      } else {
        return raw;
      }
      return '${dt.day} ${monthNames[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _buildShiftLabel(Map<String, dynamic> raw) {
    debugPrint('RAW KEYS: ${raw.keys.toList()}');
    debugPrint('MASUK KEYS: ${(raw['masuk'] as Map?)?.keys.toList()}');
    debugPrint('FOTO ABSEN URL: ${raw['masuk']?['foto_absen_url']}');
    debugPrint('FOTO ABSEN PATH: ${raw['masuk']?['foto_absen_path']}');
    // Cek level atas dulu, lalu fallback ke nested masuk/pulang
    final shift =
        (raw['shift'] as Map<String, dynamic>?) ??
        (raw['masuk']?['shift'] as Map<String, dynamic>?) ??
        (raw['pulang']?['shift'] as Map<String, dynamic>?);

    if (shift == null) return '-';
    final nama = shift['nama']?.toString() ?? '';
    final jamMasuk = shift['jam_masuk']?.toString() ?? '';
    final jamPulang = shift['jam_pulang']?.toString() ?? '';
    if (nama.isEmpty) return '-';
    if (jamMasuk.isNotEmpty && jamPulang.isNotEmpty) {
      return '$nama [$jamMasuk - $jamPulang]';
    }
    return nama;
  }

  String? _parseWaktu(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      if (raw.contains(':')) return raw.substring(0, 5);
      return null;
    }
  }

  String? _resolveFotoUrl(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;

    // foto_absen_url sudah full URL dari accessor backend
    final url = data['foto_absen_url']?.toString();
    if (url != null && url.isNotEmpty) return url;

    // Fallback: resolve dari path
    final path = data['foto_absen_path']?.toString();
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) return path;
      String base = _auth.box.read('base_url')?.toString() ?? '';
      if (base.isNotEmpty) {
        final origin = base.replaceFirst(RegExp(r'/api/?$'), '');
        return '$origin/storage/foto_absensi/$path';
      }
    }

    return null;
  }

  String? _buildWajahLabel(Map<String, dynamic> data) {
    final hasil =
        data['face_result']?.toString() ?? data['wajah_hasil']?.toString();
    final persen =
        data['face_confidence']?.toString() ??
        data['wajah_confidence']?.toString();
    if (hasil == null) return null;
    final status = (hasil == 'lulus' || hasil == 'pass') ? 'Lulus' : 'Gagal';
    if (persen != null) {
      return 'Identifikasi Wajah: $status (${persen}% Cocok)';
    }
    return 'Identifikasi Wajah: $status';
  }

  String? _buildLokasiLabel(Map<String, dynamic> data) {
    final lat = data['latitude']?.toString();
    final lng = data['longitude']?.toString();
    if (lat != null && lng != null) return '$lat,$lng';
    return data['lokasi']?.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class KehadiranSayaPage extends StatelessWidget {
  final DateTime tanggal;
  final Map<String, dynamic>? rawAbsensi;

  const KehadiranSayaPage({super.key, required this.tanggal, this.rawAbsensi});

  static void show(DateTime tanggal, {Map<String, dynamic>? rawAbsensi}) {
    final tag = 'kehadiran_${tanggal.toIso8601String().substring(0, 10)}';
    if (!Get.isRegistered<KehadiranSayaController>(tag: tag)) {
      Get.put(
        KehadiranSayaController(tanggal: tanggal, rawAbsensi: rawAbsensi),
        tag: tag,
      );
    }
    Get.to(
      () => KehadiranSayaPage(tanggal: tanggal, rawAbsensi: rawAbsensi),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
  }

  String get _tag => 'kehadiran_${tanggal.toIso8601String().substring(0, 10)}';

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<KehadiranSayaController>(tag: _tag)
        ? Get.find<KehadiranSayaController>(tag: _tag)
        : Get.put(
            KehadiranSayaController(tanggal: tanggal, rawAbsensi: rawAbsensi),
            tag: _tag,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF1A1F36),
            ),
          ),
          title: const Text(
            'Detail Kehadiran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F36),
            ),
          ),
          centerTitle: false,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ),
        ),
        body: Obx(() {
          if (c.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E88E5),
                strokeWidth: 2,
              ),
            );
          }

          final m = c.model.value;
          if (m == null) {
            return const Center(child: Text('Data tidak tersedia'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Row ──────────────────────────────────────────
                _buildProfileRow(m, c),
                _divider(),

                // ── Info Section ─────────────────────────────────────────
                _buildInfoSection(m),
                _divider(),

                // ── Warning + Koreksi ────────────────────────────────────
                if (m.kehadiranBelumLengkap) ...[
                  _buildWarningBanner(),
                  _divider(),
                ],

                // ── Attendance Card ──────────────────────────────────────
                _buildAttendanceCard(m, c),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Profile Row ──────────────────────────────────────────────────────────

  Widget _buildProfileRow(DetailKehadiranModel m, KehadiranSayaController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(m),
          const SizedBox(width: 14),
          // Name & jabatan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.namaLengkap,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (m.jabatan.isNotEmpty)
                  Text(
                    m.jabatan,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A94A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Lihat Log button
          GestureDetector(
            onTap: () {
              // TODO: navigasi ke halaman log
            },
            child: const Text(
              'Lihat Log',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E88E5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(DetailKehadiranModel m) {
    final hasPhoto = m.photoUrl != null && m.photoUrl!.isNotEmpty;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8EDF5),
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                m.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialText(m.initial),
              ),
            )
          : _initialText(m.initial),
    );
  }

  Widget _initialText(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8A94A6),
        ),
      ),
    );
  }

  // ── Info Section ─────────────────────────────────────────────────────────

  Widget _buildInfoSection(DetailKehadiranModel m) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal
          _infoLabel('Tanggal'),
          const SizedBox(height: 4),
          _infoValue(m.tanggal),
          const SizedBox(height: 16),

          // Shift
          _infoLabel('Shift'),
          const SizedBox(height: 4),
          _infoValue(m.shift),
          const SizedBox(height: 16),

          // Status chips
          _infoLabel('Status'),
          const SizedBox(height: 8),
          if (m.statusChips.isEmpty)
            _infoValue('-')
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: m.statusChips.map(_buildStatusChip).toList(),
            ),
          const SizedBox(height: 16),

          // Keterangan
          _infoLabel('Keterangan'),
          const SizedBox(height: 4),
          _infoValue(m.keterangan.isEmpty ? '-' : m.keterangan),
        ],
      ),
    );
  }

  Widget _infoLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
    );
  }

  Widget _infoValue(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1F36),
      ),
    );
  }

  Widget _buildStatusChip(StatusChip chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: chip.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        chip.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: chip.textColor,
        ),
      ),
    );
  }

  // ── Warning Banner ───────────────────────────────────────────────────────

  Widget _buildWarningBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBDEFB), width: 1),
        ),
        child: Column(
          children: [
            // Warning text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1E88E5),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Kehadiran Anda belum lengkap',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Koreksi button
            GestureDetector(
              onTap: () {
                // TODO: navigasi ke halaman koreksi kehadiran
              },
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Koreksi Kehadiran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Attendance Card ──────────────────────────────────────────────────────

  Widget _buildAttendanceCard(
    DetailKehadiranModel m,
    KehadiranSayaController c,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ),

            // Masuk row
            Obx(
              () => _buildAttendanceRow(
                label: 'Jam Masuk',
                jam: m.jamMasuk,
                fotoUrl: m.fotoMasukUrl,
                fotoDasarUrl: c.showBasePhoto.value ? m.fotoDasarUrl : null,
                wajahLabel: m.wajahMasukLabel,
                lokasiLabel: m.lokasiMasuk,
                confidenceScore: m.confidenceMasuk,
                initial: m.initial,
                showBasePhoto: c.showBasePhoto.value,
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Pulang row
            Obx(
              () => _buildAttendanceRow(
                label: 'Jam Keluar',
                jam: m.jamKeluar,
                fotoUrl: m.fotoPulangUrl,
                fotoDasarUrl: c.showBasePhoto.value ? m.fotoDasarUrl : null,
                wajahLabel: m.wajahPulangLabel,
                lokasiLabel: m.lokasiPulang,
                confidenceScore: m.confidencePulang,
                initial: m.initial,
                showBasePhoto: c.showBasePhoto.value,
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Tampilkan / Tutup Base Photo
            _buildBasePhotoToggle(c),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRow({
    required String label,
    required String? jam,
    required String? fotoUrl,
    required String? fotoDasarUrl,
    required String? wajahLabel,
    required String? lokasiLabel,
    required double? confidenceScore,
    required String initial,
    required bool showBasePhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: showBasePhoto
          // ── Mode 2 kolom (foto kehadiran + foto dasar) ──
          ? _buildTwoColumnPhoto(
              label: label,
              jam: jam,
              fotoUrl: fotoUrl,
              fotoDasarUrl: fotoDasarUrl,
              wajahLabel: wajahLabel,
              lokasiLabel: lokasiLabel,
              confidenceScore: confidenceScore,
              initial: initial,
            )
          // ── Mode 1 kolom (default) ──
          : _buildOneColumnPhoto(
              label: label,
              jam: jam,
              fotoUrl: fotoUrl,
              wajahLabel: wajahLabel,
              lokasiLabel: lokasiLabel,
              confidenceScore: confidenceScore,
              initial: initial,
            ),
    );
  }

  /// Mode default: foto di kiri, info di kanan
  Widget _buildOneColumnPhoto({
    required String label,
    required String? jam,
    required String? fotoUrl,
    required String? wajahLabel,
    required String? lokasiLabel,
    required double? confidenceScore,
    required String initial,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto
        Column(
          children: [
            _buildFotoBox(fotoUrl, initial, width: 130, height: 155),
            const SizedBox(height: 6),
            _buildDeviceIcon(),
            const SizedBox(height: 4),
            const Text(
              'Foto Kehadiran',
              style: TextStyle(fontSize: 11, color: Color(0xFF8A94A6)),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
              ),
              const SizedBox(height: 4),
              Text(
                jam ?? '--:--',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              if (wajahLabel != null)
                _buildInfoRow(
                  icon: Icons.face_retouching_natural_outlined,
                  color: const Color(0xFF4CAF50),
                  text: wajahLabel,
                ),
              if (wajahLabel != null) const SizedBox(height: 6),
              if (lokasiLabel != null)
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  color: const Color(0xFF4CAF50),
                  text: lokasiLabel,
                ),
              if (confidenceScore != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  icon: Icons.verified_outlined,
                  color: confidenceScore >= 0.8
                      ? const Color(0xFF4CAF50)
                      : confidenceScore >= 0.6
                      ? const Color(0xFFFF9800)
                      : const Color(0xFFE53935),
                  text:
                      'Confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Mode Tampilkan Base Photo: foto kehadiran + foto dasar berdampingan
  Widget _buildTwoColumnPhoto({
    required String label,
    required String? jam,
    required String? fotoUrl,
    required String? fotoDasarUrl,
    required String? wajahLabel,
    required String? lokasiLabel,
    required double? confidenceScore,
    required String initial,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
        ),
        const SizedBox(height: 4),
        Text(
          jam ?? '--:--',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1F36),
          ),
        ),
        if (wajahLabel != null) ...[
          const SizedBox(height: 6),
          _buildInfoRow(
            icon: Icons.face_retouching_natural_outlined,
            color: const Color(0xFF4CAF50),
            text: wajahLabel,
          ),
        ],
        if (lokasiLabel != null) ...[
          const SizedBox(height: 4),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            color: const Color(0xFF4CAF50),
            text: lokasiLabel,
          ),
        ],
        if (confidenceScore != null) ...[
          // ← tambah ini
          const SizedBox(height: 4),
          _buildInfoRow(
            icon: Icons.verified_outlined,
            color: confidenceScore >= 0.8
                ? const Color(0xFF4CAF50)
                : confidenceScore >= 0.6
                ? const Color(0xFFFF9800)
                : const Color(0xFFE53935),
            text: 'Confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%',
          ),
        ],
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto Kehadiran
            Expanded(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _buildFotoBox(
                      fotoUrl,
                      initial,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDeviceIcon(),
                  const SizedBox(height: 4),
                  const Text(
                    'Foto Kehadiran',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A94A6)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Foto Dasar
            Expanded(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _buildFotoBox(
                      fotoDasarUrl,
                      initial,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(
                    height: 32,
                  ), // spacer sejajar dengan device icon
                  const Text(
                    'Foto Dasar',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A94A6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFotoBox(
    String? url,
    String initial, {
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFE0E4EC),
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _photoPlaceholder(initial),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E88E5),
                      strokeWidth: 2,
                    ),
                  );
                },
              )
            : _photoPlaceholder(initial),
      ),
    );
  }

  Widget _photoPlaceholder(String initial) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 40, color: Color(0xFFB0B8C9)),
          const SizedBox(height: 4),
          Text(
            initial,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB0B8C9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.smartphone_rounded,
        size: 16,
        color: Color(0xFF8A94A6),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Base Photo Toggle ────────────────────────────────────────────────────

  Widget _buildBasePhotoToggle(KehadiranSayaController c) {
    return Obx(() {
      final show = c.showBasePhoto.value;
      return InkWell(
        onTap: c.toggleBasePhoto,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                show ? Icons.close_rounded : Icons.remove_red_eye_outlined,
                size: 18,
                color: const Color(0xFF1E88E5),
              ),
              const SizedBox(width: 8),
              Text(
                show ? 'Tutup Base Photo' : 'Tampilkan Base Photo',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Shared ───────────────────────────────────────────────────────────────

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0));
}
