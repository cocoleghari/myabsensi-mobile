import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../controllers/auth_controller.dart';
import '../../../controllers/app_config.dart';

class CompanyController extends GetxController {
  final authController = Get.find<AuthController>();

  var isLoading = false.obs;
  var isSaving = false.obs;
  var companies = <Map<String, dynamic>>[].obs;
  var filteredCompanies = <Map<String, dynamic>>[].obs;

  var searchQuery = ''.obs;
  var filterIsActive = Rxn<bool>();

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initAndFetch();
    ever(searchQuery, (_) => _applyFilter());
    ever(filterIsActive, (_) => _applyFilter());
  }

  Future<void> _initAndFetch() async {
    _baseUrl = await AppConfig.getBaseUrl();
    await fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    isLoading.value = true;
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/companies'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        companies.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
        _applyFilter();
      } else {
        _showError('Gagal memuat data company');
      }
    } catch (e) {
      _showError('Koneksi error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilter() {
    var result = companies.toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final code = (c['code'] ?? '').toString().toLowerCase();
        final city = (c['city'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q) || city.contains(q);
      }).toList();
    }
    if (filterIsActive.value != null) {
      result = result
          .where((c) => c['is_active'] == filterIsActive.value)
          .toList();
    }
    filteredCompanies.value = result;
  }

  void setSearch(String q) => searchQuery.value = q;
  void setFilterActive(bool? val) => filterIsActive.value = val;

  Future<bool> createCompany(Map<String, dynamic> body) async {
    isSaving.value = true;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/companies'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        // ✅ Set false DULU sebelum fetch & snackbar
        isSaving.value = false;
        _showSuccess(data['message'] ?? 'Company berhasil dibuat');
        await fetchCompanies();
        return true;
      } else {
        _showValidationError(data);
        return false;
      }
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateCompany(int id, Map<String, dynamic> body) async {
    isSaving.value = true;
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/admin/companies/$id'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // ✅ Set false DULU sebelum fetch & snackbar
        isSaving.value = false;
        _showSuccess(data['message'] ?? 'Company berhasil diperbarui');
        await fetchCompanies();
        return true;
      } else {
        _showValidationError(data);
        return false;
      }
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCompany(int id, String name) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Company',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus company "$name"?\n\nCompany tidak dapat dihapus jika masih memiliki department atau karyawan.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/admin/companies/$id'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSuccess(data['message'] ?? 'Company berhasil dihapus');
        await fetchCompanies();
      } else {
        _showError(data['message'] ?? 'Gagal menghapus company');
      }
    } catch (e) {
      _showError('Koneksi error: $e');
    }
  }

  void _showSuccess(String msg) => Get.snackbar(
    'Berhasil',
    msg,
    backgroundColor: Colors.green,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
  );

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    backgroundColor: Colors.red,
    colorText: Colors.white,
  );

  void _showValidationError(Map<String, dynamic> data) {
    String msg = data['message'] ?? 'Terjadi kesalahan';
    if (data['errors'] != null) {
      final errors = data['errors'] as Map;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) msg = first.first;
    }
    _showError(msg);
  }
}
