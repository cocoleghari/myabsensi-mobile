import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:get/get.dart';

class GantiPasswordModal {
  static void show(BuildContext context) {
    final authController = Get.find<AuthController>();

    final bool isAdmin = authController.isAdmin;

    final currentPassC = TextEditingController();
    final newPassC = TextEditingController();
    final confirmPassC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isCurrentPasswordVisible = false.obs;
    final isNewPasswordVisible = false.obs;
    final isConfirmPasswordVisible = false.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        color: isAdmin ? Colors.orange : Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin ? 'Ganti Password Admin' : 'Ganti Password',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAdmin
                                ? 'Ubah password admin Anda'
                                : 'Ubah password akun Anda',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Obx(
                  () => TextFormField(
                    controller: currentPassC,
                    obscureText: !isCurrentPasswordVisible.value,
                    decoration: InputDecoration(
                      labelText: 'Password Saat Ini *',
                      hintText: 'Masukkan password lama',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isCurrentPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          isCurrentPasswordVisible.value =
                              !isCurrentPasswordVisible.value;
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password saat ini wajib diisi';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                Obx(
                  () => TextFormField(
                    controller: newPassC,
                    obscureText: !isNewPasswordVisible.value,
                    decoration: InputDecoration(
                      labelText: 'Password Baru *',
                      hintText: 'Minimal 6 karakter',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.blue,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNewPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          isNewPasswordVisible.value =
                              !isNewPasswordVisible.value;
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password baru wajib diisi';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      if (value == currentPassC.text) {
                        return 'Password baru harus berbeda dari password lama';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                Obx(
                  () => TextFormField(
                    controller: confirmPassC,
                    obscureText: !isConfirmPasswordVisible.value,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru *',
                      hintText: 'Ulangi password baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.blue,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          isConfirmPasswordVisible.value =
                              !isConfirmPasswordVisible.value;
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (value != newPassC.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAdmin
                          ? Colors.orange.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isAdmin ? Colors.orange : Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Password minimal 6 karakter dan akan dienkripsi',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAdmin ? Colors.orange : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: Obx(() {
                    final isLoading = authController.isLoading.value;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                Get.back();

                                bool success;
                                if (isAdmin) {
                                  success = await authController
                                      .changePasswordAdmin(
                                        currentPassword: currentPassC.text,
                                        newPassword: newPassC.text,
                                        confirmPassword: confirmPassC.text,
                                      );
                                } else {
                                  success = await authController.changePassword(
                                    currentPassword: currentPassC.text,
                                    newPassword: newPassC.text,
                                    confirmPassword: confirmPassC.text,
                                  );
                                }

                                if (success) {
                                  currentPassC.clear();
                                  newPassC.clear();
                                  confirmPassC.clear();
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isAdmin ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        isLoading ? 'MEMPROSES...' : 'UBAH PASSWORD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      enableDrag: false,
    );
  }
}
