import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_controller.dart';
import 'app_config.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class ShiftModel {
  final int id;
  final int companyId;
  final String nama;
  final String kode;
  final String jamMasuk;
  final String jamPulang;
  final int toleransiTerlambatMenit;
  final int windowMasukAwalMenit;
  final bool melewatiTengahMalam;
  final String batasWaktuPulang;
  final bool berlakuHariLibur;
  final bool berlakuAkhirPekan;
  final String? keterangan;
  final bool isActive;
  final String? companyName;

  ShiftModel({
    required this.id,
    required this.companyId,
    required this.nama,
    required this.kode,
    required this.jamMasuk,
    required this.jamPulang,
    required this.toleransiTerlambatMenit,
    required this.windowMasukAwalMenit,
    required this.melewatiTengahMalam,
    required this.batasWaktuPulang,
    required this.berlakuHariLibur,
    required this.berlakuAkhirPekan,
    this.keterangan,
    required this.isActive,
    this.companyName,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) => ShiftModel(
    id: json['id'],
    companyId: json['company_id'],
    nama: json['nama'] ?? '',
    kode: json['kode'] ?? '',
    jamMasuk: json['jam_masuk'] ?? '00:00',
    jamPulang: json['jam_pulang'] ?? '00:00',
    toleransiTerlambatMenit: json['toleransi_terlambat_menit'] ?? 0,
    windowMasukAwalMenit: json['window_masuk_awal_menit'] ?? 30,
    melewatiTengahMalam:
        json['melewati_tengah_malam'] == true ||
        json['melewati_tengah_malam'] == 1,
    batasWaktuPulang: json['batas_waktu_pulang'] ?? '00:00',
    berlakuHariLibur:
        json['berlaku_hari_libur'] == true || json['berlaku_hari_libur'] == 1,
    berlakuAkhirPekan:
        json['berlaku_akhir_pekan'] == true || json['berlaku_akhir_pekan'] == 1,
    keterangan: json['keterangan'],
    isActive: json['is_active'] == true || json['is_active'] == 1,
    companyName: json['company']?['name'] ?? json['company_name'],
  );

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'nama': nama,
    'kode': kode,
    'jam_masuk': jamMasuk,
    'jam_pulang': jamPulang,
    'toleransi_terlambat_menit': toleransiTerlambatMenit,
    'window_masuk_awal_menit': windowMasukAwalMenit,
    'melewati_tengah_malam': melewatiTengahMalam,
    'batas_waktu_pulang': batasWaktuPulang,
    'berlaku_hari_libur': berlakuHariLibur,
    'berlaku_akhir_pekan': berlakuAkhirPekan,
    'keterangan': keterangan,
    'is_active': isActive,
  };
}

class EmployeeShiftModel {
  final int id;
  final int employeeId;
  final int? shiftId;
  final int? patternId;
  final String? patternNama;
  final String tanggalMulai;
  final String? tanggalSelesai;
  final String? keterangan;
  final String? employeeName;
  final String? employeeCode;
  final String? shiftNama;
  final String? shiftKode;
  final String? shiftJamMasuk;
  final String? shiftJamPulang;

  EmployeeShiftModel({
    required this.id,
    required this.employeeId,
    this.shiftId,
    this.patternId,
    this.patternNama,
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.keterangan,
    this.employeeName,
    this.employeeCode,
    this.shiftNama,
    this.shiftKode,
    this.shiftJamMasuk,
    this.shiftJamPulang,
  });

  factory EmployeeShiftModel.fromJson(Map<String, dynamic> json) =>
      EmployeeShiftModel(
        id: json['id'],
        employeeId: json['employee_id'],
        shiftId: json['shift_id'] as int?,
        patternId: json['pattern_id'] as int?,
        patternNama: json['pattern_nama'],
        tanggalMulai: json['tanggal_mulai'] ?? '',
        tanggalSelesai: json['tanggal_selesai'],
        keterangan: json['keterangan'],
        employeeName: json['employee']?['full_name'] ?? json['employee_name'],
        employeeCode:
            json['employee']?['employee_code'] ?? json['employee_code'],
        shiftNama: json['shift']?['nama'] ?? json['shift_nama'],
        shiftKode: json['shift']?['kode'] ?? json['shift_kode'],
        shiftJamMasuk: json['shift']?['jam_masuk'] ?? json['jam_masuk'],
        shiftJamPulang: json['shift']?['jam_pulang'] ?? json['jam_pulang'],
      );
}

class WeeklyPatternDay {
  final int hari;
  final String hariLabel;
  final int? shiftId;
  final String? shiftNama;
  final String? jamMasuk;
  final String? jamPulang;
  final bool isLibur;
  final String? keterangan;

