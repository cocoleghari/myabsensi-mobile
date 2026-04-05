import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/pusat_lokasi_model.dart';
import 'app_config.dart';
import 'auth_controller.dart';

class PusatLokasiController extends GetxController {
  final auth = Get.find<AuthController>();

  var pusatLokasis = <PusatLokasiModel>[].obs;
  var filteredLokasis = <PusatLokasiModel>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var errorMessage = ''.obs;
  var searchQuery = ''.obs;

  var currentPage = 1.obs;
  var lastPage = 1.obs;
  var totalItems = 0.obs;

  var selectedIds = <int>[].obs;
  var isSelectionMode = false.obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _baseUrl = await AppConfig.getBaseUrl();
    fetchPusatLokasi();
  }

  Future<String> get _resolvedBaseUrl async {
    if (_baseUrl.isEmpty) _baseUrl = await AppConfig.getBaseUrl();
    return _baseUrl;
  }

  Map<String, String> get _authHeaders {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${auth.token}',
    };
  }

  Future<void> fetchPusatLokasi({int page = 1, String? search}) async {
    if (auth.token.isEmpty) {
      errorMessage.value = 'Token tidak ditemukan';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final baseUrl = await _resolvedBaseUrl;
      String url = '$baseUrl/admin/pusat-lokasi';
      bool hasParam = false;

      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
        hasParam = true;
      }

      if (page > 1) {
        url += hasParam ? '&page=$page' : '?page=$page';
      }

      print('Fetching pusat lokasi: $url');

      final response = await http
          .get(Uri.parse(url), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData['data'] is List) {
          List<PusatLokasiModel> data = (jsonData['data'] as List)
              .map((item) => PusatLokasiModel.fromJson(item))
              .toList();

          pusatLokasis.value = data;
          filteredLokasis.value = data;

          print('Data loaded: ${data.length} items');
        } else if (jsonData['data'] is Map &&
            jsonData['data']['data'] != null) {
          List<PusatLokasiModel> data = (jsonData['data']['data'] as List)
              .map((item) => PusatLokasiModel.fromJson(item))
              .toList();

          pusatLokasis.value = data;
          filteredLokasis.value = data;

          currentPage.value = jsonData['data']['current_page'] ?? 1;
          lastPage.value = jsonData['data']['last_page'] ?? 1;
          totalItems.value = jsonData['data']['total'] ?? 0;

          print('Data loaded: page $currentPage/$lastPage, total: $totalItems');
        } else {
          pusatLokasis.value = [];
          filteredLokasis.value = [];
        }
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Sesi habis, silahkan login ulang';
        Future.delayed(const Duration(seconds: 2), () => auth.logout());
      } else {
        errorMessage.value = 'Error ${response.statusCode}';
        print('Error response: ${response.body}');
      }
    } catch (e) {
      print('Error fetch pusat lokasi: $e');
      errorMessage.value = 'Gagal memuat data: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void search(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredLokasis.value = pusatLokasis;
    } else {
      filteredLokasis.value = pusatLokasis.where((item) {
        return item.namaLokasi.toLowerCase().contains(query.toLowerCase()) ||
            (item.keterangan?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();
    }
  }

  Future<bool> createPusatLokasi({
    required String namaLokasi,
    required String titikKordinat,
    String? keterangan,
  }) async {
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

    isSubmitting.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Creating pusat lokasi: $namaLokasi');

      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/pusat-lokasi'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'nama_lokasi': namaLokasi,
              'titik_kordinat': titikKordinat,
              'keterangan': keterangan,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        await fetchPusatLokasi();

        Get.snackbar(
          'Berhasil',
          'Data pusat lokasi berhasil ditambahkan',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        String errorMsg = errorData['message'] ?? 'Gagal menambahkan data';

        if (errorData['errors'] != null) {
          final errors = errorData['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMsg = firstError.first;
          }
        }

        Get.snackbar(
          'Gagal',
          errorMsg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      print('Error create: $e');
      Get.snackbar(
        'Error',
        'Koneksi error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updatePusatLokasi({
    required int id,
    String? namaLokasi,
    String? titikKordinat,
    String? keterangan,
  }) async {
    if (auth.token.isEmpty) {
      Get.snackbar('Error', 'Token tidak ditemukan');
      return false;
    }

    isSubmitting.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Updating pusat lokasi ID: $id');

      Map<String, dynamic> body = {};
      if (namaLokasi != null) body['nama_lokasi'] = namaLokasi;
      if (titikKordinat != null) body['titik_kordinat'] = titikKordinat;
      if (keterangan != null) body['keterangan'] = keterangan;

      final response = await http
          .put(
            Uri.parse('$baseUrl/admin/pusat-lokasi/$id'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await fetchPusatLokasi();

        Get.snackbar(
          'Berhasil',
          'Data pusat lokasi berhasil diupdate',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          errorData['message'] ?? 'Gagal mengupdate data',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('Error update: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deletePusatLokasi(int id) async {
    if (auth.token.isEmpty) {
      Get.snackbar('Error', 'Token tidak ditemukan');
      return false;
    }

    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Deleting pusat lokasi ID: $id');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/pusat-lokasi/$id'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        pusatLokasis.removeWhere((item) => item.id == id);
        filteredLokasis.removeWhere((item) => item.id == id);

        Get.snackbar(
          'Berhasil',
          'Data pusat lokasi berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          errorData['message'] ?? 'Gagal menghapus data',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('Error delete: $e');
      Get.snackbar('Error', e.toString());
      return false;
    }
  }

  Future<bool> deleteMultiplePusatLokasi() async {
    if (selectedIds.isEmpty) {
      Get.snackbar(
        'Info',
        'Pilih data yang akan dihapus',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (auth.token.isEmpty) {
      Get.snackbar('Error', 'Token tidak ditemukan');
      return false;
    }

    try {
      final baseUrl = await _resolvedBaseUrl;
      print('Deleting multiple: ${selectedIds.length} items');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/pusat-lokasi'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({'ids': selectedIds.toList()}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        await fetchPusatLokasi();

        selectedIds.clear();
        isSelectionMode.value = false;

        Get.snackbar(
          'Berhasil',
          result['message'] ?? 'Data berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          errorData['message'] ?? 'Gagal menghapus data',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('Error delete multiple: $e');
      Get.snackbar('Error', e.toString());
      return false;
    }
  }

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedIds.clear();
    }
  }

  void toggleSelectItem(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  void selectAll() {
    if (selectedIds.length == filteredLokasis.length) {
      selectedIds.clear();
    } else {
      selectedIds.value = filteredLokasis.map((e) => e.id).toList();
    }
  }

  void reset() {
    pusatLokasis.clear();
    filteredLokasis.clear();
    errorMessage.value = '';
    isLoading.value = false;
    isSubmitting.value = false;
    selectedIds.clear();
    isSelectionMode.value = false;
    searchQuery.value = '';
  }
}
