import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'app_config.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  var users = <UserModel>[].obs;
  var isLoading = false.obs;

  final AuthController authController = Get.find<AuthController>();

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

  Map<String, String> get _authHeaders => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${authController.token.value}',
  };

  Future<void> fetchUsers() async {
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
      final res = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: _authHeaders,
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        users.value = (json['data'] as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        Get.snackbar(
          'Sesi Habis',
          'Silahkan login kembali',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        authController.logout();
      } else {
        Get.snackbar('Error', 'Gagal mengambil data user');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      isLoading.value = true;

      final baseUrl = await _resolvedBaseUrl;

      final res = await http.get(
        Uri.parse('$baseUrl/user/karyawan'),
        headers: _authHeaders,
      );

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

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,

    String? nik,
    String? namaStempel,
    DateTime? tglLahir,
    String? jk,
    String? alamat,
    String? jabatan,
    String? kantor,
    DateTime? tglMasuk,
    String? nomorTelp,
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
      print('Register user dengan token: ${authController.token.value}');
      print('User yang login: ${authController.user}');
      print('Data register: name=$name, email=$email, role=$role');

      final res = await http.post(
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

          'nik': nik,
          'nama_stempel': namaStempel,
          'tgl_lahir': formatDate(tglLahir),
          'jk': jk,
          'alamat': alamat,
          'jabatan': jabatan,
          'kantor': kantor,
          'tgl_masuk': formatDate(tglMasuk),
          'nomor_telp': nomorTelp,
        }),
      );

      print('Response status: ${res.statusCode}');
      print('Response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.back();
        Get.snackbar(
          'Berhasil',
          'User $name berhasil didaftarkan sebagai $role',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        fetchUsers();
      } else {
        final err = jsonDecode(res.body);

        if (res.statusCode == 401 || res.statusCode == 403) {
          Get.snackbar(
            'Error',
            err['message'] ??
                'Anda tidak memiliki izin. Pastikan Anda login sebagai admin.',
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
      print('Attempting to delete user ID: $id');

      final res = await http.delete(
        Uri.parse('$baseUrl/admin/users/$id'),
        headers: _authHeaders,
      );

      print('Response status: ${res.statusCode}');
      print('Response body: ${res.body}');

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

  void printDebugInfo() {
    print('=' * 50);
    print('USER CONTROLLER DEBUG');
    print('BaseUrl: $_baseUrl');
    print('Total users: ${users.length}');
    print('Loading: $isLoading');
    print('Token: ${authController.token.value.isNotEmpty ? "Ada" : "Kosong"}');
    print('=' * 50);
  }

  /// 🔧 HELPER FORMAT DATE
  String? formatDate(DateTime? date) {
    if (date == null) return null;
    return date.toIso8601String().split('T').first;
  }
}