  WeeklyPatternDay({
    required this.hari,
    required this.hariLabel,
    this.shiftId,
    this.shiftNama,
    this.jamMasuk,
    this.jamPulang,
    required this.isLibur,
    this.keterangan,
  });

  factory WeeklyPatternDay.fromJson(Map<String, dynamic> json) =>
      WeeklyPatternDay(
        hari: json['hari'],
        hariLabel: json['hari_label'] ?? '',
        shiftId: json['shift_id'],
        shiftNama: json['shift_nama'],
        jamMasuk: json['jam_masuk'],
        jamPulang: json['jam_pulang'],
        isLibur: json['is_libur'] == true || json['is_libur'] == 1,
        keterangan: json['keterangan'],
      );

  Map<String, dynamic> toJson() => {
    'hari': hari,
    'shift_id': shiftId,
    'is_libur': isLibur,
    'keterangan': keterangan,
  };
}

class WeeklyPatternModel {
  final int id;
  final int companyId;
  final String nama;
  final String kode;
  final String? keterangan;
  final bool isActive;
  final String? companyName;
  final List<WeeklyPatternDay> days;

  WeeklyPatternModel({
    required this.id,
    required this.companyId,
    required this.nama,
    required this.kode,
    this.keterangan,
    required this.isActive,
    this.companyName,
    this.days = const [],
  });

