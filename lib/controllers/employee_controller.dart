import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import 'app_config.dart';
import 'auth_controller.dart';

class EmployeeController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  var employees = <EmployeeModel>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  var currentPage = 1.obs;
  var lastPage = 1.obs;
  var total = 0.obs;

  var searchQuery = ''.obs;
  var filterCompanyId = Rxn<int>();
  var filterDepartmentId = Rxn<int>();
  var filterJobLevelId = Rxn<int>();
  var filterJobGradeId = Rxn<int>();
  var filterEmploymentType = Rxn<String>();

  // Dropdown options
  var companies = <Map<String, dynamic>>[].obs;
  var departments = <Map<String, dynamic>>[].obs;
  var positions = <Map<String, dynamic>>[].obs;
  var jobLevels = <Map<String, dynamic>>[].obs;
  var jobGrades = <Map<String, dynamic>>[].obs;
  var statuses = <Map<String, dynamic>>[].obs;

  var _isLoadingMore = false;
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

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_auth.token.value}',
  };

  Map<String, String> get _jsonHeaders => {
    ..._headers,
    'Content-Type': 'application/json',
  };

  // ─── Fetch List ──────────────────────────────────

  Future<void> fetchEmployees({bool reset = false}) async {
    if (reset) {
      currentPage.value = 1;
      employees.clear();
    }

    try {
      isLoading.value = true;
      final baseUrl = await _resolvedBaseUrl;

      final params = <String, String>{
        'page': currentPage.value.toString(),
        if (searchQuery.isNotEmpty) 'search': searchQuery.value,
        if (filterCompanyId.value != null)
          'company_id': filterCompanyId.value.toString(),
        if (filterDepartmentId.value != null)
          'department_id': filterDepartmentId.value.toString(),
        if (filterJobLevelId.value != null)
          'job_level_id': filterJobLevelId.value.toString(),
        if (filterJobGradeId.value != null)
          'job_grade_id': filterJobGradeId.value.toString(),
        if (filterEmploymentType.value != null)
          'employment_type': filterEmploymentType.value!,
      };

      final uri = Uri.parse(
        '$baseUrl/admin/employees',
      ).replace(queryParameters: params);
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = (json['data'] as List)
            .map((e) => EmployeeModel.fromJson(e))
            .toList();

        if (reset) {
          employees.value = list;
        } else {
          employees.addAll(list);
        }

        lastPage.value = json['meta']['last_page'] ?? 1;
        total.value = json['meta']['total'] ?? 0;
      } else {
        _handleError(res);
      }
    } catch (e) {
      if (!Get.isSnackbarOpen) {
        debugPrint('fetchEmployees error: $e');
        Get.snackbar(
          'Error',
          'Tidak dapat terhubung ke server',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    if (currentPage.value < lastPage.value && !isLoading.value) {
      _isLoadingMore = true;
      currentPage.value++;
      await fetchEmployees();
      _isLoadingMore = false;
    }
  }

  // ─── Fetch Single ────────────────────────────────

  Future<EmployeeModel?> fetchEmployee(int id) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final res = await http
          .get(Uri.parse('$baseUrl/admin/employees/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return EmployeeModel.fromJson(json['data']);
      }
    } catch (e) {
      debugPrint('fetchEmployee error: $e');
    }
    return null;
  }

  // ─── Fetch Options ───────────────────────────────

  Future<void> fetchOptions() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final res = await http
          .get(Uri.parse('$baseUrl/admin/employees/options'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        companies.value = List<Map<String, dynamic>>.from(
          json['companies'] ?? [],
        );
        departments.value = List<Map<String, dynamic>>.from(
          json['departments'] ?? [],
        );
        positions.value = List<Map<String, dynamic>>.from(
          json['positions'] ?? [],
        );
        jobLevels.value = List<Map<String, dynamic>>.from(
          json['job_levels'] ?? [],
        );
        jobGrades.value = List<Map<String, dynamic>>.from(
          json['job_grades'] ?? [],
        );
        statuses.value = List<Map<String, dynamic>>.from(
          json['statuses'] ?? [],
        );

        debugPrint(
          'Options loaded — '
          'companies:${companies.length} departments:${departments.length} '
          'positions:${positions.length} jobLevels:${jobLevels.length} '
          'jobGrades:${jobGrades.length} statuses:${statuses.length}',
        );
      } else {
        _handleError(res);
      }
    } catch (e) {
      debugPrint('fetchOptions error: $e');
    }
  }

  // ─── CRUD ────────────────────────────────────────

  Future<bool> createEmployee(Map<String, dynamic> payload) async {
    try {
      isSubmitting.value = true;
      final baseUrl = await _resolvedBaseUrl;
      final res = await http
          .post(
            Uri.parse('$baseUrl/admin/employees'),
            headers: _jsonHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 201) {
        Get.snackbar(
          'Berhasil',
          'Karyawan berhasil ditambahkan',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchEmployees(reset: true);
        return true;
      } else {
        _handleError(res);
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateEmployee(int id, Map<String, dynamic> payload) async {
    try {
      isSubmitting.value = true;
      final baseUrl = await _resolvedBaseUrl;
      final res = await http
          .put(
            Uri.parse('$baseUrl/admin/employees/$id'),
            headers: _jsonHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          'Data karyawan berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchEmployees(reset: true);
        return true;
      } else {
        _handleError(res);
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final res = await http
          .delete(Uri.parse('$baseUrl/admin/employees/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          'Karyawan berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        employees.removeWhere((e) => e.id == id);
        total.value = (total.value - 1).clamp(0, 99999);
      } else {
        _handleError(res);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ─── Helpers ─────────────────────────────────────

  void applySearch(String q) {
    searchQuery.value = q;
    fetchEmployees(reset: true);
  }

  void applyFilter({
    int? companyId,
    int? departmentId,
    int? jobLevelId,
    int? jobGradeId,
    String? employmentType,
  }) {
    filterCompanyId.value = companyId;
    filterDepartmentId.value = departmentId;
    filterJobLevelId.value = jobLevelId;
    filterJobGradeId.value = jobGradeId;
    filterEmploymentType.value = employmentType;
    fetchEmployees(reset: true);
  }

  void clearFilters() {
    searchQuery.value = '';
    filterCompanyId.value = null;
    filterDepartmentId.value = null;
    filterJobLevelId.value = null;
    filterJobGradeId.value = null;
    filterEmploymentType.value = null;
    fetchEmployees(reset: true);
  }

  void _handleError(http.Response res) {
    try {
      final err = jsonDecode(res.body);
      String msg = err['message'] ?? 'Terjadi kesalahan';
      if (err['errors'] != null) {
        final errors = err['errors'] as Map;
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) msg = first.first;
      }
      Get.snackbar(
        'Gagal',
        msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Status ${res.statusCode}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
