import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_controller.dart';
import 'app_config.dart';

class EmployeeStatusController extends GetxController {
  final authController = Get.find<AuthController>();

  var isLoading = false.obs;
  var statuses = <Map<String, dynamic>>[].obs;
  var searchQuery = ''.obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    _baseUrl = await AppConfig.getBaseUrl();
    await fetchStatuses();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FETCH LIST
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> fetchStatuses() async {
    isLoading.value = true;
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/employee-statuses'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        statuses.value = List<Map<String, dynamic>>.from(data);
      } else {
        _showError('Gagal memuat data status karyawan.');
      }
    } catch (e) {
      _showError('Koneksi error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CREATE
  // ───────────────────────────────────────────────────────────────────────────
  Future<bool> createStatus({
    required String code,
    required String label,
    required String color,
    required bool isActive,
    required bool isVisible,
    required int sortOrder,
  }) async {
    isLoading.value = true;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/employee-statuses'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'label': label,
              'color': color,
              'is_active': isActive,
              'is_visible': isVisible,
              'sort_order': sortOrder,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        _showSuccess(data['message'] ?? 'Status berhasil ditambahkan.');
        await fetchStatuses();
        return true;
      } else {
        _showError(data['message'] ?? 'Gagal menambah status.');
        return false;
      }
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UPDATE
  // ───────────────────────────────────────────────────────────────────────────
  Future<bool> updateStatus({
    required int id,
    required String code,
    required String label,
    required String color,
    required bool isActive,
    required bool isVisible,
    required int sortOrder,
  }) async {
    isLoading.value = true;
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/admin/employee-statuses/$id'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'label': label,
              'color': color,
              'is_active': isActive,
              'is_visible': isVisible,
              'sort_order': sortOrder,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSuccess(data['message'] ?? 'Status berhasil diperbarui.');
        await fetchStatuses();
        return true;
      } else {
        _showError(data['message'] ?? 'Gagal memperbarui status.');
        return false;
      }
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DELETE
  // ───────────────────────────────────────────────────────────────────────────
  Future<bool> deleteStatus(int id) async {
    isLoading.value = true;
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/admin/employee-statuses/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSuccess(data['message'] ?? 'Status berhasil dihapus.');
        await fetchStatuses();
        return true;
      } else {
        _showError(data['message'] ?? 'Gagal menghapus status.');
        return false;
      }
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FILTERED LIST (untuk search)
  // ───────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get filteredStatuses {
    if (searchQuery.value.isEmpty) return statuses;
    final q = searchQuery.value.toLowerCase();
    return statuses.where((s) {
      return (s['label']?.toString().toLowerCase().contains(q) ?? false) ||
          (s['code']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${authController.token.value}',
    'Accept': 'application/json',
  };

  /// Mapping nama warna (string) ke Color Flutter
  static Color colorFromString(String? colorStr) {
    switch (colorStr?.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.amber;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'gray':
      default:
        return Colors.grey;
    }
  }

  static const List<String> availableColors = [
    'gray',
    'green',
    'blue',
    'red',
    'orange',
    'yellow',
    'purple',
    'pink',
    'teal',
    'indigo',
  ];

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
    snackPosition: SnackPosition.TOP,
  );
}
