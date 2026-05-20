// bindings/company_binding.dart
import 'package:get/get.dart';
import '../controllers/employee_controller.dart';

class EmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<EmployeeController>(EmployeeController());
  }
}
