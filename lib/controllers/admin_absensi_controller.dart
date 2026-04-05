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
  var semuaUsers = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isLoadingUsers = false.obs;
  var errorMessage = ''.obs;

  var selectedUserId = ''.obs;

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

  Future<void> fetchAllUsers() async {
    if (auth.token.isEmpty) {
      errorMessage.value = 'Token tidak ditemukan';
      return;
    }

    isLoadingUsers.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Fetching all users');

      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/users/all'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Response users: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          semuaUsers.value = List<Map<String, dynamic>>.from(data['data']);
          print('Users: ${semuaUsers.length} data');
        } else {
          semuaUsers.value = [];
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
        print('Error fetch users: ${response.statusCode}');
        errorMessage.value = 'Gagal memuat data users';
      }
    } catch (e) {
      print('Error fetch users: $e');
      errorMessage.value = 'Gagal memuat data users';
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<void> fetchAllAbsensi() async {
    if (auth.token.isEmpty) {
      errorMessage.value = 'Token tidak ditemukan';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Fetching all absensi');

      String url = '$baseUrl/admin/absensi/all';

      if (selectedUserId.value.isNotEmpty) {
        url = '$url?user_id=${selectedUserId.value}';
      }

      print('URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('Response absensi: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          semuaAbsensi.value = List<Map<String, dynamic>>.from(data['data']);
          print('Absensi: ${semuaAbsensi.length} data');
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
        print('Error fetch absensi: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetch absensi: $e');
      errorMessage.value = 'Gagal memuat data absensi';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteAbsensi(int id) async {
    if (auth.token.isEmpty) {
      Get.snackbar(
        'Error',
        'Token tidak ditemukan',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Deleting absensi ID: $id');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/absensi/$id'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${auth.token}',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Response delete: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Absensi berhasil dihapus');
        return true;
      } else if (response.statusCode == 401) {
        Get.snackbar(
          'Sesi Habis',
          'Silahkan login ulang',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
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
            snackPosition: SnackPosition.TOP,
          );
        } catch (e) {
          Get.snackbar(
            'Gagal',
            'Error ${response.statusCode}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
        return false;
      }
    } catch (e) {
      print('Error delete absensi: $e');
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  void filterByUser(String userId) {
    selectedUserId.value = userId;
    fetchAllAbsensi();
  }

  void resetFilter() {
    selectedUserId.value = '';
    fetchAllAbsensi();
  }

  String getUserNameById(int userId) {
    try {
      final user = semuaUsers.firstWhere(
        (u) => u['id'] == userId,
        orElse: () => {'name': 'Unknown User'},
      );
      return user['name'] ?? 'Unknown User';
    } catch (e) {
      print('Error get user name: $e');
      return 'Unknown User';
    }
  }

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

        String jam = parts[1];
        jam = jam.replaceAll(RegExp(r'\..*$'), '');
        jam = jam.replaceAll(RegExp(r'Z$'), '');

        if (jam.contains(':')) {
          final jamParts = jam.split(':');
          if (jamParts.length >= 2) {
            jam = '${jamParts[0]}:${jamParts[1]}';
          }
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
            if (jamParts.length >= 2) {
              jam = '${jamParts[0]}:${jamParts[1]}';
            }
          }

          return '$tanggal $jam';
        }
      }

      return waktuStr;
    } catch (e) {
      print('Error format waktu: $e');
      return waktuStr;
    }
  }

  int getUniqueDatesCount() {
    try {
      Set<String> dates = {};
      for (var item in semuaAbsensi) {
        if (item['waktu_absen'] != null) {
          String waktu = item['waktu_absen'].toString();
          if (waktu.contains('T')) {
            dates.add(waktu.split('T')[0]);
          } else if (waktu.contains(' ')) {
            dates.add(waktu.split(' ')[0]);
          }
        }
      }
      return dates.length;
    } catch (e) {
      print('Error hitung unique dates: $e');
      return 0;
    }
  }

  void reset() {
    semuaAbsensi.clear();
    semuaUsers.clear();
    errorMessage.value = '';
    isLoading.value = false;
    isLoadingUsers.value = false;
    selectedUserId.value = '';
  }

  void printDebugInfo() {
    print('=' * 50);
    print('ADMIN ABSENSI CONTROLLER');
    print('BaseUrl: $_baseUrl');
    print('Token: ${auth.token.isNotEmpty ? "Ada" : "Kosong"}');
    print('Total Users: ${semuaUsers.length}');
    print('Total Absensi: ${semuaAbsensi.length}');
    print('Selected User: ${selectedUserId.value}');
    print('Loading: $isLoading');
    print('Error: ${errorMessage.value}');
    print('=' * 50);
  }
}
