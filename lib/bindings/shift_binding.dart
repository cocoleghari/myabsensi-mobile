// bindings/company_binding.dart
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';

class ShiftBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShiftController>(() => ShiftController());
  }
}
