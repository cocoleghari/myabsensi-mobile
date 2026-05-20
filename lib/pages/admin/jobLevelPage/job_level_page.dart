import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/job_level_controller.dart'; // sesuaikan path
import '../master_drawer.dart'; // sesuaikan path
import 'job_level_form_page.dart'; // sesuaikan path

class JobLevelPage extends StatelessWidget {
  const JobLevelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(JobLevelController());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Job Level',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Obx(
            () => IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list),
                  if (c.hasActiveFilter)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showFilterSheet(context, c),
              tooltip: 'Filter',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => c.fetchAll(page: 1),
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const MasterDrawer(currentPage: 'job-levels'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          c.prepareCreate();
          Get.to(() => const JobLevelFormPage());
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _SearchBar(c: c),
          _ActiveFilterChips(c: c),
          Expanded(child: _Body(c: c)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final JobLevelController c;
  const _SearchBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Obx(
        () => TextField(
          controller: c.searchController,
          decoration: InputDecoration(
            hintText: 'Cari nama level...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            suffixIcon: c.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade500),
                    onPressed: c.clearSearch,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.teal.shade300, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final JobLevelController c;
  const _Body({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (c.errorMessage.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(c.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: () => c.fetchAll(page: 1),
                    child: const Text('Coba Lagi')),
              ],
            ),
          ),
        );
      }
      if (c.jobLevels.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.layers_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                c.searchQuery.value.isNotEmpty
                    ? 'Tidak ada hasil untuk\n"${c.searchQuery.value}"'
                    : 'Belum ada data Job Level',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              if (c.searchQuery.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: c.clearSearch,
                  icon: const Icon(Icons.close),
                  label: const Text('Hapus pencarian'),
                ),
              ],
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => c.fetchAll(page: c.currentPage.value),
        child: Column(
          children: [
            if (c.searchQuery.value.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.teal.shade50,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Text(
                  'Ditemukan ${c.total.value} hasil untuk "${c.searchQuery.value}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: c.jobLevels.length,
                itemBuilder: (_, i) =>
                    _JobLevelCard(item: c.jobLevels[i], c: c),
              ),
            ),
            _Pagination(c: c),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD
// ─────────────────────────────────────────────────────────────────────────────
class _JobLevelCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final JobLevelController c;
  const _JobLevelCard({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    final isActive = item['is_active'] == true;
    final companyName =
        item['company']?['name'] ?? 'Perusahaan #${item['company_id']}';
    final order = item['order']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Urutan indicator ─────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Center(
                child: Text(
                  order,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
            ),

            // ── Konten utama ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama + Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] ?? '-',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _StatusChip(isActive: isActive),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Perusahaan
                  Row(
                    children: [
                      Icon(Icons.business_outlined,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          companyName,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Deskripsi
                  if ((item['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item['description'],
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ── Titik 3 ──────────────────────────────────────────────────
            _CardMenu(item: item, c: c),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POPUP MENU
// ─────────────────────────────────────────────────────────────────────────────
class _CardMenu extends StatelessWidget {
  final Map<String, dynamic> item;
  final JobLevelController c;
  const _CardMenu({required this.item, required this.c});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == 'edit') {
          c.prepareEdit(item);
          Get.to(() => const JobLevelFormPage());
        } else if (value == 'delete') {
          c.confirmDelete(item['id'], item['name'] ?? '');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined,
                  size: 18, color: Colors.blue.shade600),
              const SizedBox(width: 10),
              Text('Edit',
                  style: TextStyle(color: Colors.blue.shade700)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: 18, color: Colors.red.shade500),
              const SizedBox(width: 10),
              Text('Hapus',
                  style: TextStyle(color: Colors.red.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color:
                  isActive ? Colors.green.shade500 : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Aktif' : 'Nonaktif',
            style: TextStyle(
              fontSize: 11,
              color:
                  isActive ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGINATION
// ─────────────────────────────────────────────────────────────────────────────
class _Pagination extends StatelessWidget {
  final JobLevelController c;
  const _Pagination({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.lastPage.value <= 1) return const SizedBox.shrink();
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: ${c.total.value} data',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  splashRadius: 20,
                  onPressed: c.currentPage.value > 1
                      ? () => c.fetchAll(page: c.currentPage.value - 1)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${c.currentPage.value} / ${c.lastPage.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  splashRadius: 20,
                  onPressed: c.currentPage.value < c.lastPage.value
                      ? () => c.fetchAll(page: c.currentPage.value + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE FILTER CHIPS
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveFilterChips extends StatelessWidget {
  final JobLevelController c;
  const _ActiveFilterChips({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!c.hasActiveFilter) return const SizedBox.shrink();
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Icon(Icons.filter_alt_outlined,
                size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            if (c.selectedCompanyId.value != null)
              _chip('Perusahaan dipilih', Colors.blue),
            if (c.filterIsActive.value != null)
              _chip(
                c.filterIsActive.value! ? 'Aktif' : 'Nonaktif',
                c.filterIsActive.value! ? Colors.green : Colors.grey,
              ),
            const Spacer(),
            GestureDetector(
              onTap: c.resetFilter,
              child: Text(
                'Reset filter',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
void _showFilterSheet(BuildContext context, JobLevelController c) {
  final tempCompanyId = Rx<int?>(c.selectedCompanyId.value);
  final tempIsActive = Rx<bool?>(c.filterIsActive.value);

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Filter Job Level',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Perusahaan',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<int?>(
              value: tempCompanyId.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                hintText: 'Semua Perusahaan',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua')),
                ...c.companies.map(
                  (company) => DropdownMenuItem(
                    value: company['id'] as int?,
                    child: Text(company['name'] ?? ''),
                  ),
                ),
              ],
              onChanged: (val) => tempCompanyId.value = val,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Status',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<bool?>(
              value: tempIsActive.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua Status')),
                DropdownMenuItem(value: true, child: Text('Aktif')),
                DropdownMenuItem(value: false, child: Text('Nonaktif')),
              ],
              onChanged: (val) => tempIsActive.value = val,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                    c.resetFilter();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    c.applyFilter(
                      companyId: tempCompanyId.value,
                      isActive: tempIsActive.value,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Terapkan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}