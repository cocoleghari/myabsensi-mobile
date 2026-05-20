// bindings/company_binding.dart
import 'package:get/get.dart';
import '../controllers/employee_status_controller.dart';

class EmployeeStatusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeStatusController>(() => EmployeeStatusController());
  }
}
