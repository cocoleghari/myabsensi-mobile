import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/user_controller.dart';
import 'package:get/get.dart';

class DeleteUserConfirmation {
  static void show({
    required BuildContext context,
    required String userName,
    required int userId,
    required UserController userController,
  }) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Hapus User',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus user "$userName"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await userController.deleteUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
