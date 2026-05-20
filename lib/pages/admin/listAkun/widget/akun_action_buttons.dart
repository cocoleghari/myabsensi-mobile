import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/user_controller.dart';
import 'package:get/get.dart';

class AkunActionButtons extends StatelessWidget {
  final UserController userController;
  final VoidCallback onTambahUser;

  const AkunActionButtons({
    super.key,
    required this.userController,
    required this.onTambahUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: userController.fetchUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              side: BorderSide(color: Colors.blue.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onTambahUser,
            icon: const Icon(Icons.person_add),
            label: const Text('Tambah User/Admin'), // UBAH NAMA BUTTON
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }
}
