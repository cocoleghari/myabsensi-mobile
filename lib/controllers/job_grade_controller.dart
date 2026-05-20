import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'auth_controller.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class JobGradeController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  // ── State ──────────────────────────────────────────────────────────────────
  var jobGrades = <Map<String, dynamic>>[].obs;
  var companies = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var isLoadingCompanies = false.obs;
  var errorMessage = ''.obs;

  // Search
  final searchController = TextEditingController();
  var searchQuery = ''.obs;
  Timer? _debounce;

  // Filter
  var selectedCompanyId = Rx<int?>(null);
  var filterIsActive = Rx<bool?>(null);

  // Pagination
  var currentPage = 1.obs;
  var lastPage = 1.obs;
  var total = 0.obs;

  var isExporting = false.obs;
  var isImporting = false.obs;

  // ── Form ───────────────────────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final gradeController = TextEditingController();
  final descriptionController = TextEditingController();
  final orderController = TextEditingController();
  var formCompanyId = Rx<int?>(null);
  var formIsActive = true.obs;
  var editingId = Rx<int?>(null);

  // ── Helper header ──────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_auth.token.value}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
    fetchAll();

    searchController.addListener(() {
      final q = searchController.text;
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (q != searchQuery.value) {
          searchQuery.value = q;
          fetchAll(page: 1);
        }
      });
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    codeController.dispose();
    nameController.dispose();
    gradeController.dispose();
    descriptionController.dispose();
    orderController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  // ── Fetch All ──────────────────────────────────────────────────────────────
  Future<void> fetchAll({int page = 1}) async {
    isLoading(true);
    errorMessage('');
    try {
      final baseUrl = await AppConfig.getBaseUrl();

      final params = <String, String>{'page': '$page', 'per_page': '15'};
      if (searchQuery.value.trim().isNotEmpty) {
        params['search'] = searchQuery.value.trim();
      }
      if (selectedCompanyId.value != null) {
        params['company_id'] = '${selectedCompanyId.value}';
      }
      if (filterIsActive.value != null) {
        params['is_active'] = filterIsActive.value! ? '1' : '0';
      }

      final uri = Uri.parse(
        '$baseUrl/admin/job-grades',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] ?? data;
        jobGrades.value = List<Map<String, dynamic>>.from(list);
        currentPage.value = data['current_page'] ?? 1;
        lastPage.value = data['last_page'] ?? 1;
        total.value = data['total'] ?? jobGrades.length;
      } else if (response.statusCode == 401) {
        await _auth.logout();
      } else {
        errorMessage('Gagal memuat data (${response.statusCode})');
      }
    } catch (e) {
      errorMessage('Koneksi error: $e');
      debugPrint('fetchAll job-grades error: $e');
    } finally {
      isLoading(false);
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchAll(page: 1);
  }

  // ── Fetch Companies ────────────────────────────────────────────────────────
  Future<void> fetchCompanies() async {
    isLoadingCompanies(true);
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final endpoints = [
        '$baseUrl/admin/companies-list',
        '$baseUrl/admin/companies',
      ];

      for (final url in endpoints) {
        try {
          final response = await http
              .get(Uri.parse(url), headers: _headers)
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            List<dynamic> list;
            if (decoded is List) {
              list = decoded;
            } else if (decoded is Map && decoded.containsKey('data')) {
              list = decoded['data'] as List;
            } else {
              continue;
            }
            companies.value = List<Map<String, dynamic>>.from(list);
            return;
          } else if (response.statusCode == 401) {
            await _auth.logout();
            return;
          }
        } catch (e) {
          debugPrint('fetchCompanies error pada $url: $e');
        }
      }

      Get.snackbar(
        'Peringatan',
        'Gagal memuat daftar perusahaan.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoadingCompanies(false);
    }
  }

  // ── Create / Update ────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (formCompanyId.value == null) {
      Get.snackbar(
        'Error',
        'Pilih perusahaan terlebih dahulu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isSubmitting(true);
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final body = jsonEncode({
        'company_id': formCompanyId.value,
        'code': codeController.text.trim(),
        'name': nameController.text.trim(),
        'grade': int.parse(gradeController.text.trim()),
        'description': descriptionController.text.trim(),
        'order': int.tryParse(orderController.text.trim()) ?? 0,
        'is_active': formIsActive.value,
      });

      final http.Response response;
      if (editingId.value == null) {
        response = await http
            .post(
              Uri.parse('$baseUrl/admin/job-grades'),
              headers: _headers,
              body: body,
            )
            .timeout(const Duration(seconds: 15));
      } else {
        response = await http
            .put(
              Uri.parse('$baseUrl/admin/job-grades/${editingId.value}'),
              headers: _headers,
              body: body,
            )
            .timeout(const Duration(seconds: 15));
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar(
          'Berhasil',
          editingId.value == null
              ? 'Job Grade berhasil ditambahkan'
              : 'Job Grade berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchAll(page: currentPage.value);
      } else {
        String msg = data['message'] ?? 'Gagal menyimpan';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          final first = errors.values.first;
          msg = (first is List) ? first.first.toString() : first.toString();
        }
        Get.snackbar(
          'Gagal',
          msg,
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
      isSubmitting(false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> delete(int id) async {
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http
          .delete(Uri.parse('$baseUrl/admin/job-grades/$id'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        Get.snackbar(
          'Berhasil',
          'Job Grade dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchAll(page: currentPage.value);
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'Gagal',
          data['message'] ?? 'Gagal menghapus',
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
    }
  }

  void confirmDelete(int id, String name) {
    Get.defaultDialog(
      title: 'Hapus Job Grade',
      middleText: 'Hapus "$name"?\nTindakan ini tidak bisa dibatalkan.',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        delete(id);
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // EXPORT
  // ─────────────────────────────────────────────────────────

  Future<void> exportJobGrades() async {
    isExporting.value = true;
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/job-grades/export'),
            headers: {
              'Authorization': 'Bearer ${_auth.token.value}',
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
            'job_grades_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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
        Get.snackbar(
          'Error',
          'Gagal export (${response.statusCode})',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on TimeoutException {
      Get.snackbar(
        'Error',
        'Export timeout. Coba lagi.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Export error: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // DOWNLOAD TEMPLATE
  // ─────────────────────────────────────────────────────────

  Future<void> downloadImportTemplate() async {
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/job-grades/import-template'),
            headers: {
              'Authorization': 'Bearer ${_auth.token.value}',
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

        final file = File('${dir.path}/template_import_job_grades.xlsx');
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
        Get.snackbar(
          'Error',
          'Gagal mengunduh template',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // IMPORT
  // ─────────────────────────────────────────────────────────

  Future<void> importJobGrades() async {
    // Request permission Android <= 32
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

      // Coba ambil bytes langsung
      if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
        fileBytes = pickedFile.bytes!;
      }
      // Fallback: baca dari path (file lokal)
      else if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        if (await file.exists()) {
          fileBytes = await file.readAsBytes();
        }
      }
    } catch (e) {
      // Tangkap PlatformException unknown_path (file dari Google Drive/cloud)
      _showError(
        'Gagal membaca file.\n\nPastikan file disimpan di storage lokal HP, bukan Google Drive atau cloud storage.',
      );
      return;
    }

    if (fileBytes == null || fileBytes.isEmpty) {
      _showError(
        'Tidak bisa membaca file.\n\nSimpan file ke storage lokal HP terlebih dahulu, lalu coba lagi.',
      );
      return;
    }

    // Validasi ekstensi manual
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
            Icon(Icons.upload_file, color: Colors.amber),
            SizedBox(width: 10),
            Text(
              'Import Job Grade',
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
              backgroundColor: Colors.amber.shade700,
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
      final baseUrl = await AppConfig.getBaseUrl();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/job-grades/import'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer ${_auth.token.value}',
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
                  backgroundColor: Colors.amber.shade700,
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

        if (success > 0) await fetchAll(page: 1);
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

  // ── Form Helpers ───────────────────────────────────────────────────────────
  void prepareCreate() {
    editingId.value = null;
    codeController.clear();
    nameController.clear();
    gradeController.clear();
    descriptionController.clear();
    orderController.text = '0';
    formCompanyId.value = selectedCompanyId.value;
    formIsActive.value = true;
  }

  void prepareEdit(Map<String, dynamic> item) {
    editingId.value = item['id'] as int?;
    codeController.text = item['code']?.toString() ?? '';
    nameController.text = item['name']?.toString() ?? '';
    gradeController.text = item['grade']?.toString() ?? '';
    descriptionController.text = item['description']?.toString() ?? '';
    orderController.text = item['order']?.toString() ?? '0';
    formCompanyId.value = item['company_id'] as int?;
    formIsActive.value = item['is_active'] == true || item['is_active'] == 1;
  }

  // ── Filter ─────────────────────────────────────────────────────────────────
  void applyFilter({int? companyId, bool? isActive}) {
    selectedCompanyId.value = companyId;
    filterIsActive.value = isActive;
    fetchAll(page: 1);
  }

  void resetFilter() {
    selectedCompanyId.value = null;
    filterIsActive.value = null;
    fetchAll(page: 1);
  }

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    backgroundColor: Colors.red,
    colorText: Colors.white,
  );

  bool get hasActiveFilter =>
      selectedCompanyId.value != null || filterIsActive.value != null;
}
