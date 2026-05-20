import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myabsensi_mobile/controllers/user_controller.dart';
import 'package:myabsensi_mobile/models/user_model.dart';
import 'package:myabsensi_mobile/pages/admin/listAkun/modals/delete_user_confirmation.dart';
import 'package:myabsensi_mobile/pages/admin/listAkun/modals/edit_user_dialog.dart';

class AkunTableWidget extends StatefulWidget {
  final UserController userController;

  const AkunTableWidget({super.key, required this.userController});

  @override
  State<AkunTableWidget> createState() => _AkunTableWidgetState();
}

class _AkunTableWidgetState extends State<AkunTableWidget> {
  final ScrollController _scrollController = ScrollController();

  // ✅ Tambah TextEditingController agar nilai tidak hilang saat rebuild
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // ✅ Sinkron nilai awal jika searchQuery sudah ada
    _searchController.text = widget.userController.searchQuery.value;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose(); // ✅ dispose
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      widget.userController.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          // ✅ TextField di LUAR GetX — tidak ikut rebuild saat search berubah
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchController, // ✅ pakai TextEditingController
              onChanged: (val) => widget.userController.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: 'Cari nama, email, atau role...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey,
                ),
                suffixIcon: Obx(
                  () => widget.userController.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            widget.userController.searchQuery.value = '';
                            _searchController.clear(); // ✅ clear keduanya
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // ✅ Obx kecil hanya untuk loading indicator
          Obx(
            () => widget.userController.isFetchingMore.value
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.blue.shade300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memuat data... '
                          '(${widget.userController.users.length} akun)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Header tidak perlu reaktif — statis saja
          _buildHeader(),

          // ✅ GetX hanya membungkus LIST — TextField sudah aman di atas
          Expanded(
            child: GetX<UserController>(
              builder: (controller) {
                final users = controller.filteredUsers;

                if (users.isEmpty) {
                  // ✅ Bedakan: data kosong vs hasil search kosong
                  if (controller.searchQuery.value.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada hasil untuk\n'
                            '"${controller.searchQuery.value}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Data memang kosong (bukan karena search)
                  if (!controller.isLoading.value &&
                      !controller.isFetchingMore.value) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Data user kosong',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildRow(context, users[index], index + 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              'No',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Nama',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Email',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Role',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'Aksi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ROW DATA
  // ════════════════════════════════════════════════════════════════════

  Widget _buildRow(BuildContext context, UserModel user, int index) {
    final bool isSuperAdmin = user.role == 'superadmin';
    final bool isActive = user.isActive == true || user.isActive == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: isSuperAdmin ? Colors.purple.shade700 : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(flex: 2, child: _buildRoleBadge(user.role)),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditButton(context, user),
                isSuperAdmin
                    ? _buildDisabledDeleteButton()
                    : _buildDeleteButton(context, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ROLE BADGE
  // ════════════════════════════════════════════════════════════════════

  Widget _buildRoleBadge(String role) {
    switch (role) {
      case 'superadmin':
        return _roleBadge(
          icon: Icons.star,
          label: 'superadmin',
          bgColor: Colors.purple.shade50,
          fgColor: Colors.purple.shade800,
        );
      case 'admin':
        return _roleBadge(
          icon: Icons.admin_panel_settings,
          label: 'admin',
          bgColor: Colors.purple.shade50,
          fgColor: Colors.purple.shade600,
        );
      case 'hrd':
        return _roleBadge(
          icon: Icons.people,
          label: 'hrd',
          bgColor: Colors.teal.shade50,
          fgColor: Colors.teal.shade700,
        );
      case 'manager':
        return _roleBadge(
          icon: Icons.business_center,
          label: 'manager',
          bgColor: Colors.orange.shade50,
          fgColor: Colors.orange.shade800,
        );
      default:
        return _roleBadge(
          icon: Icons.person,
          label: role.isEmpty ? 'employee' : role,
          bgColor: Colors.blue.shade50,
          fgColor: Colors.blue.shade700,
        );
    }
  }

  Widget _roleBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fgColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ════════════════════════════════════════════════════════════════════

  Widget _buildEditButton(BuildContext context, UserModel user) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.edit, color: Colors.blue.shade700, size: 16),
        ),
        onPressed: () => EditUserDialog.show(
          context: context,
          user: user,
          userController: widget.userController,
        ),
        tooltip: 'Edit User',
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, UserModel user) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete, color: Colors.red, size: 16),
        ),
        onPressed: () => DeleteUserConfirmation.show(
          context: context,
          userName: user.name,
          userId: user.id,
          userController: widget.userController,
        ),
        tooltip: 'Hapus User',
      ),
    );
  }

  Widget _buildDisabledDeleteButton() {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete, color: Colors.grey, size: 16),
        ),
        onPressed: null,
        tooltip: 'Akun superadmin tidak dapat dihapus',
      ),
    );
  }
}
