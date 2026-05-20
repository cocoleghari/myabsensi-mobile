import 'package:get/get.dart';
import '../controllers/employee_pusat_lokasi_controller.dart';

class EmployeePusatLokasiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeePusatLokasiController>(
      () => EmployeePusatLokasiController(),
      fenix: true,
    );
  }
}
