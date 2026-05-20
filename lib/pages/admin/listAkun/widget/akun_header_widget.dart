import 'package:flutter/material.dart';

class AkunHeaderWidget extends StatelessWidget {
  final int totalUsers;
  final int totalSuperAdmin;
  final int totalAdmin;
  final int totalHrd;
  final int totalManager;
  final int totalEmployee;

  const AkunHeaderWidget({
    super.key,
    required this.totalUsers,
    required this.totalSuperAdmin,
    required this.totalAdmin,
    required this.totalHrd,
    required this.totalManager,
    required this.totalEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeaderRow(),
            const SizedBox(height: 16),
            _buildStatistikRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.manage_accounts,
            color: Colors.blue,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manajemen Akun',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: $totalUsers akun terdaftar',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistikRow() {
    return Column(
      children: [
        // Baris 1: superadmin + admin + hrd
        Row(
          children: [
            _buildStatCard(
              icon: Icons.star,
              label: 'Superadmin',
              count: totalSuperAdmin,
              bgColor: Colors.purple.shade50,
              fgColor: Colors.purple.shade700,
              borderColor: Colors.purple.shade200,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              icon: Icons.admin_panel_settings,
              label: 'Admin',
              count: totalAdmin,
              bgColor: Colors.purple.shade50,
              fgColor: Colors.purple.shade600,
              borderColor: Colors.purple.shade100,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              icon: Icons.people,
              label: 'HRD',
              count: totalHrd,
              bgColor: Colors.teal.shade50,
              fgColor: Colors.teal.shade700,
              borderColor: Colors.teal.shade200,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Baris 2: manager + employee
        Row(
          children: [
            _buildStatCard(
              icon: Icons.business_center,
              label: 'Manager',
              count: totalManager,
              bgColor: Colors.orange.shade50,
              fgColor: Colors.orange.shade800,
              borderColor: Colors.orange.shade200,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              icon: Icons.person,
              label: 'Employee',
              count: totalEmployee,
              bgColor: Colors.blue.shade50,
              fgColor: Colors.blue.shade700,
              borderColor: Colors.blue.shade200,
            ),
            // Spacer agar 2 card di baris 2 lebarnya sama dengan baris 1
            const SizedBox(width: 8),
            Expanded(child: const SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color bgColor,
    required Color fgColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: fgColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
