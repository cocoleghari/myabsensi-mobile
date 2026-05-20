import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'auth_controller.dart';

class JobLevelController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  // ── State ──────────────────────────────────────────────────────────────────
  var jobLevels = <Map<String, dynamic>>[].obs;
  var companies = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var isLoadingCompanies = false.obs;
  var errorMessage = ''.obs;

  // Search
  final searchController = TextEditingController();
  var searchQuery = ''.obs;
  Timer? _debounce;

  // Filter
  var selectedCompanyId = Rx<int?>(null);
  var filterIsActive = Rx<bool?>(null);

  // Pagination
  var currentPage = 1.obs;
  var lastPage = 1.obs;
  var total = 0.obs;

  // ── Form ───────────────────────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final orderController = TextEditingController();
  var formCompanyId = Rx<int?>(null);
  var formIsActive = true.obs;
  var editingId = Rx<int?>(null);

  // ── Helper header ──────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_auth.token.value}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
    fetchAll();

    searchController.addListener(() {
      final q = searchController.text;
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (q != searchQuery.value) {
          searchQuery.value = q;
          fetchAll(page: 1);
        }
      });
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    orderController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  // ── Fetch All ──────────────────────────────────────────────────────────────
  Future<void> fetchAll({int page = 1}) async {
    isLoading(true);
    errorMessage('');
    try {
      final baseUrl = await AppConfig.getBaseUrl();

      final params = <String, String>{'page': '$page', 'per_page': '15'};
      if (searchQuery.value.trim().isNotEmpty) {
        params['search'] = searchQuery.value.trim();
      }
      if (selectedCompanyId.value != null) {
        params['company_id'] = '${selectedCompanyId.value}';
      }
      if (filterIsActive.value != null) {
        params['is_active'] = filterIsActive.value! ? '1' : '0';
      }

      final uri = Uri.parse(
        '$baseUrl/admin/job-levels',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] ?? data;
        jobLevels.value = List<Map<String, dynamic>>.from(list);
        currentPage.value = data['current_page'] ?? 1;
        lastPage.value = data['last_page'] ?? 1;
        total.value = data['total'] ?? jobLevels.length;
      } else if (response.statusCode == 401) {
        await _auth.logout();
      } else {
        errorMessage('Gagal memuat data (${response.statusCode})');
      }
    } catch (e) {
      errorMessage('Koneksi error: $e');
      debugPrint('fetchAll job-levels error: $e');
    } finally {
      isLoading(false);
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchAll(page: 1);
  }

  // ── Fetch Companies ────────────────────────────────────────────────────────
  Future<void> fetchCompanies() async {
    isLoadingCompanies(true);
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final endpoints = [
        '$baseUrl/admin/companies-list',
        '$baseUrl/admin/companies',
      ];

      for (final url in endpoints) {
        try {
          final response = await http
              .get(Uri.parse(url), headers: _headers)
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            List<dynamic> list;
            if (decoded is List) {
              list = decoded;
            } else if (decoded is Map && decoded.containsKey('data')) {
              list = decoded['data'] as List;
            } else {
              continue;
            }
            companies.value = List<Map<String, dynamic>>.from(list);
            return;
          } else if (response.statusCode == 401) {
            await _auth.logout();
            return;
          }
        } catch (e) {
          debugPrint('fetchCompanies error pada $url: $e');
        }
      }
    } finally {
      isLoadingCompanies(false);
    }
  }

  // ── Create / Update ────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (formCompanyId.value == null) {
      Get.snackbar(
        'Error',
        'Pilih perusahaan terlebih dahulu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isSubmitting(true);
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final body = jsonEncode({
        'company_id': formCompanyId.value,
        'name': nameController.text.trim(),
        'order': int.tryParse(orderController.text.trim()) ?? 0,
        'description': descriptionController.text.trim(),
        'is_active': formIsActive.value,
      });

      final http.Response response;
      if (editingId.value == null) {
        response = await http
            .post(
              Uri.parse('$baseUrl/admin/job-levels'),
              headers: _headers,
              body: body,
            )
            .timeout(const Duration(seconds: 15));
      } else {
        response = await http
            .put(
              Uri.parse('$baseUrl/admin/job-levels/${editingId.value}'),
              headers: _headers,
              body: body,
            )
            .timeout(const Duration(seconds: 15));
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar(
          'Berhasil',
          editingId.value == null
              ? 'Job Level berhasil ditambahkan'
              : 'Job Level berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchAll(page: currentPage.value);
      } else {
        String msg = data['message'] ?? 'Gagal menyimpan';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          final first = errors.values.first;
          msg = (first is List) ? first.first.toString() : first.toString();
        }
        Get.snackbar(
          'Gagal',
          msg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting(false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> delete(int id) async {
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http
          .delete(Uri.parse('$baseUrl/admin/job-levels/$id'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          'Job Level dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchAll(page: currentPage.value);
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          data['message'] ?? 'Gagal menghapus',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void confirmDelete(int id, String name) {
    Get.defaultDialog(
      title: 'Hapus Job Level',
      middleText: 'Hapus "$name"?\nTindakan ini tidak bisa dibatalkan.',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        delete(id);
      },
    );
  }

  // ── Form Helpers ───────────────────────────────────────────────────────────
  void prepareCreate() {
    editingId.value = null;
    nameController.clear();
    descriptionController.clear();
    orderController.text = '0';
    formCompanyId.value = selectedCompanyId.value;
    formIsActive.value = true;
  }

  void prepareEdit(Map<String, dynamic> item) {
    editingId.value = item['id'] as int?;
    nameController.text = item['name']?.toString() ?? '';
    descriptionController.text = item['description']?.toString() ?? '';
    orderController.text = item['order']?.toString() ?? '0';
    formCompanyId.value = item['company_id'] as int?;
    formIsActive.value = item['is_active'] == true || item['is_active'] == 1;
  }

  // ── Filter ─────────────────────────────────────────────────────────────────
  void applyFilter({int? companyId, bool? isActive}) {
    selectedCompanyId.value = companyId;
    filterIsActive.value = isActive;
    fetchAll(page: 1);
  }

  void resetFilter() {
    selectedCompanyId.value = null;
    filterIsActive.value = null;
    fetchAll(page: 1);
  }

  bool get hasActiveFilter =>
      selectedCompanyId.value != null || filterIsActive.value != null;
}
