import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class InfoCardWidget extends StatelessWidget {
  const InfoCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: isWeb ? 18 : 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sistem otomatis mendeteksi lokasi terdekat. GPS aktif dan radius 100m. Foto wajah sebagai bukti.',
              style: TextStyle(
                fontSize: isWeb ? 12 : 11,
                color: Colors.blue[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
