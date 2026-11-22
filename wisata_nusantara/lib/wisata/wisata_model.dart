import 'kategori.dart';

class Wisata {
  final String id;
  final String nama;
  final String provinsi;
  final String kategori;
  final String deskripsi;
  final String gambarUrl; // opsional: boleh kosong
  final double lat;
  final double lon;
  final bool populer; // tampil di carousel "Rekomendasi"

  Wisata({
    required this.id,
    required this.nama,
    required this.provinsi,
    this.kategori = KategoriWisata.lainnya,
    required this.deskripsi,
    this.gambarUrl = '',
    required this.lat,
    required this.lon,
    this.populer = false,
  });

  // Mengubah data Firestore menjadi objek Wisata
  factory Wisata.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return Wisata(
      id: id,
      nama: data['nama'] ?? '',
      provinsi: data['provinsi'] ?? '',
      kategori: KategoriWisata.normalisasi(data['kategori'] as String?),
      deskripsi: data['deskripsi'] ?? '',
      gambarUrl: data['gambarUrl'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (data['lon'] as num?)?.toDouble() ?? 0.0,
      populer: data['populer'] as bool? ?? false,
    );
  }

  // Mengubah objek Wisata menjadi Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'provinsi': provinsi,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'gambarUrl': gambarUrl,
      'lat': lat,
      'lon': lon,
      'populer': populer,
    };
  }
}