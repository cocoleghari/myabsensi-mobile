import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/lokasi_model.dart';
import 'app_config.dart';
import 'auth_controller.dart';

class LokasiController extends GetxController {
  final auth = Get.find<AuthController>();

  var lokasis = <LokasiModel>[].obs;
  var users = <Map<String, dynamic>>[].obs;
  var pusatLokasis = <Map<String, dynamic>>[].obs;
  var selectedPusatLokasiIds = <int>[].obs;

  var isLoading = false.obs;
  var isUserLoading = false.obs;

  var selectedUserForMultiple = ''.obs;
  var multipleLokasiEntries = <Map<String, dynamic>>[].obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initAndLoad();
    addNewLokasiEntry();
  }

  Future<void> _initAndLoad() async {
    _baseUrl = await AppConfig.getBaseUrl();
    if (auth.token.isNotEmpty) {
      fetchLokasi();
      fetchUsers();
      fetchPusatLokasi();
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

  Future<void> fetchPusatLokasi() async {
    if (auth.token.isEmpty) return;

    try {
      final baseUrl = await _resolvedBaseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pusat-lokasi'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData['data'] is List) {
          pusatLokasis.value = List<Map<String, dynamic>>.from(
            jsonData['data'],
          );
        } else if (jsonData['data'] is Map &&
            jsonData['data']['data'] != null) {
          pusatLokasis.value = List<Map<String, dynamic>>.from(
            jsonData['data']['data'],
          );
        }

        print('Pusat lokasi loaded: ${pusatLokasis.length} items');
      }
    } catch (e) {
      print('Error fetch pusat lokasi: $e');
    }
  }

  Future<void> fetchLokasi() async {
    if (auth.token.isEmpty) return;

    isLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      final res = await http.get(
        Uri.parse('$baseUrl/lokasi'),
        headers: _authHeaders,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          lokasis.value = data.map((e) => LokasiModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print('Error fetchLokasi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUsers() async {
    if (auth.token.isEmpty) return;

    isUserLoading.value = true;
    try {
      final baseUrl = await _resolvedBaseUrl;
      final res = await http.get(
        Uri.parse('$baseUrl/lokasi/users'),
        headers: _authHeaders,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          users.value = List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print('Error fetchUsers: $e');
    } finally {
      isUserLoading.value = false;
    }
  }

  Future<void> deleteLokasi(int id) async {
    try {
      final baseUrl = await _resolvedBaseUrl;
      final res = await http.delete(
        Uri.parse('$baseUrl/lokasi/$id'),
        headers: _authHeaders,
      );

      if (res.statusCode == 200) {
        await fetchLokasi();
        Get.snackbar('Sukses', 'Lokasi berhasil dihapus');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  void toggleSelectAllPusatLokasi() {
    if (selectedPusatLokasiIds.length == pusatLokasis.length) {
      selectedPusatLokasiIds.clear();
    } else {
      selectedPusatLokasiIds.value = pusatLokasis
          .map((e) => e['id'] as int)
          .toList();
    }
  }

  void togglePusatLokasiItem(int id) {
    if (selectedPusatLokasiIds.contains(id)) {
      selectedPusatLokasiIds.remove(id);
    } else {
      selectedPusatLokasiIds.add(id);
    }
  }

  void resetPusatLokasiSelection() {
    selectedPusatLokasiIds.clear();
  }

  Future<void> submitMultipleLokasiFromPusat() async {
    try {
      if (selectedPusatLokasiIds.isEmpty) {
        Get.snackbar(
          'Error',
          'Pilih minimal satu lokasi',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (selectedUserForMultiple.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Pilih user terlebih dahulu',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;
      int successCount = 0;
      int failedCount = 0;

      final baseUrl = await _resolvedBaseUrl;
      final selectedLokasis = pusatLokasis
          .where((item) => selectedPusatLokasiIds.contains(item['id']))
          .toList();

      for (var item in selectedLokasis) {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/lokasi'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': int.parse(selectedUserForMultiple.value),
              'lokasi': item['nama_lokasi'],
              'koordinat': item['titik_kordinat'],
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            successCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          print('Error submit: $e');
        }
      }

      selectedPusatLokasiIds.clear();
      selectedUserForMultiple.value = '';

      await fetchLokasi();
      await fetchPusatLokasi();

      String message;
      if (failedCount > 0) {
        message = '$successCount lokasi berhasil, $failedCount gagal';
      } else {
        message = '$successCount lokasi berhasil ditambahkan';
      }

      Get.snackbar(
        'Sukses',
        message,
        backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void addNewLokasiEntry() {
    multipleLokasiEntries.add({
      'lokasi': ''.obs,
      'koordinat': ''.obs,
      'isValid': false.obs,
    });
  }

  void removeLokasiEntry(int index) {
    if (multipleLokasiEntries.length > 1) {
      multipleLokasiEntries.removeAt(index);
    }
  }

  void updateLokasiEntry(int index, String field, String value) {
    if (index < multipleLokasiEntries.length) {
      multipleLokasiEntries[index][field]?.value = value;

      final lokasi = multipleLokasiEntries[index]['lokasi']?.value ?? '';
      final koordinat = multipleLokasiEntries[index]['koordinat']?.value ?? '';
      multipleLokasiEntries[index]['isValid']?.value =
          lokasi.isNotEmpty && koordinat.isNotEmpty;
    }
  }

  Future<void> submitMultipleLokasiManual() async {
    try {
      final validEntries = multipleLokasiEntries.where((entry) {
        final lokasi = entry['lokasi']?.value ?? '';
        final koordinat = entry['koordinat']?.value ?? '';
        return lokasi.isNotEmpty && koordinat.isNotEmpty;
      }).toList();

      if (validEntries.isEmpty) {
        Get.snackbar(
          'Error',
          'Tidak ada data lokasi yang valid untuk disimpan',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (selectedUserForMultiple.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Pilih user terlebih dahulu',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;
      int successCount = 0;
      int failedCount = 0;

      final baseUrl = await _resolvedBaseUrl;

      for (var entry in validEntries) {
        try {
          final res = await http.post(
            Uri.parse('$baseUrl/lokasi'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': int.parse(selectedUserForMultiple.value),
              'lokasi': entry['lokasi']?.value ?? '',
              'koordinat': entry['koordinat']?.value ?? '',
            }),
          );

          if (res.statusCode == 200 || res.statusCode == 201) {
            successCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
        }
      }

      multipleLokasiEntries.clear();
      addNewLokasiEntry();
      selectedUserForMultiple.value = '';

      await fetchLokasi();

      String message;
      if (failedCount > 0) {
        message =
            '$successCount lokasi berhasil ditambahkan, $failedCount gagal';
      } else {
        message = '$successCount lokasi berhasil ditambahkan';
      }

      Get.snackbar(
        'Sukses',
        message,
        backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void resetMultipleForm() {
    multipleLokasiEntries.clear();
    addNewLokasiEntry();
    selectedUserForMultiple.value = '';
    selectedPusatLokasiIds.clear();
  }
}
