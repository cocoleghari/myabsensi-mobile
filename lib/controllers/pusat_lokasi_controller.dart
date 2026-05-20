import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/pusat_lokasi_model.dart';
import 'app_config.dart';
import 'auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  Map<String, String> get _authHeaders => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${auth.token}',
  };

  // =========================================================================
  // FETCH
  // =========================================================================

  Future<void> fetchPusatLokasi({int page = 1, String? search}) async {
    if (auth.token.isEmpty) {
      errorMessage.value = 'Token tidak ditemukan';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final baseUrl = await _resolvedBaseUrl;

      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (page > 1) params['page'] = page.toString();

      final uri = Uri.parse(
        '$baseUrl/admin/pusat-lokasi',
      ).replace(queryParameters: params.isNotEmpty ? params : null);

      final response = await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        List<PusatLokasiModel> data = [];

        if (jsonData['data'] is List) {
          data = (jsonData['data'] as List)
              .map((item) => PusatLokasiModel.fromJson(item))
              .toList();
          totalItems.value = data.length;
        } else if (jsonData['data'] is Map &&
            jsonData['data']['data'] != null) {
          data = (jsonData['data']['data'] as List)
              .map((item) => PusatLokasiModel.fromJson(item))
              .toList();
          currentPage.value = jsonData['data']['current_page'] ?? 1;
          lastPage.value = jsonData['data']['last_page'] ?? 1;
          totalItems.value = jsonData['data']['total'] ?? 0;
        }

        pusatLokasis.value = data;
        filteredLokasis.value = data;
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Sesi habis, silahkan login ulang';
        Future.delayed(const Duration(seconds: 2), () => auth.logout());
      } else {
        errorMessage.value = 'Error ${response.statusCode}';
      }
    } catch (e) {
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

  // =========================================================================
  // CREATE
  // FIXED: tambah company_id yang wajib diisi backend
  // =========================================================================

  Future<bool> createPusatLokasi({
    required int companyId, // FIXED: wajib sesuai backend
    required String namaLokasi,
    required String titikKordinat,
    String? keterangan,
    bool isActive = true,
  }) async {
    if (auth.token.isEmpty) {
      Get.snackbar(
        'Error',
        'Token tidak ditemukan',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    isSubmitting.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/pusat-lokasi'),
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'company_id': companyId, // FIXED: wajib
              'nama_lokasi': namaLokasi,
              'titik_kordinat': titikKordinat,
              if (keterangan != null && keterangan.isNotEmpty)
                'keterangan': keterangan,
              'is_active': isActive,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        await fetchPusatLokasi();
        Get.snackbar(
          'Berhasil',
          'Data pusat lokasi berhasil ditambahkan',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
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
      isSubmitting.value = false;
    }
  }

  // =========================================================================
  // UPDATE
  // FIXED: tambah company_id dan is_active sebagai optional
  // =========================================================================

  Future<bool> updatePusatLokasi({
    required int id,
    int? companyId,
    String? namaLokasi,
    String? titikKordinat,
    String? keterangan,
    bool? isActive,
  }) async {
    if (auth.token.isEmpty) {
      Get.snackbar('Error', 'Token tidak ditemukan');
      return false;
    }

    isSubmitting.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;

      final body = <String, dynamic>{};
      if (companyId != null) body['company_id'] = companyId;
      if (namaLokasi != null) body['nama_lokasi'] = namaLokasi;
      if (titikKordinat != null) body['titik_kordinat'] = titikKordinat;
      if (keterangan != null) body['keterangan'] = keterangan;
      if (isActive != null) body['is_active'] = isActive;

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
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // =========================================================================
  // DELETE SINGLE
  // =========================================================================

  Future<bool> deletePusatLokasi(int id) async {
    if (auth.token.isEmpty) return false;

    try {
      final baseUrl = await _resolvedBaseUrl;

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
      Get.snackbar('Error', e.toString());
      return false;
    }
  }

  // =========================================================================
  // DELETE MULTIPLE
  // =========================================================================

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

    if (auth.token.isEmpty) return false;

    try {
      final baseUrl = await _resolvedBaseUrl;

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
      Get.snackbar('Error', e.toString());
      return false;
    }
  }

  // =========================================================================
  // EXPORT
  // =========================================================================

  var isExporting = false.obs;

  Future<void> exportPusatLokasi() async {
    if (auth.token.isEmpty) return;

    isExporting.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;
      final dio = Dio();

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'pusat_lokasi_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final savePath = '${dir.path}/$fileName';

      await dio.download(
        '$baseUrl/admin/pusat-lokasi/export',
        savePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${auth.token}',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
        onReceiveProgress: (received, total) {
          // opsional: bisa tambahkan progress indicator
        },
      );

      Get.snackbar(
        'Berhasil',
        'File tersimpan: $fileName',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () => OpenFile.open(savePath),
          child: const Text(
            'Buka',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Export gagal: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  // =========================================================================
  // DOWNLOAD TEMPLATE
  // =========================================================================

  var isDownloadingTemplate = false.obs;

  Future<void> downloadTemplate() async {
    if (auth.token.isEmpty) return;

    isDownloadingTemplate.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;
      final dio = Dio();

      final dir = await getApplicationDocumentsDirectory();
      const fileName = 'template_import_pusat_lokasi.xlsx';
      final savePath = '${dir.path}/$fileName';

      await dio.download(
        '$baseUrl/admin/pusat-lokasi/import-template',
        savePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${auth.token}',
            'Accept': 'application/json',
          },
        ),
      );

      Get.snackbar(
        'Berhasil',
        'Template tersimpan',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () => OpenFile.open(savePath),
          child: const Text(
            'Buka',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Download template gagal: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isDownloadingTemplate.value = false;
    }
  }

  // =========================================================================
  // IMPORT
  // =========================================================================

  var isImporting = false.obs;

  Future<void> importPusatLokasi() async {
    if (auth.token.isEmpty) return;

    // Buka file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    isImporting.value = true;

    try {
      final baseUrl = await _resolvedBaseUrl;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/pusat-lokasi/import'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${auth.token}',
        'Accept': 'application/json',
      });

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await fetchPusatLokasi();
        Get.snackbar(
          'Berhasil',
          jsonData['message'] ?? 'Import selesai',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        final errors = jsonData['errors'];
        String msg = jsonData['message'] ?? 'Import gagal';
        if (errors is List && errors.isNotEmpty) {
          msg += '\n${errors.take(3).join('\n')}';
          if (errors.length > 3)
            msg += '\n... dan ${errors.length - 3} error lainnya';
        }
        Get.snackbar(
          'Gagal',
          msg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Import gagal: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isImporting.value = false;
    }
  }

  // =========================================================================
  // SELECTION MODE
  // =========================================================================

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) selectedIds.clear();
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
