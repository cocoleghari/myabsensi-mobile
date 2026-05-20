import 'package:flutter/material.dart';

class RiwayatEmptyWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const RiwayatEmptyWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 150),
        child: Image.asset(
          'assets/images/tidak_ada_absen.png',
          width: 230,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
