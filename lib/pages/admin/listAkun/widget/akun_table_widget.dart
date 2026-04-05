// import 'package:flutter/material.dart';
// import 'package:frontend_flutter/controllers/user_controller.dart';
// import 'package:frontend_flutter/pages/admin/listAkun/modals/delete_user_confirmation.dart';
// import 'package:frontend_flutter/pages/admin/listAkun/widget/akun_empty_widget.dart';

// class AkunTableWidget extends StatelessWidget {
//   final UserController userController;

//   const AkunTableWidget({super.key, required this.userController});

//   @override
//   Widget build(BuildContext context) {
//     if (userController.users.isEmpty) {
//       return const AkunEmptyWidget();
//     }

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: SingleChildScrollView(
//           scrollDirection: Axis.vertical,
//           child: DataTable(
//             headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
//             headingTextStyle: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.blue.shade700,
//             ),
//             columnSpacing: 20,
//             horizontalMargin: 16,
//             columns: const [
//               DataColumn(label: Text('No')),
//               DataColumn(label: Text('Nama')),
//               DataColumn(label: Text('Email')),
//               DataColumn(label: Text('Role')),
//               DataColumn(label: Text('Aksi')),
//             ],
//             rows: List.generate(userController.users.length, (index) {
//               final user = userController.users[index];
//               return DataRow(
//                 cells: [
//                   DataCell(
//                     Container(
//                       width: 24,
//                       height: 24,
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           '${index + 1}',
//                           style: TextStyle(
//                             color: Colors.blue.shade700,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   DataCell(
//                     Text(
//                       user.name,
//                       style: const TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                   ),
//                   DataCell(Text(user.email)),
//                   DataCell(_buildRoleBadge(user.role)),
//                   DataCell(
//                     IconButton(
//                       icon: Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           color: Colors.red.shade50,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.delete,
//                           color: Colors.red,
//                           size: 18,
//                         ),
//                       ),
//                       onPressed: () {
//                         DeleteUserConfirmation.show(
//                           context: context,
//                           userName: user.name,
//                           userId: user.id,
//                           userController: userController,
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               );
//             }),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRoleBadge(String role) {
//     final isAdmin = role == 'admin';
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: isAdmin ? Colors.purple.shade50 : Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isAdmin ? Icons.admin_panel_settings : Icons.person,
//             size: 12,
//             color: isAdmin ? Colors.purple : Colors.blue,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             role,
//             style: TextStyle(
//               color: isAdmin ? Colors.purple : Colors.blue,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/user_controller.dart';
import 'package:myabsensi_mobile/pages/admin/listAkun/modals/delete_user_confirmation.dart';
import 'package:get/get.dart';

class AkunTableWidget extends StatelessWidget {
  final UserController userController;

  const AkunTableWidget({super.key, required this.userController});

  @override
  Widget build(BuildContext context) {
    if (userController.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Data user kosong',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
            columnSpacing: 20,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: List.generate(userController.users.length, (index) {
              final user = userController.users[index];

              // CEK APAKAH INI SUPER ADMIN (TIDAK BISA DIHAPUS)
              final bool isSuperAdmin = user.email == 'superadmin@absensi.com';

              return DataRow(
                cells: [
                  // Nomor
                  DataCell(
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Nama
                  DataCell(
                    Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSuperAdmin ? Colors.purple : Colors.black87,
                      ),
                    ),
                  ),

                  // Email
                  DataCell(
                    Text(
                      user.email,
                      style: TextStyle(
                        color: isSuperAdmin ? Colors.purple : Colors.black87,
                      ),
                    ),
                  ),

                  // Role
                  DataCell(_buildRoleBadge(user.role, isSuperAdmin)),

                  // Aksi (Hapus)
                  DataCell(
                    isSuperAdmin
                        ? _buildDisabledDeleteButton() // Super admin tidak bisa dihapus
                        : _buildDeleteButton(context, user),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ================= BADGE ROLE =================
  Widget _buildRoleBadge(String role, bool isSuperAdmin) {
    final bool isAdmin = role == 'admin';

    // Super admin mendapat badge khusus
    if (isSuperAdmin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 14,
              color: Colors.purple.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              'SUPER ADMIN',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Admin biasa
    if (isAdmin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings, size: 12, color: Colors.purple),
            const SizedBox(width: 4),
            Text(
              'admin',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // User biasa
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            'user',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ================= TOMBOL DELETE (AKTIF) =================
  Widget _buildDeleteButton(BuildContext context, dynamic user) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.delete, color: Colors.red, size: 18),
      ),
      onPressed: () {
        DeleteUserConfirmation.show(
          context: context,
          userName: user.name,
          userId: user.id,
          userController: userController,
        );
      },
      tooltip: 'Hapus User',
    );
  }

  // ================= TOMBOL DELETE (NONAKTIF UNTUK SUPER ADMIN) =================
  Widget _buildDisabledDeleteButton() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.delete, color: Colors.grey, size: 18),
      ),
      onPressed: null, // Nonaktifkan
      tooltip: 'Akun Super Admin tidak dapat dihapus',
    );
  }
}
