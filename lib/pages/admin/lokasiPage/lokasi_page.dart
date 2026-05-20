import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/controllers/auth_controller.dart';
import 'package:myabsensi_mobile/controllers/employee_pusat_lokasi_controller.dart';
import 'package:myabsensi_mobile/pages/admin/lokasiPage/widget/lokasi_table_widget.dart';
import 'package:myabsensi_mobile/pages/admin/master_drawer.dart';
import 'package:get/get.dart';

class LokasiPage extends StatelessWidget {
  const LokasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    if (!Get.isRegistered<EmployeePusatLokasiController>()) {
      Get.put(EmployeePusatLokasiController());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lokasi Karyawan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final controller = Get.find<EmployeePusatLokasiController>();
              controller.fetchEmployeeLokasi();
              controller.fetchEmployees();
              controller.fetchPusatLokasi();
              Get.snackbar(
                'Sukses',
                'Data diperbarui',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 1),
              );
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: const MasterDrawer(currentPage: 'lokasi'),
      body: Obx(() {
        if (auth.token.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Silahkan login terlebih dahulu',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final controller = Get.find<EmployeePusatLokasiController>();
            await controller.fetchEmployeeLokasi();
            await controller.fetchEmployees();
            await controller.fetchPusatLokasi();
          },
          color: Colors.blue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final ctrl = Get.find<EmployeePusatLokasiController>();

              // Saat loading: tampilkan full-page modern loading state
              if (ctrl.isLoading.value) {
                return const _ModernLoadingState();
              }

              // Setelah data tersedia: tampilkan tabel + statistik
              return Column(
                children: [
                  const LokasiTableWidget(),
                  const SizedBox(height: 20),
                  _buildStatistikCard(ctrl),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildStatistikCard(EmployeePusatLokasiController controller) {
    final totalLokasi = controller.employeeLokasis.length;

    final Set<int> uniqueEmployees = {};
    for (var lokasi in controller.employeeLokasis) {
      final empId = lokasi['employee_id'];
      if (empId != null) uniqueEmployees.add(empId);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stacked_bar_chart,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: $totalLokasi lokasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${uniqueEmployees.length} karyawan terdaftar',
                  style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modern Loading State ────────────────────────────────────────
class _ModernLoadingState extends StatefulWidget {
  const _ModernLoadingState();

  @override
  State<_ModernLoadingState> createState() => _ModernLoadingStateState();
}

class _ModernLoadingStateState extends State<_ModernLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer
        _shimmerBox(height: 14, width: 120, radius: 7),
        const SizedBox(height: 12),
        // Search bar shimmer
        _shimmerBox(height: 48, width: double.infinity, radius: 12),
        const SizedBox(height: 16),
        // Card shimmers
        ...List.generate(
          6,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ShimmerCard(delay: i * 80),
          ),
        ),
        const SizedBox(height: 16),
        // Pagination shimmer
        Center(
          child: AnimatedBuilder(
            animation: _fadeAnim,
            builder: (_, __) => Opacity(
              opacity: _fadeAnim.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Statistik card shimmer
        _shimmerBox(height: 72, width: double.infinity, radius: 12),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _shimmerBox({
    required double height,
    required double width,
    required double radius,
  }) {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (_, __) => Opacity(
        opacity: _fadeAnim.value,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final int delay;
  const _ShimmerCard({this.delay = 0});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Start with a delay for staggered effect
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });

    _anim = Tween<double>(
      begin: 0.45,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // Text skeletons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 18,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action button skeletons
              Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 32,
                    height: 32,
                    margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
