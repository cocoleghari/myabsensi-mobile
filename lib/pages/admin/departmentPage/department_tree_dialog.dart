import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../controllers/auth_controller.dart';
import '../../../controllers/app_config.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DepartmentTreeDialog
///
/// Menampilkan bagan hierarki department dalam bentuk pohon interaktif.
/// Bisa dibuka dari DepartmentPage via popup menu "Lihat Hierarki".
///
/// Cara pakai:
///   showDialog(
///     context: context,
///     builder: (_) => const DepartmentTreeDialog(),
///   );
/// ─────────────────────────────────────────────────────────────────────────────
class DepartmentTreeDialog extends StatefulWidget {
  const DepartmentTreeDialog({super.key});

  @override
  State<DepartmentTreeDialog> createState() => _DepartmentTreeDialogState();
}

class _DepartmentTreeDialogState extends State<DepartmentTreeDialog> {
  final _authController = Get.find<AuthController>();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _tree = [];

  // Simpan state expanded per node (key = id department)
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _fetchTree();
  }

  // ─── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> _fetchTree() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/departments-tree'),
            headers: {
              'Authorization': 'Bearer ${_authController.token.value}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = List<Map<String, dynamic>>.from(data['data'] ?? []);

        // Auto-expand level pertama
        for (final dept in list) {
          _expanded.add(dept['id'] as int);
        }

        setState(() => _tree = list);
      } else {
        setState(() => _error = 'Gagal memuat hierarki department');
      }
    } catch (e) {
      setState(() => _error = 'Koneksi error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Toggle expand ──────────────────────────────────────────────────────────

  void _toggleExpand(int id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  // ─── Expand / Collapse semua ────────────────────────────────────────────────

  void _expandAll(List<Map<String, dynamic>> nodes) {
    for (final node in nodes) {
      _expanded.add(node['id'] as int);
      final children = _getChildren(node);
      if (children.isNotEmpty) _expandAll(children);
    }
    setState(() {});
  }

  void _collapseAll(List<Map<String, dynamic>> nodes) {
    for (final node in nodes) {
      _expanded.remove(node['id'] as int);
      final children = _getChildren(node);
      if (children.isNotEmpty) _collapseAll(children);
    }
    setState(() {});
  }

  List<Map<String, dynamic>> _getChildren(Map<String, dynamic> node) {
    final raw = node['all_children'] ?? node['children'] ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  // ─── Hitung total node ──────────────────────────────────────────────────────

  int _countAll(List<Map<String, dynamic>> nodes) {
    int count = nodes.length;
    for (final n in nodes) {
      count += _countAll(_getChildren(n));
    }
    return count;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_tree_outlined,
              color: Colors.deepPurple.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hierarki Department',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_tree.isNotEmpty)
                  Text(
                    '${_countAll(_tree)} department',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          // Tombol expand/collapse semua
          if (_tree.isNotEmpty) ...[
            IconButton(
              onPressed: () => _expandAll(_tree),
              icon: const Icon(Icons.unfold_more, size: 20),
              tooltip: 'Expand semua',
              color: Colors.grey.shade600,
            ),
            IconButton(
              onPressed: () => _collapseAll(_tree),
              icon: const Icon(Icons.unfold_less, size: 20),
              tooltip: 'Collapse semua',
              color: Colors.grey.shade600,
            ),
          ],
          IconButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchTree,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_tree.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada department',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _tree
              .map(
                (node) =>
                    _buildNode(node, depth: 0, isLast: node == _tree.last),
              )
              .toList(),
        ),
      ),
    );
  }

  // ─── Node rekursif ──────────────────────────────────────────────────────────

  Widget _buildNode(
    Map<String, dynamic> node, {
    required int depth,
    required bool isLast,
    List<bool> ancestorLines = const [],
  }) {
    final id = node['id'] as int;
    final name = node['name']?.toString() ?? '-';
    final code = node['code']?.toString();
    final isActive = node['is_active'] == true;
    final empCount = node['employees_count'] ?? 0;
    final managerName = node['manager']?['full_name']?.toString();
    final children = _getChildren(node);
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expanded.contains(id);

    // Warna aksen berdasarkan kedalaman
    final depthColors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
    ];
    final color = depthColors[depth % depthColors.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Baris node ────────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Garis vertikal + horizontal (tree lines)
            if (depth > 0)
              SizedBox(
                width: depth * 24.0,
                child: CustomPaint(
                  painter: _TreeLinePainter(
                    depth: depth,
                    isLast: isLast,
                    ancestorLines: ancestorLines,
                    color: Colors.grey.shade300,
                  ),
                  size: Size(depth * 24.0, 52),
                ),
              ),

            // Konten node
            Expanded(
              child: GestureDetector(
                onTap: hasChildren ? () => _toggleExpand(id) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: depth == 0
                          ? color.withOpacity(0.4)
                          : Colors.grey.shade200,
                      width: depth == 0 ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: depth == 0
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Icon dept
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            depth == 0
                                ? Icons.account_tree
                                : depth == 1
                                ? Icons.business_center_outlined
                                : Icons.storefront_outlined,
                            size: 16,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: depth == 0
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: depth == 0 ? 14 : 13,
                                      ),
                                    ),
                                  ),
                                  if (code != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        code,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isActive ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isActive
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$empCount karyawan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  if (managerName != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.person_outline,
                                      size: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        managerName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Toggle expand icon
                        if (hasChildren) ...[
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Children (rekursif) ───────────────────────────────────────────────
        if (hasChildren && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.asMap().entries.map((entry) {
                final isLastChild = entry.key == children.length - 1;
                return _buildNode(
                  entry.value,
                  depth: depth + 1,
                  isLast: isLastChild,
                  ancestorLines: [...ancestorLines, !isLast],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter untuk garis tree
// ─────────────────────────────────────────────────────────────────────────────

class _TreeLinePainter extends CustomPainter {
  final int depth;
  final bool isLast;
  final List<bool> ancestorLines;
  final Color color;

  const _TreeLinePainter({
    required this.depth,
    required this.isLast,
    required this.ancestorLines,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Garis vertikal dari ancestor
    for (int i = 0; i < ancestorLines.length; i++) {
      if (ancestorLines[i]) {
        final x = i * 24.0 + 12;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }

    // Garis L untuk node ini
    final x = (depth - 1) * 24.0 + 12;
    final midY = size.height / 2;

    // Garis vertikal (atas ke tengah, atau full jika bukan last)
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, isLast ? midY : size.height),
      paint,
    );

    // Garis horizontal ke node
    canvas.drawLine(Offset(x, midY), Offset(x + 16, midY), paint);
  }

  @override
  bool shouldRepaint(_TreeLinePainter old) =>
      old.isLast != isLast || old.depth != depth;
}