  factory WeeklyPatternModel.fromJson(Map<String, dynamic> json) =>
      WeeklyPatternModel(
        id: json['id'],
        companyId: json['company_id'],
        nama: json['nama'] ?? '',
        kode: json['kode'] ?? '',
        keterangan: json['keterangan'],
        isActive: json['is_active'] == true || json['is_active'] == 1,
        companyName: json['company']?['name'] ?? json['company_name'],
        days: (json['days'] as List? ?? [])
            .map((d) => WeeklyPatternDay.fromJson(d))
            .toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class ShiftController extends GetxController {
  final _auth = Get.find<AuthController>();

  var shifts = <ShiftModel>[].obs;
  var isLoadingShifts = false.obs;

  var employeeShifts = <EmployeeShiftModel>[].obs;
  var isLoadingEmployeeShifts = false.obs;

  var weeklyPatterns = <WeeklyPatternModel>[].obs;
  var isLoadingPatterns = false.obs;

  // Dropdown lists
  var companiesList = <Map<String, dynamic>>[].obs;
  var employeesList = <Map<String, dynamic>>[].obs;
  var shiftsList = <Map<String, dynamic>>[].obs;
  var patternsList = <Map<String, dynamic>>[].obs;

  // Filter master shift
  var filterIsActive = Rxn<bool>();
  var searchQuery = ''.obs;

  var isExporting = false.obs;
  var isImporting = false.obs;

  String _baseUrl = '';

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  @override
  void onInit() {
    super.onInit();
    _initBaseUrl();
  }

  Future<void> _initBaseUrl() async {
    _baseUrl = await AppConfig.getBaseUrl();
    await Future.wait([fetchShifts(), fetchCompanies()]);
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_auth.token.value}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ── SHIFTS ─────────────────────────────────────────────────────────────────

  Future<void> fetchShifts() async {
    isLoadingShifts.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      final params = <String, String>{};
      if (filterIsActive.value != null)
        params['is_active'] = filterIsActive.value! ? '1' : '0';
      if (searchQuery.value.isNotEmpty) params['search'] = searchQuery.value;

      final uri = Uri.parse(
        '$baseUrl/admin/shifts',
      ).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] ?? data) as List;
        shifts.value = list.map((e) => ShiftModel.fromJson(e)).toList();
      }
    } catch (e) {
      _showError('Gagal memuat data shift: $e');
    } finally {
      isLoadingShifts.value = false;
    }
  }

  Future<bool> createShift(Map<String, dynamic> payload) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/shifts'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  Future<bool> updateShift(int id, Map<String, dynamic> payload) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .put(
            Uri.parse('$baseUrl/admin/shifts/$id'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  Future<bool> deleteShift(int id) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .delete(Uri.parse('$baseUrl/admin/shifts/$id'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        _showSuccess('Shift berhasil dihapus');
        shifts.removeWhere((s) => s.id == id);
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  // Tambah di ShiftController — bulk assign dengan progress callback
  Future<Map<String, dynamic>> bulkAssignShift({
    required List<int> employeeIds,
    required Map<String, dynamic> basePayload,
    void Function(int done, int total)? onProgress,
  }) async {
    try {
      final baseUrl = await _resolvedBaseUrl;

      // Gunakan endpoint bulk jika shift langsung (bukan pattern)
      // karena bulkStore backend hanya support shift_id
      if (basePayload.containsKey('shift_id')) {
        final payload = {'employee_ids': employeeIds, ...basePayload};
        final response = await http
            .post(
              Uri.parse('$baseUrl/admin/employee-shifts/bulk'),
              headers: _headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final inserted = data['data']?['inserted'] ?? employeeIds.length;
          final skipped = data['data']?['skipped'] ?? 0;
          await fetchEmployeeShifts();
          return {'success': inserted, 'failed': 0, 'skipped': skipped};
        }
        _handleError(response);
        return {'success': 0, 'failed': employeeIds.length, 'skipped': 0};
      }

      // Fallback loop untuk pattern_id (belum ada bulk endpoint)
      int success = 0;
      int failed = 0;
      for (int i = 0; i < employeeIds.length; i++) {
        final payload = {...basePayload, 'employee_id': employeeIds[i]};
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/admin/employee-shifts'),
                headers: _headers,
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 15));
          if (response.statusCode == 200 || response.statusCode == 201) {
            success++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
        onProgress?.call(i + 1, employeeIds.length);
      }
      if (success > 0) await fetchEmployeeShifts();
      return {'success': success, 'failed': failed, 'skipped': 0};
    } catch (e) {
      _showError('Koneksi error: $e');
      return {'success': 0, 'failed': employeeIds.length, 'skipped': 0};
    }
  }

  // ── EMPLOYEE SHIFTS ────────────────────────────────────────────────────────

  Future<void> fetchEmployeeShifts({int? employeeId}) async {
    isLoadingEmployeeShifts.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      final params = <String, String>{};
      if (employeeId != null) params['employee_id'] = employeeId.toString();

      final uri = Uri.parse(
        '$baseUrl/admin/employee-shifts',
      ).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] ?? data) as List;
        employeeShifts.value = list
            .map((e) => EmployeeShiftModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      _showError('Gagal memuat data: $e');
    } finally {
      isLoadingEmployeeShifts.value = false;
    }
  }

  Future<bool> assignShift(Map<String, dynamic> payload) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/employee-shifts'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Shift berhasil di-assign');
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  Future<bool> updateEmployeeShift(int id, Map<String, dynamic> payload) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .put(
            Uri.parse('$baseUrl/admin/employee-shifts/$id'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        _showSuccess('Assignment shift berhasil diperbarui');
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  Future<bool> deleteEmployeeShift(int id) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/employee-shifts/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        _showSuccess('Assignment shift berhasil dihapus');
        employeeShifts.removeWhere((s) => s.id == id);
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  // ── WEEKLY PATTERNS ────────────────────────────────────────────────────────

  Future<void> fetchWeeklyPatterns() async {
    isLoadingPatterns.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(Uri.parse('$baseUrl/admin/shift-patterns'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] ?? data) as List;
        weeklyPatterns.value = list
            .map((e) => WeeklyPatternModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      _showError('Gagal memuat pola shift: $e');
    } finally {
      isLoadingPatterns.value = false;
    }
  }

  Future<bool> createWeeklyPattern(Map<String, dynamic> payload) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/shift-patterns'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        // JANGAN await fetchWeeklyPatterns() di sini
        // biarkan caller yang handle refresh setelah dialog tutup
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  Future<bool> updateWeeklyPattern(int id, Map<String, dynamic> payload) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .put(
            Uri.parse('$baseUrl/admin/shift-patterns/$id'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  Future<bool> deleteWeeklyPattern(int id) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/shift-patterns/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        _showSuccess('Pola shift berhasil dihapus');
        weeklyPatterns.removeWhere((p) => p.id == id);
        return true;
      }
      _handleError(response);
      return false;
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    }
  }

  // ── DROPDOWN ───────────────────────────────────────────────────────────────

  Future<void> fetchCompanies() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(Uri.parse('$baseUrl/admin/companies-list'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        companiesList.value = List<Map<String, dynamic>>.from(
          data['data'] ?? data,
        );
      }
    } catch (_) {}
  }

  Future<void> fetchEmployeesDropdown() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/employees-dropdown'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        employeesList.value = List<Map<String, dynamic>>.from(
          data['data'] ?? [],
        );
      }
    } catch (_) {}
  }

  Future<void> fetchShiftsDropdown() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(Uri.parse('$baseUrl/admin/shifts-list'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        shiftsList.value = List<Map<String, dynamic>>.from(
          data['data'] ?? data,
        );
      }
    } catch (_) {}
  }

  Future<void> fetchPatternsDropdown() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/shift-patterns-list'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        patternsList.value = List<Map<String, dynamic>>.from(
          data['data'] ?? data,
        );
      }
    } catch (_) {}
  }

  Future<WeeklyPatternModel?> fetchWeeklyPatternDetail(int id) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/shift-patterns/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final json = data['data'] ?? data;
        return WeeklyPatternModel.fromJson(json);
      }
      _handleError(response);
      return null;
    } catch (e) {
      _showError('Gagal memuat detail: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // EXPORT
  // ─────────────────────────────────────────────────────────

  Future<void> exportShifts() async {
    isExporting.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/shifts/export'),
            headers: {
              'Authorization': 'Bearer ${_auth.token.value}',
              'Accept':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            },
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final dir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download')
            : await getApplicationDocumentsDirectory();

        if (!await dir.exists()) await dir.create(recursive: true);

        final filename = 'shifts_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        Get.snackbar(
          'Export Berhasil',
          'File disimpan: ${file.path}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => OpenFile.open(file.path),
            child: const Text('Buka', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        _showError('Gagal export (${response.statusCode})');
      }
    } on TimeoutException {
      _showError('Export timeout. Coba lagi.');
    } catch (e) {
      _showError('Export error: $e');
    } finally {
      isExporting.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // DOWNLOAD TEMPLATE
  // ─────────────────────────────────────────────────────────

  Future<void> downloadImportTemplate() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/shifts/import-template'),
            headers: {
              'Authorization': 'Bearer ${_auth.token.value}',
              'Accept':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download')
            : await getApplicationDocumentsDirectory();

        if (!await dir.exists()) await dir.create(recursive: true);

        final file = File('${dir.path}/template_import_shifts.xlsx');
        await file.writeAsBytes(response.bodyBytes);

        Get.snackbar(
          'Template Diunduh',
          'File: ${file.path}',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => OpenFile.open(file.path),
            child: const Text('Buka', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        _showError('Gagal mengunduh template');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // IMPORT
  // ─────────────────────────────────────────────────────────

  Future<void> importShifts() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        final status = await Permission.storage.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          _showError('Izin akses storage diperlukan');
          return;
        }
      }
    }

    Uint8List? fileBytes;
    String fileName = 'import.xlsx';

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      fileName = pickedFile.name;

      if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
        fileBytes = pickedFile.bytes!;
      } else if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        if (await file.exists()) fileBytes = await file.readAsBytes();
      }
    } catch (e) {
      _showError(
        'Gagal membaca file.\n\nPastikan file disimpan di storage lokal HP, bukan Google Drive atau cloud storage.',
      );
      return;
    }

    if (fileBytes == null || fileBytes.isEmpty) {
      _showError(
        'Tidak bisa membaca file. Simpan file ke storage lokal HP terlebih dahulu.',
      );
      return;
    }

    final ext = fileName.split('.').last.toLowerCase();
    if (!['xlsx', 'xls'].contains(ext)) {
      _showError('Format file tidak didukung. Gunakan file .xlsx atau .xls');
      return;
    }

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Color(0xFF0288D1)),
            SizedBox(width: 10),
            Text(
              'Import Shift',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: $fileName',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data dari file akan ditambahkan ke database.\nPastikan format file sesuai template.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    isImporting.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/shifts/import'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer ${_auth.token.value}',
        'Accept': 'application/json',
      });
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final errList = (data['errors'] as List?)?.cast<String>() ?? [];
        final success = data['success'] ?? 0;
        final failed = data['failed'] ?? 0;

        await Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  failed == 0
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: failed == 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Hasil Import',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _importResultRow(
                  Icons.check_circle_outline,
                  Colors.green,
                  'Berhasil: $success data',
                ),
                if (failed > 0)
                  _importResultRow(
                    Icons.error_outline,
                    Colors.red,
                    'Gagal: $failed data',
                  ),
                if (errList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Detail error:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: errList
                            .map(
                              (e) => Text(
                                '• $e',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );

        if (success > 0) await fetchShifts();
      } else {
        String msg = data['message'] ?? 'Gagal import';
        if (data['errors'] != null) {
          final errs = data['errors'] as Map;
          final first = errs.values.first;
          msg = (first is List) ? first.first.toString() : first.toString();
        }
        _showError(msg);
      }
    } on TimeoutException {
      _showError('Import timeout. Coba lagi.');
    } catch (e) {
      _showError('Import error: $e');
    } finally {
      isImporting.value = false;
    }
  }

  Widget _importResultRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  void _handleError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      String msg =
          data['message'] ?? 'Terjadi kesalahan (${response.statusCode})';
      if (data['errors'] != null) {
        final errs = data['errors'] as Map;
        msg = errs.values.map((v) => v is List ? v.first : v).join('\n');
      }
      _showError(msg);
    } catch (_) {
      _showError('Terjadi kesalahan (${response.statusCode})');
    }
  }

  void _showSuccess(String msg) => Get.snackbar(
    'Berhasil',
    msg,
    backgroundColor: Colors.green,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 2),
  );

  void showSuccessSnackbar(String msg) => _showSuccess(msg);

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    backgroundColor: Colors.red,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 3),
  );
}
