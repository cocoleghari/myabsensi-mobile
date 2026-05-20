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
import '../../../pages/admin/master_drawer.dart'; // sesuaikan path

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class SummaryAktivitas {
  final int totalAktivitas;
  final int totalKaryawan;
  final double rataDurasiMenit;
  final Map<String, int> perTipe;
  final List<Map<String, dynamic>> perKaryawan;

  const SummaryAktivitas({
    required this.totalAktivitas,
    required this.totalKaryawan,
    required this.rataDurasiMenit,
    required this.perTipe,
    required this.perKaryawan,
  });

  factory SummaryAktivitas.fromJson(Map<String, dynamic> json) {
    final rawTipe = json['per_tipe'];
    final Map<String, dynamic> perTipeRaw = (rawTipe is Map)
        ? Map<String, dynamic>.from(rawTipe)
        : {};
    final perTipe = perTipeRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    // Fix: handle berbagai kemungkinan struktur per_karyawan
    final perKaryawanRaw = json['per_karyawan'];
    final List<Map<String, dynamic>> perKaryawan;
    if (perKaryawanRaw is List) {
      perKaryawan = perKaryawanRaw
          .map(
            (e) =>
                e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
          )
          .toList();
    } else {
      perKaryawan = [];
    }

    return SummaryAktivitas(
      totalAktivitas: json['total_aktivitas'] as int? ?? 0,
      totalKaryawan: json['total_karyawan'] as int? ?? 0,
      rataDurasiMenit: (json['rata_durasi_menit'] as num?)?.toDouble() ?? 0,
      perTipe: perTipe,
      perKaryawan: perKaryawan,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class LaporanAktivitasController extends GetxController {
  final AuthController _auth = Get.find();
  final box = GetStorage();

  // Filter state
  var tanggalMulai = DateTime.now().subtract(const Duration(days: 30)).obs;
  var tanggalSelesai = DateTime.now().obs;
  var selectedEmployeeId = Rxn<int>();
  var selectedDepartmentId = Rxn<int>();
  var selectedTipeAktivitasId = Rxn<int>();
  var selectedFormat = 'detail'.obs; // detail | rekap_karyawan | rekap_tipe

  // UI state
  var isLoadingSummary = false.obs;
  var isExporting = false.obs;
  var summary = Rxn<SummaryAktivitas>();

  // Dropdown data
  var employees = <Map<String, dynamic>>[].obs;
  var departments = <Map<String, dynamic>>[].obs;
  var tipeAktivitas = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadDropdowns();
    fetchSummary();
  }

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
        http.get(Uri.parse('$_baseUrl/admin/departments'), headers: _headers),
        http.get(
          Uri.parse('$_baseUrl/admin/tipe-aktivitas'),
          headers: _headers,
        ),
      ]);

      // DEBUG — lihat response asli
      debugPrint('=== EMPLOYEES RESPONSE ===');
      debugPrint(futures[0].body.substring(0, 200));
      debugPrint('=== DEPARTMENTS RESPONSE ===');
      debugPrint(futures[1].body.substring(0, 200));
      debugPrint('=== TIPE AKTIVITAS RESPONSE ===');
      debugPrint(futures[2].body.substring(0, 200));

      // Employees
      if (futures[0].statusCode == 200) {
        final data = jsonDecode(futures[0].body);
        final list = _extractList(data);
        employees.value = list;
      }

      // Departments
      if (futures[1].statusCode == 200) {
        final data = jsonDecode(futures[1].body);
        final list = _extractList(data);
        departments.value = list;
      }

      // Tipe Aktivitas
      if (futures[2].statusCode == 200) {
        final data = jsonDecode(futures[2].body);
        final list = _extractList(data);
        tipeAktivitas.value = list;
      }
    } catch (e) {
      debugPrint('_loadDropdowns error: $e');
    }
  }

  /// Ekstrak list dari berbagai format response:
  /// - langsung List: [...]
  /// - {data: [...]}
  /// - {status: true, data: [...]}
  List<Map<String, dynamic>> _extractList(dynamic data) {
    List? list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = (data['data'] ?? data['items'] ?? []) as List?;
    }
    return list
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
  }

  // ── FETCH SUMMARY ─────────────────────────────────────────────────────────
  Future<void> fetchSummary() async {
    isLoadingSummary.value = true;
    summary.value = null;
    try {
      final uri = Uri.parse(
        '$_baseUrl/admin/laporan-aktivitas/summary',
      ).replace(queryParameters: _buildParams());

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      // DEBUG — tambah ini
      debugPrint('=== SUMMARY RESPONSE ===');
      debugPrint(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        summary.value = SummaryAktivitas.fromJson(data);
      } else {
        _showError('Gagal memuat ringkasan');
      }
    } catch (e, stack) {
      // Tambah stack trace
      debugPrint('fetchSummary error: $e');
      debugPrint('$stack');
      _showError('Koneksi error: $e');
    } finally {
      isLoadingSummary.value = false;
    }
  }

  // ── EXPORT ────────────────────────────────────────────────────────────────
  Future<void> exportExcel() async {
    isExporting.value = true;
    try {
      final saveDir = await _resolveSaveDirectory();
      if (saveDir == null) return;

      final params = _buildParams();
      params['format'] = selectedFormat.value;

      final uri = Uri.parse(
        '$_baseUrl/admin/laporan-aktivitas/export',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final fmt = DateFormat('yyyyMMdd_HHmm');
        final filename = 'laporan_aktivitas_${fmt.format(DateTime.now())}.xlsx';
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

  Future<Directory?> _resolveSaveDirectory() async {
    if (!Platform.isAndroid) return getApplicationDocumentsDirectory();

    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (await downloadsDir.exists()) {
      try {
        final testFile = File('${downloadsDir.path}/.test_write');
        await testFile.writeAsString('test');
        await testFile.delete();
        return downloadsDir;
      } catch (_) {}
    }

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
    if (selectedDepartmentId.value != null)
      params['department_id'] = selectedDepartmentId.value.toString();
    if (selectedTipeAktivitasId.value != null)
      params['tipe_aktivitas_id'] = selectedTipeAktivitasId.value.toString();
    return params;
  }

  void resetFilter() {
    tanggalMulai.value = DateTime.now().subtract(const Duration(days: 30));
    tanggalSelesai.value = DateTime.now();
    selectedEmployeeId.value = null;
    selectedDepartmentId.value = null;
    selectedTipeAktivitasId.value = null;
    fetchSummary();
  }

  String formatDurasi(double menit) {
    if (menit <= 0) return '0 mnt';
    final jam = menit ~/ 60;
    final sisa = (menit % 60).round();
    if (jam > 0) return sisa > 0 ? '${jam}j ${sisa}mnt' : '${jam}j';
    return '${sisa}mnt';
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  List<Map<String, dynamic>> get filteredEmployees {
    if (selectedDepartmentId.value == null) return employees;
    return employees.where((e) {
      final deptId = (e['department_id'] as num?)?.toInt();
      return deptId == selectedDepartmentId.value;
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class LaporanAktivitasPage extends StatelessWidget {
  const LaporanAktivitasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LaporanAktivitasController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Laporan Aktivitas',
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
      drawer: const MasterDrawer(currentPage: 'laporan-aktivitas'),
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
// FILTER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FilterCard extends StatelessWidget {
  final LaporanAktivitasController c;
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
                      value: (d['id'] as num?)?.toInt(),
                      child: Text(
                        d['name']?.toString() ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  c.selectedDepartmentId.value = v;

                  // Reset karyawan jika tidak ada di department baru
                  if (v != null && c.selectedEmployeeId.value != null) {
                    final stillValid = c.filteredEmployees.any(
                      (e) =>
                          (e['id'] as num?)?.toInt() ==
                          c.selectedEmployeeId.value,
                    );
                    if (!stillValid) c.selectedEmployeeId.value = null;
                  }

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
                  ...c.filteredEmployees.map(
                    (e) => DropdownMenuItem(
                      value: (e['id'] as num?)?.toInt(),
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

            // Tipe Aktivitas
            Obx(
              () => _DropdownField<int?>(
                label: 'Tipe Aktivitas',
                value: c.selectedTipeAktivitasId.value,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Tipe'),
                  ),
                  ...c.tipeAktivitas.map(
                    (t) => DropdownMenuItem(
                      value: (t['id'] as num?)?.toInt(),
                      child: Text(
                        t['nama']?.toString() ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  c.selectedTipeAktivitasId.value = v;
                  c.fetchSummary();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _SummarySection extends StatelessWidget {
  final LaporanAktivitasController c;
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
              // Statistik utama
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Aktivitas',
                      value: s.totalAktivitas.toString(),
                      color: const Color(0xFF3B82F6),
                      icon: Icons.assignment_rounded,
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
                      label: 'Rata Durasi',
                      value: c.formatDurasi(s.rataDurasiMenit),
                      color: const Color(0xFF14B8A6),
                      icon: Icons.timer_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tipe terbanyak
                  Expanded(
                    child: _StatCard(
                      label: 'Tipe Terbanyak',
                      value: s.perTipe.isEmpty
                          ? '-'
                          : s.perTipe.entries
                                .reduce((a, b) => a.value >= b.value ? a : b)
                                .key,
                      color: const Color(0xFFF97316),
                      icon: Icons.category_rounded,
                    ),
                  ),
                ],
              ),

              // Per tipe aktivitas
              if (s.perTipe.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Per Tipe Aktivitas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a3a6b),
                    ),
                  ),
                ),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: s.perTipe.entries.map((entry) {
                        final persen = s.totalAktivitas > 0
                            ? entry.value / s.totalAktivitas
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1a3a6b),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: persen,
                                  backgroundColor: Colors.grey.shade200,
                                  color: const Color(0xFF1a3a6b),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              // Top karyawan
              if (s.perKaryawan.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Top Karyawan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a3a6b),
                    ),
                  ),
                ),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: s.perKaryawan.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final colors = [
                          const Color(0xFFFFD700),
                          const Color(0xFFC0C0C0),
                          const Color(0xFFCD7F32),
                          Colors.blueGrey,
                          Colors.blueGrey,
                        ];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: colors[i < 5 ? i : 4].withOpacity(
                              0.2,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors[i < 5 ? i : 4],
                              ),
                            ),
                          ),
                          title: Text(
                            item['nama']?.toString() ?? '-',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a3a6b).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item['total']} aktivitas',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1a3a6b),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPORT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ExportCard extends StatelessWidget {
  final LaporanAktivitasController c;
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

            const Text(
              'Format Laporan',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            Obx(
              () => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FormatOption(
                          label: 'Detail',
                          subtitle: '1 baris per aktivitas',
                          icon: Icons.table_rows_rounded,
                          isSelected: c.selectedFormat.value == 'detail',
                          onTap: () => c.selectedFormat.value = 'detail',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FormatOption(
                          label: 'Rekap Karyawan',
                          subtitle: 'Per karyawan',
                          icon: Icons.people_rounded,
                          isSelected:
                              c.selectedFormat.value == 'rekap_karyawan',
                          onTap: () =>
                              c.selectedFormat.value = 'rekap_karyawan',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FormatOption(
                          label: 'Rekap Tipe',
                          subtitle: 'Per tipe aktivitas',
                          icon: Icons.category_rounded,
                          isSelected: c.selectedFormat.value == 'rekap_tipe',
                          onTap: () => c.selectedFormat.value = 'rekap_tipe',
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
// SMALL WIDGETS (sama persis dengan laporan_absensi_page)
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
                    fontSize: 16,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
