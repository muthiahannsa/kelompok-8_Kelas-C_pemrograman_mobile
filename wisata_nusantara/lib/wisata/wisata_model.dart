
class Wisata {
  final String id;
  final String nama;
  final String provinsi;
  final String deskripsi;
  final String gambarUrl;
  final double lat;
  final double lon;

  Wisata({
    required this.id,
    required this.nama,
    required this.provinsi,
    required this.deskripsi,
    required this.gambarUrl,
    required this.lat,
    required this.lon,
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
      deskripsi: data['deskripsi'] ?? '',
      gambarUrl: data['gambarUrl'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (data['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Mengubah objek Wisata menjadi Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'provinsi': provinsi,
      'deskripsi': deskripsi,
      'gambarUrl': gambarUrl,
      'lat': lat,
      'lon': lon,
    };
  }
}
