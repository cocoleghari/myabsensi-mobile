import 'package:flutter/material.dart';
import 'package:myabsensi_mobile/pages/admin/riwayatSemuaUserPage/modals/admin_delete_confirmation.dart';
import 'admin_formatter.dart';

class AdminAbsensiCardWidget extends StatelessWidget {
  final int userIndex;
  final String userName;
  final String tanggal;
  final String lokasi;
  final Map<String, dynamic>? dataMasuk;
  final Map<String, dynamic>? dataPulang;
  final VoidCallback onTap;

  const AdminAbsensiCardWidget({
    super.key,
    required this.userIndex,
    required this.userName,
    required this.tanggal,
    required this.lokasi,
    required this.dataMasuk,
    required this.dataPulang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int? idMasuk = dataMasuk?['id'];
    int? idPulang = dataPulang?['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue, Colors.blue.shade700],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${userIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AdminFormatter.formatTanggal(tanggal),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lokasi,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dataMasuk != null
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 12,
                            color: dataMasuk != null
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: dataMasuk != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (dataMasuk != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            AdminFormatter.formatJam(
                              dataMasuk!['waktu_absen']?.toString() ?? '',
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dataPulang != null
                                ? Colors.orange
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pulang',
                          style: TextStyle(
                            fontSize: 12,
                            color: dataPulang != null
                                ? Colors.orange
                                : Colors.grey,
                            fontWeight: dataPulang != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (dataPulang != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            AdminFormatter.formatJam(
                              dataPulang!['waktu_absen']?.toString() ?? '',
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'hapus_masuk' && idMasuk != null) {
                    AdminDeleteConfirmation.show(
                      context: context,
                      id: idMasuk,
                      tipe: 'masuk',
                    );
                  } else if (value == 'hapus_pulang' && idPulang != null) {
                    AdminDeleteConfirmation.show(
                      context: context,
                      id: idPulang,
                      tipe: 'pulang',
                    );
                  } else if (value == 'hapus_semua' &&
                      idMasuk != null &&
                      idPulang != null) {
                    AdminDeleteConfirmation.show(
                      context: context,
                      id: idMasuk,
                      tipe: 'semua',
                      idPulang: idPulang,
                    );
                  }
                },
                itemBuilder: (context) => [
                  if (dataMasuk != null)
                    const PopupMenuItem(
                      value: 'hapus_masuk',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Hapus Absen Masuk'),
                        ],
                      ),
                    ),
                  if (dataPulang != null)
                    const PopupMenuItem(
                      value: 'hapus_pulang',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Hapus Absen Pulang'),
                        ],
                      ),
                    ),
                  if (dataMasuk != null && dataPulang != null)
                    const PopupMenuItem(
                      value: 'hapus_semua',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Hapus Semua'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
