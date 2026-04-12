import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/rekam_aktivitas_controller.dart';

class RekamAktivitasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RekamAktivitasController>(() => RekamAktivitasController());
  }
}

class RekamAktivitasFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RekamAktivitasFormController>(
      () => RekamAktivitasFormController(),
    );
  }
}
