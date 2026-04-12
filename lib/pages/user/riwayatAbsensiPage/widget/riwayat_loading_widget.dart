import 'package:flutter/material.dart';

class RiwayatLoadingWidget extends StatelessWidget {
  const RiwayatLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Memuat riwayat...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8A94A6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
