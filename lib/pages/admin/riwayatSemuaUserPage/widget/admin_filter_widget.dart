import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/admin_absensi_controller.dart';
import 'package:get/get.dart';

class AdminFilterWidget extends StatelessWidget {
  final AdminAbsensiController controller;

  const AdminFilterWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter User',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),

          Obx(() {
            if (controller.semuaEmployees.isEmpty) {
              return const Center(child: Text('Tidak ada data user'));
            }

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Pilih User',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(Icons.person, size: 18),
                    ),
                    value: controller.selectedEmployeeId.value.isEmpty
                        ? null
                        : controller.selectedEmployeeId.value,
                    hint: const Text('Semua User'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Semua User'),
                      ),
                      ...controller.semuaEmployees.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'].toString(),
                          child: Text(user['name'] ?? 'Unknown'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      controller.filterByEmployee(value ?? '');
                    },
                  ),
                ),
                if (controller.selectedEmployeeId.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: controller.resetFilter,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
