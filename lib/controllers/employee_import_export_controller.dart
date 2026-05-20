import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'app_config.dart';
import 'auth_controller.dart';

class EmployeeImportExportController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  var isExporting = false.obs;
  var isImporting = false.obs;
  var importProgress = 0.0.obs;

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

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_auth.token.value}',
  };

  // ─── Export ──────────────────────────────────────

  Future<void> exportEmployees({
    String? search,
    int? companyId,
    int? departmentId,
    int? jobLevelId, // ← tambah
    int? jobGradeId, // ← tambah
    String? employmentType,
  }) async {
    try {
      isExporting.value = true;
      final baseUrl = await _resolvedBaseUrl;

      final params = <String, String>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (companyId != null) 'company_id': companyId.toString(),
        if (departmentId != null) 'department_id': departmentId.toString(),
        if (jobLevelId != null)
          'job_level_id': jobLevelId.toString(), // ← tambah
        if (jobGradeId != null)
          'job_grade_id': jobGradeId.toString(), // ← tambah
        if (employmentType != null) 'employment_type': employmentType,
      };

      final uri = Uri.parse(
        '$baseUrl/admin/employees/export',
      ).replace(queryParameters: params.isNotEmpty ? params : null);

      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 60));

      if (res.statusCode == 200) {
        final dir = Platform.isAndroid
            ? await getExternalStorageDirectory()
            : await getApplicationDocumentsDirectory();

        final filename =
            'employees_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File('${dir!.path}/$filename');
        await file.writeAsBytes(res.bodyBytes);

        Get.snackbar(
          'Export Berhasil',
          'File disimpan: $filename',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () => OpenFile.open(file.path),
            child: const Text('Buka', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        _handleError(res);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Export gagal: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  // ─── Download Template ───────────────────────────

  Future<void> downloadTemplate() async {
    try {
      isExporting.value = true;
      final baseUrl = await _resolvedBaseUrl;

      final res = await http
          .get(
            Uri.parse('$baseUrl/admin/employees/import-template'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final dir = Platform.isAndroid
            ? await getExternalStorageDirectory()
            : await getApplicationDocumentsDirectory();

        final file = File('${dir!.path}/employee_import_template.xlsx');
        await file.writeAsBytes(res.bodyBytes);

        Get.snackbar(
          'Template Diunduh',
          'Buka dan isi template, lalu upload kembali.',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => OpenFile.open(file.path),
            child: const Text('Buka', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        _handleError(res);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Download template gagal: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  // ─── Import ──────────────────────────────────────

  Future<void> importEmployees({VoidCallback? onSuccess}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    try {
      isImporting.value = true;
      importProgress.value = 0.1;

      final baseUrl = await _resolvedBaseUrl;

      final req =
          http.MultipartRequest(
              'POST',
              Uri.parse('$baseUrl/admin/employees/import'),
            )
            ..headers.addAll(_headers)
            ..files.add(await http.MultipartFile.fromPath('file', filePath));

      importProgress.value = 0.4;
      final streamed = await req.send().timeout(const Duration(seconds: 120));
      importProgress.value = 0.8;

      final res = await http.Response.fromStream(streamed);
      importProgress.value = 1.0;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final importResults = body['results'] as Map<String, dynamic>?;

      if (res.statusCode == 200 || res.statusCode == 207) {
        final success = importResults?['success'] ?? 0;
        final failed = importResults?['failed'] ?? 0;
        final errors = importResults?['errors'] as List? ?? [];

        if (failed == 0) {
          Get.snackbar(
            'Import Berhasil',
            '$success karyawan berhasil diimport.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } else {
          _showImportErrorSheet(success, failed, errors);
        }

        onSuccess?.call();
      } else {
        Get.snackbar(
          'Import Gagal',
          body['message'] ?? 'Terjadi kesalahan',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Import gagal: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isImporting.value = false;
      importProgress.value = 0;
    }
  }

  // ─── Helpers ─────────────────────────────────────

  void _showImportErrorSheet(int success, int failed, List errors) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Hasil Import',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statChip('$success Berhasil', Colors.green),
                const SizedBox(width: 8),
                _statChip('$failed Gagal', Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Detail error:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: errors.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = errors[i] as Map;
                  final errs = (e['errors'] as List).join(', ');
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red.shade50,
                      child: Text(
                        '${e['row']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    title: Text(
                      e['name'] ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(errs, style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Get.back(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _handleError(http.Response res) {
    try {
      final err = jsonDecode(res.body);
      Get.snackbar(
        'Gagal',
        err['message'] ?? 'Status ${res.statusCode}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Status ${res.statusCode}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
