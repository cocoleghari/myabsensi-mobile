import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/pusat_lokasi_controller.dart';

class PusatLokasiSearchBar extends StatefulWidget {
  const PusatLokasiSearchBar({super.key});

  @override
  State<PusatLokasiSearchBar> createState() => _PusatLokasiSearchBarState();
}

class _PusatLokasiSearchBarState extends State<PusatLokasiSearchBar> {
  late final PusatLokasiController controller;
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PusatLokasiController>();
    _textCtrl = TextEditingController(text: controller.searchQuery.value);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Obx(() {
        // Obx HANYA untuk styling — tidak menyentuh TextField sama sekali
        final hasQuery = controller.searchQuery.value.isNotEmpty;

        // Sync jika searchQuery di-reset dari luar (misal tombol "Reset Pencarian")
        if (_textCtrl.text != controller.searchQuery.value) {
          _textCtrl.value = TextEditingValue(
            text: controller.searchQuery.value,
            selection: TextSelection.collapsed(
              offset: controller.searchQuery.value.length,
            ),
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasQuery ? Colors.blue.shade300 : Colors.grey.shade200,
              width: hasQuery ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: hasQuery
                    ? Colors.blue.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // ✅ TextField TIDAK rebuild — controller tetap sama
          child: TextField(
            controller: _textCtrl,
            onChanged: (v) => controller.search(v),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Cari nama lokasi atau keterangan...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                hasQuery ? Icons.search : Icons.search_outlined,
                color: hasQuery ? Colors.blue : Colors.grey.shade400,
                size: 20,
              ),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      onPressed: () {
                        controller.search('');
                        // _textCtrl akan sync otomatis via Obx di atas
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 4,
              ),
            ),
          ),
        );
      }),
    );
  }
}
