import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'dart:io';

class AuthController extends GetxController {
  static AuthController instance = Get.find();

  final box = GetStorage();

  var isLoading = false.obs;
  var token = ''.obs;
  var user = {}.obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initBaseUrl();
    _loadStoredData();
    // Refresh profile jika sudah login
    if (token.isNotEmpty) {
      fetchProfile(); // ← tambahkan ini
    }
  }

  Future<void> fetchProfile() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/user/profil'), // atau endpoint profile Anda
        headers: {
          'Authorization': 'Bearer ${token.value}',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        user.value = data['data']; // sesuai response ProfileController
        await box.write('user', user.value);
      }
    } catch (e) {
      print('fetchProfile error: $e');
    }
  }

  Future<void> _initBaseUrl() async {
    _baseUrl = await AppConfig.getBaseUrl();
  }

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  void _loadStoredData() {
    token.value = box.read('token') ?? '';
    user.value = box.read('user') ?? {};
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    isLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Register attempt: $name, $email, $role');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Berhasil',
          data['message'] ?? 'Register berhasil',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );

        Get.offAllNamed('/login');
      } else {
        String errorMessage = data['message'] ?? 'Register gagal';

        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first;
          }
        }

        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Register error: $e');
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Login attempt: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        token.value = data['access_token'];
        user.value = data['user'];

        await _saveUserData();

        Get.snackbar(
          'Berhasil',
          'Login berhasil sebagai ${user['role']}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );

        if (isAdmin) {
          Get.offAllNamed('/admin');
        } else {
          Get.offAllNamed('/user');
        }
      } else {
        String errorMessage = data['message'] ?? 'Login gagal';

        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first;
          }
        }

        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('Login error: $e');
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePasswordAdmin({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (token.isEmpty) {
      Get.snackbar(
        'Error',
        'Anda harus login terlebih dahulu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/change-password'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token.value}',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
              'confirm_password': confirmPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          data['message'] ?? 'Password berhasil diubah',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        String errorMessage = data['message'] ?? 'Gagal mengubah password';

        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
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
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      print('Error change password admin: $e');
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (token.isEmpty) {
      Get.snackbar(
        'Error',
        'Anda harus login terlebih dahulu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/user/change-password'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token.value}',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
              'confirm_password': confirmPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          data['message'] ?? 'Password berhasil diubah',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        String errorMessage = data['message'] ?? 'Gagal mengubah password';

        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
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
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      print('Error change password: $e');
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      if (token.isNotEmpty) {
        final baseUrl = await _resolvedBaseUrl;
        print('Logout attempt');
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer ${token.value}',
            'Accept': 'application/json',
          },
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _clearUserData();

      Get.deleteAll();

      Get.offAllNamed('/login');

      Get.snackbar(
        'Berhasil',
        'Berhasil logout',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _saveUserData() async {
    await box.write('token', token.value);
    await box.write('user', user.value);
  }

  Future<void> _clearUserData() async {
    await box.erase();
    token.value = '';
    user.value = {};
  }

  // ─── METHOD BARU: Upload Foto ─────────────────────────────────────────────

  Future<void> uploadPhoto(File imageFile) async {
    isLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;

      // Gunakan multipart request karena kirim file
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/upload-foto'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${token.value}',
        'Accept': 'application/json',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo', // sesuaikan dengan field name di backend
          imageFile.path,
          filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update user map dengan photo_url baru dari response
        final updatedUser = Map<String, dynamic>.from(user.value);
        updatedUser['photo_url'] =
            data['photo_url'] ?? data['data']?['photo_url'];
        user.value = updatedUser;
        await box.write('user', user.value);

        Get.snackbar(
          'Berhasil',
          'Foto profil berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Gagal',
          data['message'] ?? 'Gagal mengupload foto',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('uploadPhoto error: $e');
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePhoto() async {
    isLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .delete(
            Uri.parse('$baseUrl/user/hapus-foto'),
            headers: {
              'Authorization': 'Bearer ${token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final updatedUser = Map<String, dynamic>.from(user.value);
        updatedUser.remove('photo_url');
        user.value = updatedUser;
        await box.write('user', user.value);

        Get.snackbar(
          'Berhasil',
          'Foto profil berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('deletePhoto error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool get isLoggedIn => token.isNotEmpty;

  bool get isAdmin {
    if (user.isEmpty) return false;
    return user['role'] == 'admin';
  }

  bool get isUser {
    if (user.isEmpty) return false;
    return user['role'] == 'user';
  }

  String get userName {
    if (user.isEmpty) return '';
    return user['name'] ?? '';
  }

  String get userEmail {
    if (user.isEmpty) return '';
    return user['email'] ?? '';
  }

  String get userRole {
    if (user.isEmpty) return '';
    return user['role'] ?? '';
  }
}
