import '../../../../controllers/employee_pusat_lokasi_controller.dart';

class LokasiHelpers {
  /// Jumlah relasi yang memiliki employee_id dan pusat_lokasi_id valid (tidak null/0)
  static int getValidEntriesCount(EmployeePusatLokasiController controller) {
    return controller.employeeLokasis.where((entry) {
      final employeeId = entry['employee_id'];
      final pusatLokasiId = entry['pusat_lokasi_id'];
      return employeeId != null &&
          employeeId != 0 &&
          pusatLokasiId != null &&
          pusatLokasiId != 0;
    }).length;
  }

  /// Nama karyawan berdasarkan employee_id dari list employees
  static String getEmployeeName(
    EmployeePusatLokasiController controller,
    int employeeId,
  ) {
    return controller.getEmployeeName(employeeId);
  }

  /// Nama pusat lokasi berdasarkan pusat_lokasi_id
  static String getPusatLokasiName(
    EmployeePusatLokasiController controller,
    int pusatLokasiId,
  ) {
    try {
      final lokasi = controller.pusatLokasis.firstWhere(
        (e) => e['id'] == pusatLokasiId,
        orElse: () => {},
      );
      if (lokasi.isEmpty) return 'Unknown';
      return lokasi['nama'] ?? lokasi['name'] ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Cek apakah controller sedang loading atau submitting
  static bool isBusy(EmployeePusatLokasiController controller) {
    return controller.isLoading.value || controller.isSubmitting.value;
  }

  /// Jumlah relasi milik satu karyawan dari data yang sudah di-load
  static int getEntriesCountByEmployee(
    EmployeePusatLokasiController controller,
    int employeeId,
  ) {
    return controller.employeeLokasis
        .where((entry) => entry['employee_id'] == employeeId)
        .length;
  }
}
