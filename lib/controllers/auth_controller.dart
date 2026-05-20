import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:myabsensi_mobile/controllers/offline_absensi_controller.dart';
import 'app_config.dart';
import 'dart:io';

class AuthController extends GetxController {
  static AuthController instance = Get.find();

  final box = GetStorage();

  var isLoading = false.obs;
  var token = ''.obs;

  // Data user (credentials saja: id, name, email, role, is_active)
  var user = <String, dynamic>{}.obs;

  // Data employee (profil karyawan lengkap, null jika belum dibuat)
  var employee = Rxn<Map<String, dynamic>>();

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initBaseUrl();
    _loadStoredData();
    if (token.isNotEmpty) {
      fetchProfile();
    }
  }

  Future<void> _initBaseUrl() async {
    _baseUrl = await AppConfig.getBaseUrl();
    await box.write('base_url', _baseUrl);
  }

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  void _loadStoredData() {
    token.value = box.read('token') ?? '';
    final userStored = box.read('user');
    if (userStored != null) {
      user.value = Map<String, dynamic>.from(userStored);
    }
    final empStored = box.read('employee');
    if (empStored != null) {
      employee.value = Map<String, dynamic>.from(empStored);
    }
  }

  // ===========================================================================
  // FETCH PROFILE
  // GET /user/profil
  //
  // Response sekarang:
  // {
  //   ...user fields (id, name, email, role, is_active),
  //   employee: { id, employee_code, full_name, nickname, photo_url,
  //               wajah_terdaftar, foto_wajah_url, ... },
  //   foto_wajah_url: '...',
  //   photo_url: '...'
  // }
  // ===========================================================================

  Future<void> fetchProfile() async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/profil'),
            headers: {
              'Authorization': 'Bearer ${token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Simpan user fields (hanya kolom dari tabel users)
        final userFields = <String, dynamic>{};
        for (final key in ['id', 'name', 'email', 'role', 'is_active']) {
          if (data.containsKey(key)) userFields[key] = data[key];
        }
        user.value = userFields;
        await box.write('user', userFields);

        // Simpan employee data (nested object dari relasi)
        if (data['employee'] != null) {
          final empData = Map<String, dynamic>.from(data['employee']);
          // Sertakan foto_wajah_url dari level atas jika ada
          if (data['foto_wajah_url'] != null) {
            empData['foto_wajah_url'] = data['foto_wajah_url'];
          }
          // photo_url dari employee, atau fallback level atas
          if (data['photo_url'] != null && empData['photo_url'] == null) {
            empData['photo_url'] = data['photo_url'];
          }
          employee.value = empData;
          await box.write('employee', empData);
        }
      } else if (response.statusCode == 401) {
        // Token expired, logout
        await logout();
      }
    } catch (e) {
      debugPrint('fetchProfile error: $e');
    }
  }

  // ===========================================================================
  // REGISTER
  // POST /register
  // Body: name, email, password, role
  // (field karyawan seperti nik, jabatan, dll sudah TIDAK dikirim di sini)
  // ===========================================================================

  Future<void> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    isLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Berhasil',
          data['message'] ?? 'Register berhasil',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
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
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // LOGIN
  // POST /login
  //
  // Response:
  // {
  //   access_token, token_type,
  //   user: { id, name, email, role, is_active },
  //   employee: { id, employee_code, full_name, nickname, photo_url,
  //               wajah_terdaftar, department, position, company, ... }
  //              — null jika belum ada profil karyawan
  // }
  // ===========================================================================

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'login': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        token.value = data['access_token'];
        user.value = Map<String, dynamic>.from(data['user'] ?? {});

        // Simpan employee jika ada (bisa null untuk user yang belum punya profil)
        if (data['employee'] != null) {
          employee.value = Map<String, dynamic>.from(data['employee']);
        } else {
          employee.value = null;
        }

        await _saveUserData();

        if (Get.isRegistered<OfflineAbsensiController>()) {
          Get.find<OfflineAbsensiController>().reloadQueue();
        }

        final roleName = user['role']?.toString() ?? '';
        Get.snackbar(
          'Berhasil',
          'Login berhasil sebagai $roleName',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        // Routing berdasarkan role
        if (isAdmin || isSuperAdmin || isHrd) {
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
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // CHANGE PASSWORD — Admin
  // POST /admin/change-password
  // ===========================================================================

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
        );
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
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // CHANGE PASSWORD — User/Karyawan
  // POST /user/change-password
  // ===========================================================================

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
        );
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
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // LOGOUT
  // POST /logout
  // ===========================================================================

  Future<void> logout() async {
    try {
      if (token.isNotEmpty) {
        final baseUrl = await _resolvedBaseUrl;
        await http
            .post(
              Uri.parse('$baseUrl/logout'),
              headers: {
                'Authorization': 'Bearer ${token.value}',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      if (Get.isRegistered<OfflineAbsensiController>()) {
        Get.find<OfflineAbsensiController>().clearMemory();
      }
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

  // ===========================================================================
  // UPLOAD FOTO PROFIL
  // POST /user/upload-foto
  // Response: { message, photo_url }
  // photo_url disimpan di employee.photo_url, bukan user
  // ===========================================================================

  Future<void> uploadPhoto(File imageFile) async {
    isLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
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
          'photo',
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
        // Update photo_url di employee (bukan user, karena sudah pindah ke employees)
        final newPhotoUrl = data['photo_url']?.toString();
        if (newPhotoUrl != null && employee.value != null) {
          final updatedEmployee = Map<String, dynamic>.from(employee.value!);
          updatedEmployee['photo_url'] = newPhotoUrl;
          employee.value = updatedEmployee;
          await box.write('employee', updatedEmployee);
        }

        Get.snackbar(
          'Berhasil',
          'Foto profil berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Gagal',
          data['message'] ?? 'Gagal mengupload foto',
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
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // HAPUS FOTO PROFIL
  // DELETE /user/hapus-foto
  // ===========================================================================

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
        // Hapus photo_url dari employee
        if (employee.value != null) {
          final updatedEmployee = Map<String, dynamic>.from(employee.value!);
          updatedEmployee.remove('photo_url');
          employee.value = updatedEmployee;
          await box.write('employee', updatedEmployee);
        }

        Get.snackbar(
          'Berhasil',
          'Foto profil berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('deletePhoto error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // STORAGE HELPERS
  // ===========================================================================

  Future<void> _saveUserData() async {
    await box.write('token', token.value);
    await box.write('user', Map<String, dynamic>.from(user));
    if (employee.value != null) {
      await box.write('employee', employee.value);
    }
  }

  Future<void> _clearUserData() async {
    // Hapus hanya data session, JANGAN hapus offline queue
    await box.remove('token');
    await box.remove('user');
    await box.remove('employee');
    await box.remove('base_url');
    // Tidak hapus 'offline_absensi_queue_*' agar data offline tetap ada

    token.value = '';
    user.value = {};
    employee.value = null;
  }

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  bool get isLoggedIn => token.isNotEmpty;

  // Cek role dari user map
  bool get isSuperAdmin => user['role'] == 'superadmin';
  bool get isAdmin => user['role'] == 'admin';
  bool get isHrd => user['role'] == 'hrd';
  bool get isManager => user['role'] == 'manager';

  // 'employee' adalah role karyawan (sesuai enum di tabel users)
  bool get isEmployee => user['role'] == 'employee';

  bool get isActive => user['is_active'] == true || user['is_active'] == 1;

  // Data user
  String get userName => user['name']?.toString() ?? '';
  String get userEmail => user['email']?.toString() ?? '';
  String get userRole => user['role']?.toString() ?? '';

  // Data employee — ambil dari nested employee object
  int? get employeeId => employee.value?['id'] as int?;

  String get employeeFullName =>
      employee.value?['full_name']?.toString() ?? userName;

  String get employeeNickname =>
      employee.value?['nickname']?.toString() ?? employeeFullName;

  String get employeeCode => employee.value?['employee_code']?.toString() ?? '';

  String get employeeNik => employee.value?['nik']?.toString() ?? '';

  String get photoUrl => employee.value?['photo_url']?.toString() ?? '';

  String get fotoWajahUrl =>
      employee.value?['foto_wajah_url']?.toString() ?? '';

  bool get wajahTerdaftar =>
      employee.value?['wajah_terdaftar'] == true ||
      employee.value?['wajah_terdaftar'] == 1;

  String get departmentName => employee.value?['department']?.toString() ?? '';

  String get positionName => employee.value?['position']?.toString() ?? '';

  String get companyName => employee.value?['company']?.toString() ?? '';

  int? get companyId =>
      (employee.value?['company_id'] as int?) ?? (user['company_id'] as int?);

  // Apakah sudah ada profil karyawan
  bool get hasEmployee => employee.value != null;
}
