import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/employee_import_export_controller.dart';
import '../../../controllers/employee_controller.dart';

/// Widget sheet yang muncul saat tombol ⬆⬇ ditekan di EmployeeListPage.
/// Menyediakan: Export, Download Template, Import.
class EmployeeImportExportSheet extends StatelessWidget {
  final EmployeeController employeeCtrl;

  const EmployeeImportExportSheet({super.key, required this.employeeCtrl});

  @override
  Widget build(BuildContext context) {
    // Lazy-init controller
    final ctrl = Get.put(EmployeeImportExportController());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          const Text(
            'Export / Import Karyawan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola data karyawan secara massal via Excel',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // ── Export ──────────────────────────────────────────────────────
          _SectionLabel('Export'),
          const SizedBox(height: 8),
          Obx(
            () => _ActionTile(
              icon: Icons.download_rounded,
              iconColor: Colors.green,
              title: 'Download Data Karyawan (.xlsx)',
              subtitle: 'Export semua/filter karyawan saat ini',
              loading: ctrl.isExporting.value,
              onTap: () {
                Navigator.pop(context);
                ctrl.exportEmployees(
                  search: employeeCtrl.searchQuery.value.isNotEmpty
                      ? employeeCtrl.searchQuery.value
                      : null,
                  companyId: employeeCtrl.filterCompanyId.value,
                  departmentId: employeeCtrl.filterDepartmentId.value,
                  jobLevelId: employeeCtrl.filterJobLevelId.value,
                  jobGradeId: employeeCtrl.filterJobGradeId.value,
                  employmentType: employeeCtrl.filterEmploymentType.value,
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── Import ──────────────────────────────────────────────────────
          _SectionLabel('Import'),
          const SizedBox(height: 8),

          _ActionTile(
            icon: Icons.file_download_outlined,
            iconColor: Colors.blue,
            title: 'Download Template Import',
            subtitle: 'Unduh file template Excel yang sudah berformat',
            onTap: () {
              Navigator.pop(context);
              ctrl.downloadTemplate();
            },
          ),

          const SizedBox(height: 8),

          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActionTile(
                  icon: Icons.upload_file_rounded,
                  iconColor: Colors.orange,
                  title: 'Upload File Import (.xlsx)',
                  subtitle: 'Maksimal 500 baris per file',
                  loading: ctrl.isImporting.value,
                  onTap: () {
                    Navigator.pop(context);
                    ctrl.importEmployees(
                      onSuccess: () => employeeCtrl.fetchEmployees(reset: true),
                    );
                  },
                ),
                if (ctrl.isImporting.value) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => LinearProgressIndicator(
                            value: ctrl.importProgress.value,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mengupload dan memproses data...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Catatan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gunakan template yang disediakan agar format sesuai. '
                    'NIK, KTP, NPWP, dan BPJS harus unik.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey.shade500,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!loading)
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
