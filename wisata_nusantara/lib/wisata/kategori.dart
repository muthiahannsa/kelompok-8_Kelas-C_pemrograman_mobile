import 'package:flutter/material.dart';

/// Daftar kategori destinasi + ikon & warna latar (dipakai juga sebagai
/// tampilan cadangan saat destinasi belum punya gambar).
class KategoriWisata {
  KategoriWisata._();

  static const String lainnya = 'Lainnya';

  static const List<String> semua = [
    'Pantai',
    'Dataran Tinggi',
    'Taman',
    'Budaya & Sejarah',
    'Air Terjun & Danau',
    lainnya,
  ];

  /// Kategori yang tampil sebagai chip di homescreen (tanpa "Lainnya").
  static const List<String> untukFilter = [
    'Pantai',
    'Dataran Tinggi',
    'Taman',
    'Budaya & Sejarah',
    'Air Terjun & Danau',
  ];

  static String normalisasi(String? value) {
    if (value == null || !semua.contains(value)) return lainnya;
    return value;
  }

  static IconData ikon(String kategori) {
    switch (kategori) {
      case 'Pantai':
        return Icons.beach_access_rounded;
      case 'Dataran Tinggi':
        return Icons.landscape_rounded;
      case 'Taman':
        return Icons.park_rounded;
      case 'Budaya & Sejarah':
        return Icons.account_balance_rounded;
      case 'Air Terjun & Danau':
        return Icons.water_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  /// Pasangan warna gradien [atas-kiri, bawah-kanan].
  static List<Color> warna(String kategori) {
    switch (kategori) {
      case 'Pantai':
        return const [Color(0xFF38BDF8), Color(0xFF0369A1)];
      case 'Dataran Tinggi':
        return const [Color(0xFF86EFAC), Color(0xFF15803D)];
      case 'Taman':
        return const [Color(0xFFA3E635), Color(0xFF4D7C0F)];
      case 'Budaya & Sejarah':
        return const [Color(0xFFFBBF24), Color(0xFFB45309)];
      case 'Air Terjun & Danau':
        return const [Color(0xFF67E8F9), Color(0xFF0E7490)];
      default:
        return const [Color(0xFF45C2B8), Color(0xFF0B7A75)];
    }
  }
}