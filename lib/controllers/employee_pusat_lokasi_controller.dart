import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'auth_controller.dart';

/// Controller untuk manajemen relasi karyawan ↔ pusat lokasi absensi.
/// Menggantikan LokasiController yang lama (endpoint /lokasi sudah dihapus).
///
/// Endpoint baru (semua di bawah /admin/employee-lokasi):
///   GET    /admin/employee-lokasi                  → index
///   POST   /admin/employee-lokasi                  → store
///   PUT    /admin/employee-lokasi/{id}             → update
///   DELETE /admin/employee-lokasi/{id}             → destroy
///   GET    /admin/employee-lokasi/employee/{id}    → byEmployee
///   GET    /admin/employees-list                   → dropdown karyawan
///   POST   /admin/employee-lokasi/cek-duplikat     → cekDuplikat
class EmployeePusatLokasiController extends GetxController {
  final auth = Get.find<AuthController>();

  var employeeLokasis = <Map<String, dynamic>>[].obs;
  var employees = <Map<String, dynamic>>[].obs;
  var pusatLokasis = <Map<String, dynamic>>[].obs;

  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var errorMessage = ''.obs;

  // Filter
  var selectedEmployeeId = Rxn<int>();
  var selectedPusatLokasiId = Rxn<int>();
  var selectedPusatLokasiIds = <int>[].obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initAndLoad();
  }

  // ── Internal (tanpa isLoading) ────────────────────────────────

  // employee_pusat_lokasi_controller.dart

  Future<void> _fetchEmployeeLokasiBare() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final allData = <Map<String, dynamic>>[];
      int page = 1;
      int lastPage = 1;

      do {
        final params = <String, String>{
          'page': page.toString(),
          'per_page': '100',
        };
        if (selectedEmployeeId.value != null)
          params['employee_id'] = selectedEmployeeId.value.toString();
        if (selectedPusatLokasiId.value != null)
          params['pusat_lokasi_id'] = selectedPusatLokasiId.value.toString();

        final uri = Uri.parse(
          '$baseUrl/admin/employee-lokasi',
        ).replace(queryParameters: params);

        final response = await http
            .get(uri, headers: _authHeaders)
            .timeout(const Duration(seconds: 30));

        debugPrint(
          '=== employee-lokasi page $page status: ${response.statusCode}',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> items = data['data'] ?? [];
          allData.addAll(items.map((e) => Map<String, dynamic>.from(e)));

          lastPage = data['meta']?['last_page'] ?? 1;
          debugPrint('=== page $page/$lastPage, loaded ${items.length} items');
        } else {
          debugPrint('=== employee-lokasi error: ${response.body}');
          break;
        }

        page++;
      } while (page <= lastPage);

      employeeLokasis.value = allData;
      debugPrint('=== total employee-lokasi loaded: ${allData.length}');
    } catch (e) {
      errorMessage.value = 'Gagal memuat data: $e';
      debugPrint('=== employee-lokasi exception: $e');
    }
  }

  Future<void> _fetchEmployeesBare() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/employees-list'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      // ✅ Tambah log ini sementara
      debugPrint('=== employees-list status: ${response.statusCode}');
      debugPrint('=== employees-list body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          employees.value = List<Map<String, dynamic>>.from(data['data']);
          debugPrint('=== employees loaded: ${employees.length}');
          debugPrint(
            '=== first employee: ${employees.isNotEmpty ? employees.first : "kosong"}',
          );
        }
      }
    } catch (e) {
      debugPrint('=== employees-list error: $e');
    }
  }

  Future<void> _fetchPusatLokasiBare() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(Uri.parse('$baseUrl/admin/pusat-lokasi'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> rawList = [];
        if (data['data'] is List) {
          rawList = data['data'];
        } else if (data['data'] is Map && data['data']['data'] is List) {
          rawList = data['data']['data'];
        }
        pusatLokasis.value = rawList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _initAndLoad() async {
    _baseUrl = await AppConfig.getBaseUrl();
    if (auth.token.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Serial — satu per satu, tidak paralel
      await _fetchEmployeeLokasiBare();
      await _fetchPusatLokasiBare();
      // _fetchEmployeesBare() DIHAPUS — nama sudah ada di relasi employee
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  Map<String, String> get _authHeaders => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${auth.token}',
  };

  // =========================================================================
  // INDEX — Daftar semua relasi (opsional filter)
  // GET /admin/employee-lokasi
  // =========================================================================

  Future<void> fetchEmployeeLokasi() async {
    if (auth.token.isEmpty) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _fetchEmployeeLokasiBare();
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // STORE — Tambah relasi karyawan ↔ pusat lokasi
  // POST /admin/employee-lokasi
  // =========================================================================

  Future<bool> addEmployeeLokasi({
    required int employeeId,
    required int pusatLokasiId,
    int radiusMeter = 100,
    String? keterangan,
  }) async {
    if (auth.token.isEmpty) return false;

    // Cek duplikat dulu
    final isDuplikat = await cekDuplikat(
      employeeId: employeeId,
      pusatLokasiId: pusatLokasiId,
    );
    if (isDuplikat) {
      Get.snackbar(
        'Gagal',
        'Karyawan ini sudah terdaftar di lokasi tersebut',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    isSubmitting.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/employee-lokasi'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'employee_id': employeeId,
              'pusat_lokasi_id': pusatLokasiId,
              'radius_meter': radiusMeter,
              if (keterangan != null && keterangan.isNotEmpty)
                'keterangan': keterangan,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        await fetchEmployeeLokasi();
        Get.snackbar(
          'Berhasil',
          'Lokasi karyawan berhasil ditambahkan',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
        return false;
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          err['message'] ?? 'Gagal menambahkan lokasi',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Koneksi error: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // =========================================================================
  // UPDATE — Ubah radius / keterangan
  // PUT /admin/employee-lokasi/{id}
  // =========================================================================

  Future<bool> updateEmployeeLokasi({
    required int id,
    int? radiusMeter,
    String? keterangan,
  }) async {
    if (auth.token.isEmpty) return false;

    isSubmitting.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;

      final body = <String, dynamic>{};
      if (radiusMeter != null) body['radius_meter'] = radiusMeter;
      if (keterangan != null) body['keterangan'] = keterangan;

      final response = await http
          .put(
            Uri.parse('$baseUrl/admin/employee-lokasi/$id'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await fetchEmployeeLokasi();
        Get.snackbar(
          'Berhasil',
          'Data lokasi karyawan berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          err['message'] ?? 'Gagal memperbarui',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // =========================================================================
  // DESTROY
  // DELETE /admin/employee-lokasi/{id}
  // =========================================================================

  Future<bool> deleteEmployeeLokasi(int id) async {
    if (auth.token.isEmpty) return false;

    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/employee-lokasi/$id'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        employeeLokasis.removeWhere((e) => e['id'] == id);
        Get.snackbar(
          'Berhasil',
          'Lokasi karyawan berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          err['message'] ?? 'Gagal menghapus',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    }
  }

  // =========================================================================
  // BY EMPLOYEE — Lokasi milik satu karyawan
  // GET /admin/employee-lokasi/employee/{id}
  // =========================================================================

  Future<List<Map<String, dynamic>>> fetchLokasiBySingleEmployee(
    int employeeId,
  ) async {
    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/employee-lokasi/employee/$employeeId'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // =========================================================================
  // CEK DUPLIKAT
  // POST /admin/employee-lokasi/cek-duplikat
  // =========================================================================

  Future<bool> cekDuplikat({
    required int employeeId,
    required int pusatLokasiId,
  }) async {
    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/employee-lokasi/cek-duplikat'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'employee_id': employeeId,
              'pusat_lokasi_id': pusatLokasiId,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // EMPLOYEES LIST (dropdown)
  // GET /admin/employees-list
  // =========================================================================

  Future<void> fetchEmployees() async {
    await _fetchEmployeesBare();
  }

  // =========================================================================
  // PUSAT LOKASI LIST (untuk dropdown form tambah)
  // GET /admin/pusat-lokasi
  // =========================================================================

  Future<void> fetchPusatLokasi() async {
    await _fetchPusatLokasiBare();
  }

  // =========================================================================
  // FILTER HELPERS
  // =========================================================================

  void filterByEmployee(int? employeeId) {
    selectedEmployeeId.value = employeeId;
    fetchEmployeeLokasi();
  }

  void filterByPusatLokasi(int? pusatLokasiId) {
    selectedPusatLokasiId.value = pusatLokasiId;
    fetchEmployeeLokasi();
  }

  void resetFilter() {
    selectedEmployeeId.value = null;
    selectedPusatLokasiId.value = null;
    fetchEmployeeLokasi();
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  void _handleUnauthorized() {
    errorMessage.value = 'Sesi habis, silahkan login ulang';
    Get.snackbar(
      'Sesi Habis',
      'Silahkan login ulang',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    Future.delayed(const Duration(seconds: 2), () => auth.logout());
  }

  /// Nama karyawan dari list employees
  String getEmployeeName(int employeeId) {
    try {
      // ✅ Ambil dari relasi employee yang sudah ada di employeeLokasis
      final lokasi = employeeLokasis.firstWhere(
        (e) => e['employee_id'] == employeeId,
        orElse: () => {},
      );

      if (lokasi.isNotEmpty && lokasi['employee'] != null) {
        final emp = lokasi['employee'] as Map<String, dynamic>;
        return emp['full_name'] ?? emp['nickname'] ?? 'Unknown';
      }

      // Fallback ke employees list jika ada
      final emp = employees.firstWhere(
        (e) => e['id'] == employeeId,
        orElse: () => {},
      );
      return emp.isEmpty
          ? 'Unknown'
          : (emp['full_name'] ?? emp['nickname'] ?? 'Unknown');
    } catch (_) {
      return 'Unknown';
    }
  }

  void reset() {
    employeeLokasis.clear();
    employees.clear();
    pusatLokasis.clear();
    errorMessage.value = '';
    isLoading.value = false;
    isSubmitting.value = false;
    selectedEmployeeId.value = null;
    selectedPusatLokasiId.value = null;
  }
}
