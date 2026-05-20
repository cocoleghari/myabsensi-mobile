import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../controllers/auth_controller.dart';
import '../../../pages/admin/master_drawer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL ringkasan (dari endpoint /summary)
// ─────────────────────────────────────────────────────────────────────────────
class SummaryAbsensi {
  final int totalAbsensi;
  final int totalKaryawan;
  final int tepatWaktu;
  final int terlambat;
  final int diluarLokasi;
  final int lembur;
  final double rataMenitTerlambat;
  final double rataMenitLembur;

  const SummaryAbsensi({
    required this.totalAbsensi,
    required this.totalKaryawan,
    required this.tepatWaktu,
    required this.terlambat,
    required this.diluarLokasi,
    required this.lembur,
    required this.rataMenitTerlambat,
    required this.rataMenitLembur,
  });

  factory SummaryAbsensi.fromJson(Map<String, dynamic> json) => SummaryAbsensi(
    totalAbsensi: json['total_absensi'] as int? ?? 0,
    totalKaryawan: json['total_karyawan'] as int? ?? 0,
    tepatWaktu: json['tepat_waktu'] as int? ?? 0,
    terlambat: json['terlambat'] as int? ?? 0,
    diluarLokasi: json['diluar_lokasi'] as int? ?? 0,
    lembur: json['lembur'] as int? ?? 0,
    rataMenitTerlambat: (json['rata_menit_terlambat'] as num?)?.toDouble() ?? 0,
    rataMenitLembur: (json['rata_menit_lembur'] as num?)?.toDouble() ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER (GetX)
// ─────────────────────────────────────────────────────────────────────────────
class LaporanAbsensiController extends GetxController {
  final AuthController _auth = Get.find();
  final box = GetStorage();

  // Filter state
  var tanggalMulai = DateTime.now().subtract(const Duration(days: 30)).obs;
  var tanggalSelesai = DateTime.now().obs;
  var selectedEmployeeId = Rxn<int>();
  var selectedPusatLokasiId = Rxn<int>();
  var selectedDepartmentId = Rxn<int>();
  var selectedStatus = Rxn<String>();
  var selectedTipeAbsen = Rxn<String>();
  var selectedFormat = 'detail'.obs; // detail | rekap

  // UI state
  var isLoadingSummary = false.obs;
  var isExporting = false.obs;
  var summary = Rxn<SummaryAbsensi>();

  // Dropdown data
  var employees = <Map<String, dynamic>>[].obs;
  var pusatLokasi = <Map<String, dynamic>>[].obs;
  var departments = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadDropdowns();
    fetchSummary();
  }

  // ── BASE URL ──────────────────────────────────────────────────────────────
  String get _baseUrl => box.read('base_url') ?? '';
  String get _token => _auth.token.value;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  // ── LOAD DROPDOWNS ────────────────────────────────────────────────────────
  Future<void> _loadDropdowns() async {
    try {
      final futures = await Future.wait([
        http.get(
          Uri.parse('$_baseUrl/admin/employees-dropdown'),
          headers: _headers,
        ),
        http.get(Uri.parse('$_baseUrl/admin/pusat-lokasi'), headers: _headers),
        http.get(Uri.parse('$_baseUrl/admin/departments'), headers: _headers),
      ]);

      // Employees
      if (futures[0].statusCode == 200) {
        final data = jsonDecode(futures[0].body);
        final list = (data['data'] ?? data) as List?;
        employees.value = list?.cast<Map<String, dynamic>>() ?? [];
      }

      // Pusat Lokasi
      if (futures[1].statusCode == 200) {
        final data = jsonDecode(futures[1].body);
        final list = (data['data'] ?? data) as List?;
        pusatLokasi.value = list?.cast<Map<String, dynamic>>() ?? [];
      }

      // Departments
      if (futures[2].statusCode == 200) {
        final data = jsonDecode(futures[2].body);
        final list = (data['data'] ?? data) as List?;
        departments.value = list?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (e) {
      debugPrint('_loadDropdowns error: $e');
    }
  }

  // ── FETCH SUMMARY ─────────────────────────────────────────────────────────
  Future<void> fetchSummary() async {
    isLoadingSummary.value = true;
    summary.value = null;
    try {
      final uri = Uri.parse(
        '$_baseUrl/admin/laporan-absensi/summary',
      ).replace(queryParameters: _buildParams());

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        summary.value = SummaryAbsensi.fromJson(data);
      } else {
        _showError('Gagal memuat ringkasan');
      }
    } catch (e) {
      _showError('Koneksi error: $e');
    } finally {
      isLoadingSummary.value = false;
    }
  }

  // ── EXPORT ───────────────────────────────────────────────────────────────
  Future<void> exportExcel() async {
    isExporting.value = true;
    try {
      // Tentukan direktori simpan & urus izin sesuai versi Android
      final saveDir = await _resolveSaveDirectory();
      if (saveDir == null) return; // izin ditolak, error sudah ditampilkan

      final params = _buildParams();
      params['format'] = selectedFormat.value;

      final uri = Uri.parse(
        '$_baseUrl/admin/laporan-absensi/export',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final fmt = DateFormat('yyyyMMdd_HHmm');
        final filename = 'laporan_absensi_${fmt.format(DateTime.now())}.xlsx';
        final file = File('${saveDir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        Get.snackbar(
          'Berhasil',
          'Disimpan di: ${file.path}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
          mainButton: TextButton(
            onPressed: () => OpenFile.open(file.path),
            child: const Text('Buka', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        try {
          final data = jsonDecode(response.body);
          _showError(data['message'] ?? 'Gagal mengekspor data');
        } catch (_) {
          _showError('Gagal mengekspor (status ${response.statusCode})');
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      isExporting.value = false;
    }
  }

  /// Pilih direktori simpan & urus izin sesuai versi Android.
  /// Mengembalikan null jika izin ditolak.
  Future<Directory?> _resolveSaveDirectory() async {
    if (!Platform.isAndroid) {
      return getApplicationDocumentsDirectory();
    }

    // Android 10+ (API 29+): tidak perlu izin WRITE_EXTERNAL_STORAGE
    // Langsung gunakan folder Downloads publik
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (await downloadsDir.exists()) {
      // Coba tulis tanpa minta izin dulu (berlaku untuk API 29+)
      try {
        final testFile = File('${downloadsDir.path}/.test_write');
        await testFile.writeAsString('test');
        await testFile.delete();
        return downloadsDir;
      } catch (_) {
        // Gagal tulis — mungkin Android 9 ke bawah, minta izin
      }
    }

    // Fallback: minta izin WRITE_EXTERNAL_STORAGE (Android 9 ke bawah)
    final status = await Permission.storage.request();
    if (status.isGranted) {
      return downloadsDir.existsSync()
          ? downloadsDir
          : await getApplicationDocumentsDirectory();
    } else if (status.isPermanentlyDenied) {
      _showError('Izin ditolak permanen. Aktifkan di Pengaturan > Aplikasi.');
      openAppSettings();
      return null;
    } else {
      // Fallback ke app directory yang tidak butuh izin
      return getApplicationDocumentsDirectory();
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Map<String, String> _buildParams() {
    final fmt = DateFormat('yyyy-MM-dd');
    final params = <String, String>{
      'tanggal_mulai': fmt.format(tanggalMulai.value),
      'tanggal_selesai': fmt.format(tanggalSelesai.value),
    };
    if (selectedEmployeeId.value != null)
      params['employee_id'] = selectedEmployeeId.value.toString();
    if (selectedPusatLokasiId.value != null)
      params['pusat_lokasi_id'] = selectedPusatLokasiId.value.toString();
    if (selectedDepartmentId.value != null)
      params['department_id'] = selectedDepartmentId.value.toString();
    if (selectedStatus.value != null) params['status'] = selectedStatus.value!;
    if (selectedTipeAbsen.value != null)
      params['tipe_absen'] = selectedTipeAbsen.value!;
    return params;
  }

  void resetFilter() {
    tanggalMulai.value = DateTime.now().subtract(const Duration(days: 30));
    tanggalSelesai.value = DateTime.now();
    selectedEmployeeId.value = null;
    selectedPusatLokasiId.value = null;
    selectedDepartmentId.value = null;
    selectedStatus.value = null;
    selectedTipeAbsen.value = null;
    fetchSummary();
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class LaporanAbsensiPage extends StatelessWidget {
  const LaporanAbsensiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LaporanAbsensiController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Laporan Absensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1a3a6b),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: c.fetchSummary,
          ),
        ],
      ),
      drawer: const MasterDrawer(
        currentPage: 'laporan-absensi',
      ), // ← tambah ini
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterCard(c: c),
            const SizedBox(height: 16),
            _SummarySection(c: c),
            const SizedBox(height: 16),
            _ExportCard(c: c),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET — Filter Card
// ─────────────────────────────────────────────────────────────────────────────
class _FilterCard extends StatelessWidget {
  final LaporanAbsensiController c;
  const _FilterCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt_rounded, color: Color(0xFF1a3a6b)),
                const SizedBox(width: 8),
                const Text(
                  'Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: c.resetFilter,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),

            // Tanggal
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Dari',
                    value: c.tanggalMulai,
                    onPick: (d) {
                      c.tanggalMulai.value = d;
                      c.fetchSummary();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Sampai',
                    value: c.tanggalSelesai,
                    onPick: (d) {
                      c.tanggalSelesai.value = d;
                      c.fetchSummary();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Department
            Obx(
              () => _DropdownField<int?>(
                label: 'Department',
                value: c.selectedDepartmentId.value,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Department'),
                  ),
                  ...c.departments.map(
                    (d) => DropdownMenuItem(
                      value: d['id'] as int?,
                      child: Text(
                        d['name']?.toString() ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  c.selectedDepartmentId.value = v;
                  c.fetchSummary();
                },
              ),
            ),
            const SizedBox(height: 12),

            // Karyawan
            Obx(
              () => _DropdownField<int?>(
                label: 'Karyawan',
                value: c.selectedEmployeeId.value,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Karyawan'),
                  ),
                  ...c.employees.map(
                    (e) => DropdownMenuItem(
                      value: e['id'] as int?,
                      child: Text(
                        e['full_name']?.toString() ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  c.selectedEmployeeId.value = v;
                  c.fetchSummary();
                },
              ),
            ),
            const SizedBox(height: 12),

            // Pusat Lokasi
            Obx(
              () => _DropdownField<int?>(
                label: 'Lokasi',
                value: c.selectedPusatLokasiId.value,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Lokasi'),
                  ),
                  ...c.pusatLokasi.map(
                    (l) => DropdownMenuItem(
                      value: l['id'] as int?,
                      child: Text(
                        l['nama_lokasi']?.toString() ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  c.selectedPusatLokasiId.value = v;
                  c.fetchSummary();
                },
              ),
            ),
            const SizedBox(height: 12),

            // Status & Tipe baris bawah
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => _DropdownField<String?>(
                      label: 'Status',
                      value: c.selectedStatus.value,
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Semua Status'),
                        ),
                        DropdownMenuItem(
                          value: 'tepat_waktu',
                          child: Text('Tepat Waktu'),
                        ),
                        DropdownMenuItem(
                          value: 'terlambat',
                          child: Text('Terlambat'),
                        ),
                        DropdownMenuItem(
                          value: 'diluar_lokasi',
                          child: Text('Di Luar Lokasi'),
                        ),
                        DropdownMenuItem(
                          value: 'lembur',
                          child: Text('Lembur'),
                        ),
                      ],
                      onChanged: (v) {
                        c.selectedStatus.value = v;
                        c.fetchSummary();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => _DropdownField<String?>(
                      label: 'Tipe',
                      value: c.selectedTipeAbsen.value,
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Semua Tipe'),
                        ),
                        DropdownMenuItem(value: 'masuk', child: Text('Masuk')),
                        DropdownMenuItem(
                          value: 'pulang',
                          child: Text('Pulang'),
                        ),
                      ],
                      onChanged: (v) {
                        c.selectedTipeAbsen.value = v;
                        c.fetchSummary();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET — Summary Section
// ─────────────────────────────────────────────────────────────────────────────
class _SummarySection extends StatelessWidget {
  final LaporanAbsensiController c;
  const _SummarySection({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Ringkasan Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a3a6b),
            ),
          ),
        ),
        Obx(() {
          if (c.isLoadingSummary.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF1a3a6b)),
              ),
            );
          }

          final s = c.summary.value;
          if (s == null) {
            return const Center(
              child: Text(
                'Tidak ada data',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Absensi',
                      value: s.totalAbsensi.toString(),
                      color: const Color(0xFF3B82F6),
                      icon: Icons.checklist_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Karyawan Aktif',
                      value: s.totalKaryawan.toString(),
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.people_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Tepat Waktu',
                      value: s.tepatWaktu.toString(),
                      color: const Color(0xFF22C55E),
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Terlambat',
                      value: s.terlambat.toString(),
                      color: const Color(0xFFEF4444),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Di Luar Lokasi',
                      value: s.diluarLokasi.toString(),
                      color: const Color(0xFFF97316),
                      icon: Icons.location_off_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Lembur',
                      value: s.lembur.toString(),
                      color: const Color(0xFF6366F1),
                      icon: Icons.nightlight_round,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Rata Terlambat',
                      value: '${s.rataMenitTerlambat} mnt',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.timer_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Rata Lembur',
                      value: '${s.rataMenitLembur} mnt',
                      color: const Color(0xFF14B8A6),
                      icon: Icons.more_time_rounded,
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET — Export Card
// ─────────────────────────────────────────────────────────────────────────────
class _ExportCard extends StatelessWidget {
  final LaporanAbsensiController c;
  const _ExportCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_rounded, color: Color(0xFF1a3a6b)),
                const SizedBox(width: 8),
                const Text(
                  'Export Excel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),

            // Format pilihan
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Format Laporan',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _FormatOption(
                          label: 'Detail',
                          subtitle: '1 baris per absensi',
                          icon: Icons.table_rows_rounded,
                          isSelected: c.selectedFormat.value == 'detail',
                          onTap: () => c.selectedFormat.value = 'detail',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FormatOption(
                          label: 'Rekap',
                          subtitle: 'Masuk & pulang per hari',
                          icon: Icons.summarize_rounded,
                          isSelected: c.selectedFormat.value == 'rekap',
                          onTap: () => c.selectedFormat.value = 'rekap',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: c.isExporting.value ? null : c.exportExcel,
                  icon: c.isExporting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    c.isExporting.value
                        ? 'Sedang Mengekspor...'
                        : 'Download Excel',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a3a6b),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'File akan disimpan ke folder Downloads.\nSheet berisi data + tab Ringkasan.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1a3a6b) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1a3a6b) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final Rx<DateTime> value;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value.value,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1a3a6b),
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPick(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
          child: Text(
            DateFormat('dd/MM/yyyy').format(value.value),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
    );
  }
}
