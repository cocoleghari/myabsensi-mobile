import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'app_config.dart';
import 'auth_controller.dart';

/// Controller untuk manajemen User (akun login) oleh admin.
///
/// Catatan penting setelah refactor:
/// - [fetchUsers]    → GET /admin/users  → hanya return data tabel users
///                     (id, name, email, role, is_active)
/// - [fetchAllUsers] → GET /user/karyawan → list karyawan dari tabel employees
///                     (untuk fitur direktori karyawan di sisi user)
/// - [registerUser]  → POST /register → hanya kirim name, email, password, role
///                     Data karyawan (NIK, jabatan, dll) dikelola terpisah
///                     via halaman manajemen karyawan (Employee)
/// - [deleteUser]    → DELETE /admin/users/{id}
class UserController extends GetxController {
  var searchQuery = ''.obs; // simpan semua data asli

  var users = <UserModel>[].obs;
  var isLoading = false.obs;

  final AuthController authController = Get.find<AuthController>();

  // Tambah state pagination
  final RxBool isFetchingMore = false.obs;
  int _currentPage = 1;
  int _lastPage = 1;
  bool get hasMore => _currentPage <= _lastPage;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initBaseUrl().then((_) => fetchUsers());
  }

  Future<void> _initBaseUrl() async {
    _baseUrl = await AppConfig.getBaseUrl();
  }

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  Map<String, String> get _authHeaders => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${authController.token.value}',
  };

  // ===========================================================================
  // FETCH USERS (Admin)
  // GET /admin/users
  // Return: id, name, email, role, is_active, created_at
  // (hanya field dari tabel users, tidak include data employee)
  // ===========================================================================

  Future<void> fetchUsers({bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      _lastPage = 1;
      users.clear();
      isLoading.value = true;
    }

    try {
      final baseUrl = await _resolvedBaseUrl;

      // Fetch page pertama — langsung tampil
      final res = await http
          .get(
            Uri.parse('$baseUrl/admin/users?page=1&per_page=25'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final firstPage = (json['data'] as List)
            .map((e) => UserModel.fromJson(e))
            .toList();

        users.addAll(firstPage);
        _lastPage = json['meta']['last_page'] ?? 1;
        isLoading.value = false; // ✅ UI sudah bisa dipakai

        // Load sisa page di background tanpa blocking UI
        _fetchRemainingInBackground(baseUrl);
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        authController.logout();
      }
    } catch (e) {
      debugPrint('fetchUsers error: $e');
      Get.snackbar(
        'Error',
        'Tidak dapat terhubung ke server',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load page 2 dst di background — user tidak perlu scroll
  void _fetchRemainingInBackground(String baseUrl) {
    Future.microtask(() async {
      for (int page = 2; page <= _lastPage; page++) {
        try {
          isFetchingMore.value = true;
          final res = await http
              .get(
                Uri.parse('$baseUrl/admin/users?page=$page&per_page=25'),
                headers: _authHeaders,
              )
              .timeout(const Duration(seconds: 10));

          if (res.statusCode == 200) {
            final json = jsonDecode(res.body);
            final moreUsers = (json['data'] as List)
                .map((e) => UserModel.fromJson(e))
                .toList();
            users.addAll(moreUsers); // ✅ list bertambah otomatis
          } else {
            break; // stop kalau ada error
          }
        } catch (e) {
          debugPrint('background fetch page $page error: $e');
          break;
        }
      }
      isFetchingMore.value = false;
    });
  }

  Future<void> loadMore() async {
    if (!hasMore || isFetchingMore.value || isLoading.value) return;
    await fetchUsers(reset: false);
  }

  // ===========================================================================
  // FETCH ALL KARYAWAN (User/Employee view)
  // GET /user/karyawan
  // Return: data dari tabel employees (direktori karyawan)
  // ===========================================================================

  Future<void> fetchAllUsers() async {
    try {
      isLoading.value = true;

      final baseUrl = await _resolvedBaseUrl;
      final res = await http
          .get(Uri.parse('$baseUrl/user/karyawan'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List;
        users.value = list.map((e) => UserModel.fromJson(e)).toList();
      } else {
        Get.snackbar(
          'Info',
          'Gagal memuat data karyawan (${res.statusCode})',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Tidak dapat terhubung ke server',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // REGISTER USER (Admin)
  // POST /register
  //
  // PERUBAHAN: hanya kirim name, email, password, role.
  // Field lama (nik, nama_stempel, jabatan, kantor, dll) DIHAPUS dari sini
  // karena sudah tidak ada di tabel users — dikelola via Employee management.
  // ===========================================================================

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    // Parameter lama di bawah ini sengaja dihapus:
    // String? nik, String? namaStempel, DateTime? tglLahir, dll.
    // Gunakan EmployeeController untuk mengisi data karyawan setelah akun dibuat.
  }) async {
    try {
      isLoading.value = true;

      if (authController.token.isEmpty) {
        Get.snackbar(
          'Error',
          'Anda harus login sebagai admin',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final baseUrl = await _resolvedBaseUrl;

      final res = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${authController.token.value}',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.back();
        Get.snackbar(
          'Berhasil',
          'Akun $name berhasil dibuat sebagai $role.\n'
              'Lengkapi data karyawan melalui manajemen karyawan.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        fetchUsers();
      } else {
        final err = jsonDecode(res.body);

        if (res.statusCode == 401 || res.statusCode == 403) {
          Get.snackbar(
            'Error',
            err['message'] ?? 'Tidak memiliki izin',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } else {
          String errorMessage = err['message'] ?? 'Register gagal';
          if (err['errors'] != null) {
            final errors = err['errors'] as Map;
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first;
            }
          }
          Get.snackbar(
            'Gagal',
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // DELETE USER (Admin)
  // DELETE /admin/users/{id}
  // ===========================================================================

  Future<void> deleteUser(int id) async {
    try {
      isLoading.value = true;

      if (authController.token.isEmpty) {
        Get.snackbar(
          'Error',
          'Anda harus login sebagai admin',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final baseUrl = await _resolvedBaseUrl;
      final res = await http
          .delete(Uri.parse('$baseUrl/admin/users/$id'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          'User berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        fetchUsers();
      } else {
        final err = jsonDecode(res.body);

        if (res.statusCode == 403) {
          Get.snackbar(
            'Tidak Bisa Hapus',
            err['message'] ?? 'Akun ini tidak dapat dihapus',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        } else {
          Get.snackbar(
            'Gagal',
            err['message'] ?? 'Gagal menghapus user',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // UPDATE USER (Admin)
  // PUT /admin/users/{id}
  // Body: name, email, role, is_active, password (opsional)
  // ===========================================================================

  Future<void> updateUser({
    required int id,
    required String name,
    required String email,
    required String role,
    required bool isActive,
    String? password,
  }) async {
    try {
      isLoading.value = true;

      if (authController.token.isEmpty) {
        Get.snackbar(
          'Error',
          'Anda harus login sebagai admin',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final baseUrl = await _resolvedBaseUrl;

      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'role': role,
        'is_active': isActive ? 1 : 0,
      };

      // Hanya kirim password jika diisi
      if (password != null && password.trim().isNotEmpty) {
        body['password'] = password.trim();
      }

      final res = await http
          .put(
            Uri.parse('$baseUrl/admin/users/$id'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${authController.token.value}',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        Get.back();
        Get.snackbar(
          'Berhasil',
          'Akun $name berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        fetchUsers();
      } else {
        final err = jsonDecode(res.body);

        if (res.statusCode == 401 || res.statusCode == 403) {
          Get.snackbar(
            'Error',
            err['message'] ?? 'Tidak memiliki izin',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } else {
          String errorMessage = err['message'] ?? 'Update gagal';
          if (err['errors'] != null) {
            final errors = err['errors'] as Map;
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first;
            }
          }
          Get.snackbar(
            'Gagal',
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Override users getter dengan filtered list
  List<UserModel> get filteredUsers {
    if (searchQuery.isEmpty) return users.toList();
    final q = searchQuery.value.toLowerCase();
    return users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.role.toLowerCase().contains(q),
        )
        .toList();
  }

  // ===========================================================================
  // DEBUG
  // ===========================================================================

  void printDebugInfo() {
    debugPrint('=' * 50);
    debugPrint('USER CONTROLLER DEBUG');
    debugPrint('BaseUrl: $_baseUrl');
    debugPrint('Total users: ${users.length}');
    debugPrint('Loading: $isLoading');
    debugPrint(
      'Token: ${authController.token.value.isNotEmpty ? "Ada" : "Kosong"}',
    );
    debugPrint('=' * 50);
  }
}
