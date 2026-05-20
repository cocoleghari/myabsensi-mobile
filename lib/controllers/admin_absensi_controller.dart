import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'auth_controller.dart';

class AdminAbsensiController extends GetxController {
  final auth = Get.find<AuthController>();

  var semuaAbsensi = <Map<String, dynamic>>[].obs;
  // FIXED: renamed semuaUsers → semuaEmployees, tipe sama
  var semuaEmployees = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isLoadingEmployees = false.obs;
  var errorMessage = ''.obs;

  // FIXED: filter pakai employee_id, bukan user_id
  var selectedEmployeeId = ''.obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initBaseUrl();
  }

  Future<void> _initBaseUrl() async {
    _baseUrl = await AppConfig.getBaseUrl();
  }

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  // =========================================================================
  // FETCH EMPLOYEES (dropdown filter)
  // FIXED: endpoint /admin/users/all → /admin/employees
  // =========================================================================

  Future<void> fetchAllEmployees() async {
    if (auth.token.isEmpty) {
      errorMessage.value = 'Token tidak ditemukan';
      return;
    }

    isLoadingEmployees.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;

      // FIXED: endpoint lama /admin/users/all → /admin/employees
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/employees'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          semuaEmployees.value = List<Map<String, dynamic>>.from(data['data']);
        } else {
          semuaEmployees.value = [];
        }
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Sesi habis, silahkan login ulang';
        Get.snackbar(
          'Sesi Habis',
          'Silahkan login ulang',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        Future.delayed(const Duration(seconds: 2), () => auth.logout());
      } else {
        errorMessage.value = 'Gagal memuat data karyawan';
      }
    } catch (e) {
      errorMessage.value = 'Gagal memuat data karyawan';
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  // =========================================================================
  // FETCH ABSENSI
  // FIXED: filter pakai employee_id (bukan user_id)
  // =========================================================================

  Future<void> fetchAllAbsensi({
    String? tanggal,
    String? bulan,
    String? tahun,
    String? status,
  }) async {
    if (auth.token.isEmpty) {
      errorMessage.value = 'Token tidak ditemukan';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final baseUrl = await _resolvedBaseUrl;

      // Build query params
      final params = <String, String>{};

      // FIXED: filter key employee_id bukan user_id
      if (selectedEmployeeId.value.isNotEmpty) {
        params['employee_id'] = selectedEmployeeId.value;
      }
      if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
      if (bulan != null && bulan.isNotEmpty) params['bulan'] = bulan;
      if (tahun != null && tahun.isNotEmpty) params['tahun'] = tahun;
      if (status != null && status.isNotEmpty) params['status'] = status;

      final uri = Uri.parse(
        '$baseUrl/admin/absensi/all',
      ).replace(queryParameters: params.isNotEmpty ? params : null);

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          semuaAbsensi.value = List<Map<String, dynamic>>.from(data['data']);
        } else {
          semuaAbsensi.value = [];
        }
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Sesi habis, silahkan login ulang';
        Get.snackbar(
          'Sesi Habis',
          'Silahkan login ulang',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        Future.delayed(const Duration(seconds: 2), () => auth.logout());
      } else {
        errorMessage.value = 'Error ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Gagal memuat data absensi';
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // DELETE ABSENSI
  // =========================================================================

  Future<bool> deleteAbsensi(int id) async {
    if (auth.token.isEmpty) {
      Get.snackbar(
        'Error',
        'Token tidak ditemukan',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/absensi/$id'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Hapus dari list lokal agar tidak perlu fetch ulang
        semuaAbsensi.removeWhere((a) => a['id'] == id);
        return true;
      } else if (response.statusCode == 401) {
        Get.snackbar(
          'Sesi Habis',
          'Silahkan login ulang',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        Future.delayed(const Duration(seconds: 2), () => auth.logout());
        return false;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          Get.snackbar(
            'Gagal',
            errorData['message'] ?? 'Gagal menghapus absensi',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } catch (_) {
          Get.snackbar(
            'Gagal',
            'Error ${response.statusCode}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // =========================================================================
  // FILTER HELPERS
  // FIXED: pakai employee_id dan field full_name/nickname dari Employee model
  // =========================================================================

  void filterByEmployee(String employeeId) {
    selectedEmployeeId.value = employeeId;
    fetchAllAbsensi();
  }

  void resetFilter() {
    selectedEmployeeId.value = '';
    fetchAllAbsensi();
  }

  // FIXED: cari berdasarkan employee id (int), return full_name
  String getEmployeeNameById(int employeeId) {
    try {
      final emp = semuaEmployees.firstWhere(
        (e) => e['id'] == employeeId,
        orElse: () => {},
      );
      if (emp.isEmpty) return 'Unknown';
      // FIXED: field full_name dari Employee model, bukan name dari User
      return emp['full_name'] ?? emp['nickname'] ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  // Helper: ambil nama dari nested employee object di dalam absensi
  String getEmployeeNameFromAbsensi(Map<String, dynamic> absensi) {
    try {
      final emp = absensi['employee'];
      if (emp == null) return 'Unknown';
      return emp['full_name'] ?? emp['nickname'] ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  // Helper: ambil nama lokasi dari nested pusat_lokasi
  String getLokasiNameFromAbsensi(Map<String, dynamic> absensi) {
    try {
      final lok = absensi['pusat_lokasi'];
      if (lok == null) return '-';
      return lok['nama_lokasi'] ?? '-';
    } catch (_) {
      return '-';
    }
  }

  // =========================================================================
  // FORMAT WAKTU
  // =========================================================================

  String formatWaktu(String waktuStr) {
    try {
      if (waktuStr.isEmpty) return '-';

      if (waktuStr.contains('T')) {
        final parts = waktuStr.split('T');
        String tanggal = parts[0];
        final tglParts = tanggal.split('-');
        if (tglParts.length == 3) {
          tanggal = '${tglParts[2]}-${tglParts[1]}-${tglParts[0]}';
        }
        String jam = parts[1]
            .replaceAll(RegExp(r'\..*$'), '')
            .replaceAll(RegExp(r'Z$'), '');
        if (jam.contains(':')) {
          final jamParts = jam.split(':');
          if (jamParts.length >= 2) jam = '${jamParts[0]}:${jamParts[1]}';
        }
        return '$tanggal $jam';
      }

      if (waktuStr.contains(' ')) {
        final parts = waktuStr.split(' ');
        if (parts.length >= 2) {
          String tanggal = parts[0];
          final tglParts = tanggal.split('-');
          if (tglParts.length == 3) {
            tanggal = '${tglParts[2]}-${tglParts[1]}-${tglParts[0]}';
          }
          String jam = parts[1];
          if (jam.contains(':')) {
            final jamParts = jam.split(':');
            if (jamParts.length >= 2) jam = '${jamParts[0]}:${jamParts[1]}';
          }
          return '$tanggal $jam';
        }
      }
      return waktuStr;
    } catch (_) {
      return waktuStr;
    }
  }

  // =========================================================================
  // STATISTICS
  // =========================================================================

  var statistics = <String, dynamic>{}.obs;
  var isLoadingStatistics = false.obs;

  Future<void> fetchStatistics() async {
    if (auth.token.isEmpty) return;

    isLoadingStatistics.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/absensi/statistics'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        statistics.value = Map<String, dynamic>.from(data['data'] ?? {});
      }
    } catch (e) {
      // silent fail
    } finally {
      isLoadingStatistics.value = false;
    }
  }

  // =========================================================================
  // MISC
  // =========================================================================

  int getUniqueDatesCount() {
    try {
      final dates = <String>{};
      for (var item in semuaAbsensi) {
        final waktu = item['waktu_absen']?.toString() ?? '';
        if (waktu.contains('T')) {
          dates.add(waktu.split('T')[0]);
        } else if (waktu.contains(' ')) {
          dates.add(waktu.split(' ')[0]);
        }
      }
      return dates.length;
    } catch (_) {
      return 0;
    }
  }

  void reset() {
    semuaAbsensi.clear();
    semuaEmployees.clear();
    errorMessage.value = '';
    isLoading.value = false;
    isLoadingEmployees.value = false;
    selectedEmployeeId.value = '';
    statistics.clear();
  }
}
