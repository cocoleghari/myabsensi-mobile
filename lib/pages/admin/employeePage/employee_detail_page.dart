import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/employee_controller.dart';
import '../../../models/employee_model.dart';
import 'employee_form_page.dart';

class EmployeeDetailPage extends StatefulWidget {
  final int employeeId;
  const EmployeeDetailPage({super.key, required this.employeeId});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  final _ctrl = Get.find<EmployeeController>();
  EmployeeModel? _employee;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final emp = await _ctrl.fetchEmployee(widget.employeeId);
    setState(() {
      _employee = emp;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_employee?.displayName ?? 'Detail Karyawan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_employee != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Get.to(
                  () => EmployeeFormPage(employee: _employee),
                );
                if (result == true) _load();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employee == null
          ? const Center(child: Text('Data tidak ditemukan'))
          : _buildDetail(_employee!),
    );
  }

  Widget _buildDetail(EmployeeModel e) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.blue,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: e.photoUrl != null
                      ? NetworkImage(e.photoUrl!)
                      : null,
                  child: e.photoUrl == null
                      ? Text(
                          e.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  e.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (e.employeeCode != null)
                  Text(
                    e.employeeCode!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (e.departmentName != null)
                      _headerChip(e.departmentName!),
                    if (e.positionName != null) ...[
                      const SizedBox(width: 8),
                      _headerChip(e.positionName!),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Sections ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Identitas', [
                  _row('Nama Lengkap', e.fullName),
                  if (e.nickname != null) _row('Nama Panggilan', e.nickname!),
                  if (e.nik != null) _row('NIK', e.nik!),
                  if (e.ktpNumber != null) _row('No. KTP', e.ktpNumber!),
                  // gender disimpan sebagai 'male'/'female' — tampilkan label
                  if (e.gender != null)
                    _row('Jenis Kelamin', _labelGender(e.gender!)),
                  if (e.placeOfBirth != null)
                    _row('Tempat Lahir', e.placeOfBirth!),
                  if (e.dateOfBirth != null)
                    _row('Tgl Lahir', _formatDate(e.dateOfBirth!)),
                  if (e.maritalStatus != null)
                    _row('Status Nikah', _labelMarital(e.maritalStatus!)),
                  if (e.religion != null) _row('Agama', e.religion!),
                  if (e.bloodType != null) _row('Gol. Darah', e.bloodType!),
                ]),
                _section('Kepegawaian', [
                  if (e.companyName != null) _row('Perusahaan', e.companyName!),
                  if (e.departmentName != null)
                    _row('Departemen', e.departmentName!),
                  if (e.positionName != null) _row('Jabatan', e.positionName!),
                  if (e.jobLevelName != null)
                    _row('Job Level', e.jobLevelName!),
                  if (e.jobGradeName != null)
                    _row(
                      'Job Grade',
                      e.jobGradeCode != null
                          ? '${e.jobGradeName} (${e.jobGradeCode})'
                          : e.jobGradeName!,
                    ),
                  if (e.statusName != null) _row('Status', e.statusName!),
                  if (e.employmentType != null)
                    _row('Tipe', _labelEmploymentType(e.employmentType!)),
                  if (e.joinDate != null)
                    _row('Bergabung', _formatDate(e.joinDate!)),
                  if (e.contractEndDate != null)
                    _row('Akhir Kontrak', _formatDate(e.contractEndDate!)),
                  if (e.resignDate != null)
                    _row('Resign', _formatDate(e.resignDate!)),
                ]),
                _section('Kontak', [
                  if (e.phone != null) _row('Telepon', e.phone!),
                  if (e.address != null) _row('Alamat', e.address!),
                  if (e.city != null) _row('Kota', e.city!),
                  if (e.province != null) _row('Provinsi', e.province!),
                  if (e.postalCode != null) _row('Kode Pos', e.postalCode!),
                ]),
                _section('Kontak Darurat', [
                  if (e.emergencyContactName != null)
                    _row('Nama', e.emergencyContactName!),
                  if (e.emergencyContactPhone != null)
                    _row('Telepon', e.emergencyContactPhone!),
                  if (e.emergencyContactRelation != null)
                    _row('Hubungan', e.emergencyContactRelation!),
                ]),
                _section('Data Finansial', [
                  if (e.npwp != null) _row('NPWP', e.npwp!),
                  if (e.bpjsKesehatan != null)
                    _row('BPJS Kesehatan', e.bpjsKesehatan!),
                  if (e.bpjsKetenagakerjaan != null)
                    _row('BPJS TK', e.bpjsKetenagakerjaan!),
                  if (e.bankName != null) _row('Bank', e.bankName!),
                  if (e.bankAccountNumber != null)
                    _row('No. Rek', e.bankAccountNumber!),
                  if (e.bankAccountName != null)
                    _row('Nama Rek', e.bankAccountName!),
                ]),
                _section('Pendidikan', [
                  if (e.lastEducation != null)
                    _row('Jenjang', _labelEducation(e.lastEducation!)),
                  if (e.lastEducationMajor != null)
                    _row('Jurusan', e.lastEducationMajor!),
                  if (e.lastEducationInstitution != null)
                    _row('Institusi', e.lastEducationInstitution!),
                ]),
                _section('Wajah', [
                  _row(
                    'Status',
                    e.wajahTerdaftar
                        ? '✓ Sudah terdaftar'
                        : '✗ Belum terdaftar',
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Label helpers ─────────────────────────────────

  /// Konversi nilai enum 'male'/'female' ke label tampilan
  String _labelGender(String value) {
    const map = {'male': 'Laki-laki', 'female': 'Perempuan'};
    return map[value] ?? value;
  }

  String _labelMarital(String value) {
    const map = {
      'single': 'Belum Menikah',
      'married': 'Menikah',
      'divorced': 'Cerai',
      'widowed': 'Janda/Duda',
    };
    return map[value] ?? value;
  }

  /// employment_type: permanent|contract|intern|freelance
  String _labelEmploymentType(String value) {
    const map = {
      'permanent': 'Tetap',
      'contract': 'Kontrak',
      'intern': 'Magang',
      'freelance': 'Freelance',
    };
    return map[value] ?? value;
  }

  /// last_education enum sesuai migration
  String _labelEducation(String value) {
    const map = {
      'sd': 'SD',
      'smp': 'SMP',
      'sma': 'SMA / SMK',
      'd1': 'D1',
      'd2': 'D2',
      'd3': 'D3',
      'd4': 'D4',
      's1': 'S1',
      's2': 'S2',
      's3': 'S3',
    };
    return map[value] ?? value.toUpperCase();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  // ── UI helpers ────────────────────────────────────

  Widget _headerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
