import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/offline_absensi_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<UserController>(UserController(), permanent: true);
    Get.put(OfflineAbsensiController(), permanent: true);
  }
}
