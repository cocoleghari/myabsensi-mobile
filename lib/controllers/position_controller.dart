import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/position_model.dart';
import 'app_config.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PositionController extends GetxController {
  final box = GetStorage();

  var isLoading = false.obs;
  var isLoadingCompanies = false.obs;

  var positions = <Position>[].obs;
  var currentPage = 1.obs;
  var lastPage = 1.obs;

  var searchQuery = ''.obs;
  var filterCompanyId = Rxn<int>();

  var companies = <Map<String, dynamic>>[].obs;

  var isExporting = false.obs;
  var isImporting = false.obs;

  String get _token => box.read('token') ?? '';
  Future<String> get _base async => await AppConfig.getBaseUrl();

  @override
  void onInit() {
    super.onInit();
    Future.wait([fetchCompanies(), fetchPositions()]);
  }

  // ─── Master data fetchers ────────────────────────────────────────────────

  Future<void> fetchCompanies() async {
    if (isLoadingCompanies.value) return;
    isLoadingCompanies.value = true;
    try {
      final base = await _base;
      final resp = await http
          .get(
            Uri.parse('$base/admin/companies-list'),
            headers: {
              'Authorization': 'Bearer $_token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List raw;
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          raw = decoded['data'] as List;
        } else {
          raw = [];
        }
        companies.value = raw.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('fetchCompanies error: $e');
    } finally {
      isLoadingCompanies.value = false;
    }
  }

  // ─── Positions CRUD ──────────────────────────────────────────────────────

  Future<void> fetchPositions({bool reset = true}) async {
    if (reset) currentPage.value = 1;
    isLoading.value = true;
    try {
      final base = await _base;
      final uri = Uri.parse('$base/admin/positions').replace(
        queryParameters: {
          'page': currentPage.value.toString(),
          'per_page': '20',
          if (searchQuery.isNotEmpty) 'search': searchQuery.value,
          if (filterCompanyId.value != null)
            'company_id': filterCompanyId.value.toString(),
        },
      );
      final resp = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = (data['data'] as List)
            .map((e) => Position.fromJson(e))
            .toList();
        if (reset) {
          positions.value = list;
        } else {
          positions.addAll(list);
        }
        lastPage.value = data['meta']?['last_page'] ?? 1;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createPosition(Map<String, dynamic> data) async {
    try {
      final base = await _base;
      final resp = await http
          .post(
            Uri.parse('$base/admin/positions'),
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          'Posisi berhasil dibuat',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchPositions();
        return true;
      } else {
        final msg = jsonDecode(resp.body)['message'] ?? 'Gagal membuat posisi';
        Get.snackbar(
          'Gagal',
          msg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> updatePosition(int id, Map<String, dynamic> data) async {
    try {
      final base = await _base;
      final resp = await http
          .put(
            Uri.parse('$base/admin/positions/$id'),
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          'Posisi berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchPositions();
        return true;
      } else {
        final msg = jsonDecode(resp.body)['message'] ?? 'Gagal memperbarui';
        Get.snackbar(
          'Gagal',
          msg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> deletePosition(int id) async {
    try {
      final base = await _base;
      final resp = await http
          .delete(
            Uri.parse('$base/admin/positions/$id'),
            headers: {
              'Authorization': 'Bearer $_token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        positions.removeWhere((p) => p.id == id);
        Get.snackbar(
          'Berhasil',
          body['message'] ?? 'Posisi dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Gagal',
          body['message'] ?? 'Tidak bisa menghapus',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ─── Export ──────────────────────────────────────────────────────────────

  Future<void> exportPositions() async {
    isExporting.value = true;
    try {
      final base = await _base;
      final response = await http
          .get(
            Uri.parse('$base/admin/positions/export'),
            headers: {
              'Authorization': 'Bearer $_token',
              'Accept':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            },
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final dir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download')
            : await getApplicationDocumentsDirectory();

        if (!await dir.exists()) await dir.create(recursive: true);

        final filename =
            'positions_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        Get.snackbar(
          'Export Berhasil',
          'File disimpan: ${file.path}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => OpenFile.open(file.path),
            child: const Text('Buka', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        _showError('Gagal export (${response.statusCode})');
      }
    } on TimeoutException {
      _showError('Export timeout. Coba lagi.');
    } catch (e) {
      _showError('Export error: $e');
    } finally {
      isExporting.value = false;
    }
  }

  // ─── Download Template ───────────────────────────────────────────────────

  Future<void> downloadImportTemplate() async {
    try {
      final base = await _base;
      final response = await http
          .get(
            Uri.parse('$base/admin/positions/import-template'),
            headers: {
              'Authorization': 'Bearer $_token',
              'Accept':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download')
            : await getApplicationDocumentsDirectory();

        if (!await dir.exists()) await dir.create(recursive: true);

        final file = File('${dir.path}/template_import_positions.xlsx');
        await file.writeAsBytes(response.bodyBytes);

        Get.snackbar(
          'Template Diunduh',
          'File: ${file.path}',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => OpenFile.open(file.path),
            child: const Text('Buka', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        _showError('Gagal mengunduh template');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  // ─── Import ──────────────────────────────────────────────────────────────

  Future<void> importPositions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        final status = await Permission.storage.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          _showError('Izin akses storage diperlukan');
          return;
        }
      }
    }

    Uint8List? fileBytes;
    String fileName = 'import.xlsx';

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      fileName = pickedFile.name;

      if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
        fileBytes = pickedFile.bytes!;
      } else if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        if (await file.exists()) fileBytes = await file.readAsBytes();
      }
    } catch (e) {
      _showError(
        'Gagal membaca file.\n\nPastikan file disimpan di storage lokal HP, bukan Google Drive atau cloud storage.',
      );
      return;
    }

    if (fileBytes == null || fileBytes.isEmpty) {
      _showError(
        'Tidak bisa membaca file. Simpan file ke storage lokal HP terlebih dahulu.',
      );
      return;
    }

    final ext = fileName.split('.').last.toLowerCase();
    if (!['xlsx', 'xls'].contains(ext)) {
      _showError('Format file tidak didukung. Gunakan file .xlsx atau .xls');
      return;
    }

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Colors.indigo),
            SizedBox(width: 10),
            Text(
              'Import Posisi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: $fileName',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data dari file akan ditambahkan ke database.\nPastikan format file sesuai template.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    isImporting.value = true;
    try {
      final base = await _base;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/admin/positions/import'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      });
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final errList = (data['errors'] as List?)?.cast<String>() ?? [];
        final success = data['success'] ?? 0;
        final failed = data['failed'] ?? 0;

        await Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  failed == 0
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: failed == 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Hasil Import',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _importResultRow(
                  Icons.check_circle_outline,
                  Colors.green,
                  'Berhasil: $success data',
                ),
                if (failed > 0)
                  _importResultRow(
                    Icons.error_outline,
                    Colors.red,
                    'Gagal: $failed data',
                  ),
                if (errList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Detail error:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: errList
                            .map(
                              (e) => Text(
                                '• $e',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );

        if (success > 0) await fetchPositions();
      } else {
        String msg = data['message'] ?? 'Gagal import';
        if (data['errors'] != null) {
          final errs = data['errors'] as Map;
          final first = errs.values.first;
          msg = (first is List) ? first.first.toString() : first.toString();
        }
        _showError(msg);
      }
    } on TimeoutException {
      _showError('Import timeout. Coba lagi.');
    } catch (e) {
      _showError('Import error: $e');
    } finally {
      isImporting.value = false;
    }
  }

  Widget _importResultRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    backgroundColor: Colors.red,
    colorText: Colors.white,
  );
}
