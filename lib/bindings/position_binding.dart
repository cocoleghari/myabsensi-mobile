// lib/bindings/position_binding.dart
import 'package:get/get.dart';
import '../controllers/position_controller.dart';

class PositionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PositionController>(() => PositionController());
  }
}
