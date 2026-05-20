import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../controllers/auth_controller.dart';
import '../../../controllers/app_config.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DepartmentController extends GetxController {
  final authController = Get.find<AuthController>();

  var isLoading = false.obs;
  var isSaving = false.obs;
  var departments = <Map<String, dynamic>>[].obs;
  var filteredDepartments = <Map<String, dynamic>>[].obs;

  // Filter & search
  var searchQuery = ''.obs;
  var filterIsActive = Rxn<bool>();

  // Companies
  var companies = <Map<String, dynamic>>[].obs;
  var isLoadingCompanies = false.obs;

  // Employees untuk dropdown manager
  var employeesDropdown = <Map<String, dynamic>>[].obs;
  var isLoadingEmployeesDropdown = false.obs;

  var isExporting = false.obs;
  var isImporting = false.obs;

  String _baseUrl = '';

  @override
  void onInit() {
    super.onInit();
    _initAndFetch();

    ever(searchQuery, (_) => _applyFilter());
    ever(filterIsActive, (_) => _applyFilter());
  }

  Future<void> _initAndFetch() async {
    _baseUrl = await AppConfig.getBaseUrl();
    // Fetch semua data awal secara paralel
    await Future.wait([
      fetchDepartments(),
      fetchCompanies(),
      fetchEmployeesDropdown(), // ← diperlukan untuk dropdown manager di form
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // FETCH
  // ─────────────────────────────────────────────────────────

  Future<void> fetchDepartments() async {
    isLoading.value = true;
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/departments'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        late Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('=== DEPT JSON ERROR: $e');
          _showError('Gagal memuat data department');
          return;
        }
        departments.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
        _applyFilter();
      } else {
        _showError('Gagal memuat data department (${response.statusCode})');
      }
    } on TimeoutException {
      _showError('Koneksi timeout. Coba lagi.');
    } catch (e) {
      _showError('Koneksi error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCompanies() async {
    isLoadingCompanies.value = true;
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/companies'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final bodyString = utf8.decode(
          response.bodyBytes,
          allowMalformed: true,
        );
        final data = jsonDecode(bodyString);
        companies.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      _showError('Gagal memuat data company: $e');
    } finally {
      isLoadingCompanies.value = false;
    }
  }

  /// Fetch semua karyawan aktif (semua halaman) untuk dipakai sebagai
  /// dropdown manager di DepartmentFormDialog.
  Future<void> fetchEmployeesDropdown() async {
    isLoadingEmployeesDropdown.value = true;
    try {
      final List<Map<String, dynamic>> allEmployees = [];
      int currentPage = 1;
      int lastPage = 1;

      do {
        // Gunakan endpoint yang sama dengan employeesForAssign di backend
        final uri = Uri.parse('$_baseUrl/admin/employees-list').replace(
          queryParameters: {'page': currentPage.toString(), 'per_page': '50'},
        );

        final response = await http
            .get(
              uri,
              headers: {
                'Authorization': 'Bearer ${authController.token.value}',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final bodyString = utf8.decode(
            response.bodyBytes,
            allowMalformed: true,
          );
          final data = jsonDecode(bodyString) as Map<String, dynamic>;
          final list = List<Map<String, dynamic>>.from(data['data'] ?? []);
          allEmployees.addAll(list);

          final meta = data['meta'] as Map<String, dynamic>? ?? {};
          lastPage = meta['last_page'] ?? 1;
          currentPage++;
        } else {
          break;
        }
      } while (currentPage <= lastPage);

      employeesDropdown.value = allEmployees;
    } catch (e) {
      debugPrint('fetchEmployeesDropdown error: $e');
    } finally {
      isLoadingEmployeesDropdown.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // FILTER (lokal)
  // ─────────────────────────────────────────────────────────

  void _applyFilter() {
    var result = departments.toList();

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((d) {
        final name = (d['name'] ?? '').toString().toLowerCase();
        final code = (d['code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }

    if (filterIsActive.value != null) {
      result = result
          .where((d) => d['is_active'] == filterIsActive.value)
          .toList();
    }

    filteredDepartments.value = result;
  }

  void setSearch(String q) => searchQuery.value = q;

  void setFilterActive(bool? val) => filterIsActive.value = val;

  // ─────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────

  Future<bool> createDepartment(Map<String, dynamic> body) async {
    isSaving.value = true;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/departments'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
      final data = jsonDecode(bodyString);
      if (response.statusCode == 201) {
        _showSuccess(data['message'] ?? 'Department berhasil dibuat');
        await fetchDepartments();
        return true;
      } else {
        _showValidationError(data);
        return false;
      }
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────

  Future<bool> updateDepartment(int id, Map<String, dynamic> body) async {
    isSaving.value = true;
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/admin/departments/$id'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
      final data = jsonDecode(bodyString);
      if (response.statusCode == 200) {
        _showSuccess(data['message'] ?? 'Department berhasil diperbarui');
        await fetchDepartments();
        return true;
      } else {
        _showValidationError(data);
        return false;
      }
    } catch (e) {
      _showError('Koneksi error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────

  Future<void> deleteDepartment(int id, String name) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Department',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus department "$name"?\n\nDepartment tidak dapat dihapus jika masih memiliki sub-department atau karyawan.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/admin/departments/$id'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
      final data = jsonDecode(bodyString);
      if (response.statusCode == 200) {
        _showSuccess(data['message'] ?? 'Department berhasil dihapus');
        await fetchDepartments();
      } else {
        _showError(data['message'] ?? 'Gagal menghapus department');
      }
    } catch (e) {
      _showError('Koneksi error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // EXPORT
  // ─────────────────────────────────────────────────────────

  Future<void> exportDepartments() async {
    isExporting.value = true;
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/departments/export'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
              'Accept':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            },
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // Simpan file ke storage
        final dir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download')
            : await getApplicationDocumentsDirectory();

        if (!await dir.exists()) await dir.create(recursive: true);

        final filename =
            'departments_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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
        _showError('Gagal export department (${response.statusCode})');
      }
    } on TimeoutException {
      _showError('Export timeout. Coba lagi.');
    } catch (e) {
      _showError('Export error: $e');
    } finally {
      isExporting.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // DOWNLOAD TEMPLATE IMPORT
  // ─────────────────────────────────────────────────────────

  Future<void> downloadImportTemplate() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/departments/import-template'),
            headers: {
              'Authorization': 'Bearer ${authController.token.value}',
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

        final file = File('${dir.path}/template_import_departments.xlsx');
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

  // ─────────────────────────────────────────────────────────
  // IMPORT
  // ─────────────────────────────────────────────────────────

  Future<void> importDepartments() async {
    // ── ANDROID: request permission dulu ──────────────────────────
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt <= 32) {
        // Android 9, 10, 11, 12 — pakai READ_EXTERNAL_STORAGE
        final status = await Permission.storage.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          _showError('Izin akses storage diperlukan');
          return;
        }
      }
      // Android 13+ (SDK 33+) — TIDAK perlu permission storage
      // file_picker pakai system document picker, sudah aman
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      // allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
      withData: true,
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;

    Uint8List? fileBytes;

    if (fileBytes == null) {
      if (pickedFile.bytes != null) {
        fileBytes = pickedFile.bytes!;
      } else if (pickedFile.readStream != null) {
        // Fallback: baca dari stream
        fileBytes = await pickedFile.readStream!
            .fold<List<int>>([], (buf, chunk) => buf..addAll(chunk))
            .then((list) => Uint8List.fromList(list));
      } else {
        _showError('Tidak bisa membaca file');
        return;
      }
    }

    // Konfirmasi import
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Colors.deepPurple),
            SizedBox(width: 10),
            Text(
              'Import Department',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${pickedFile.name}',
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
              backgroundColor: Colors.deepPurple,
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/admin/departments/import'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer ${authController.token.value}',
        'Accept': 'application/json',
      });
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes!,
          filename: pickedFile.name,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      final bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);
      final data = jsonDecode(bodyString) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final errList = (data['errors'] as List?)?.cast<String>() ?? [];
        final success = data['success'] ?? 0;
        final failed = data['failed'] ?? 0;

        // Tampilkan hasil detail
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
                  backgroundColor: Colors.deepPurple,
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

        if (success > 0) await fetchDepartments();
      } else {
        _showValidationError(data);
      }
    } on TimeoutException {
      _showError('Import timeout. Coba lagi.');
    } catch (e) {
      _showError('Import error: $e');
    } finally {
      isImporting.value = false;
    }
  }

  // Helper widget untuk hasil import
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

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

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
  );

  void _showValidationError(Map<String, dynamic> data) {
    String msg = data['message'] ?? 'Terjadi kesalahan';
    if (data['errors'] != null) {
      final errors = data['errors'] as Map;
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) msg = first.first;
    }
    _showError(msg);
  }
}
