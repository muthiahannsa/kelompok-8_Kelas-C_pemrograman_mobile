import 'wisata_model.dart';

/// Data contoh destinasi terkenal di Indonesia (tanpa gambar; admin dapat
/// menambahkan gambar lewat menu Edit). Koordinat bersifat perkiraan dan
/// dapat dikoreksi lewat pemilih lokasi di peta.
///
/// Key = ID dokumen Firestore, sehingga menjalankan seed berulang tidak
/// membuat data ganda.
final Map<String, Wisata> wisataContoh = {
  'candi-borobudur': Wisata(
    id: 'candi-borobudur',
    nama: 'Candi Borobudur',
    provinsi: 'Jawa Tengah',
    kategori: 'Budaya & Sejarah',
    deskripsi:
        'Candi Buddha terbesar di dunia dari abad ke-9 di Magelang. Situs Warisan Dunia UNESCO yang terkenal dengan relief dan stupa-stupanya, apalagi saat matahari terbit.',
    lat: -7.6079,
    lon: 110.2038,
    populer: true,
  ),
  'keraton-yogyakarta': Wisata(
    id: 'keraton-yogyakarta',
    nama: 'Keraton Yogyakarta',
    provinsi: 'DI Yogyakarta',
    kategori: 'Budaya & Sejarah',
    deskripsi:
        'Istana resmi Kesultanan Ngayogyakarta Hadiningrat. Tempat menikmati arsitektur Jawa, koleksi pusaka, serta pertunjukan gamelan dan tari tradisional.',
    lat: -7.8053,
    lon: 110.3642,
    populer: true,
  ),
  'candi-prambanan': Wisata(
    id: 'candi-prambanan',
    nama: 'Candi Prambanan',
    provinsi: 'DI Yogyakarta',
    kategori: 'Budaya & Sejarah',
    deskripsi:
        'Kompleks candi Hindu megah dengan menara-menara runcing setinggi puluhan meter. Pemandangan senjanya sangat populer di kalangan wisatawan.',
    lat: -7.7520,
    lon: 110.4915,
  ),
  'pantai-kuta-bali': Wisata(
    id: 'pantai-kuta-bali',
    nama: 'Pantai Kuta',
    provinsi: 'Bali',
    kategori: 'Pantai',
    deskripsi:
        'Pantai berpasir luas yang terkenal untuk berselancar dan menikmati matahari terbenam, dengan banyak kafe dan pusat hiburan di sekitarnya.',
    lat: -8.7180,
    lon: 115.1686,
    populer: true,
  ),
  'pantai-pandawa-bali': Wisata(
    id: 'pantai-pandawa-bali',
    nama: 'Pantai Pandawa',
    provinsi: 'Bali',
    kategori: 'Pantai',
    deskripsi:
        'Pantai berpasir putih yang diapit tebing kapur tinggi di Bali selatan, dengan air laut jernih dan suasana yang lebih tenang.',
    lat: -8.8456,
    lon: 115.1881,
    populer: true,
  ),
  'pantai-sanur-bali': Wisata(
    id: 'pantai-sanur-bali',
    nama: 'Pantai Sanur',
    provinsi: 'Bali',
    kategori: 'Pantai',
    deskripsi:
        'Pantai berombak tenang yang cocok untuk keluarga, terkenal dengan pemandangan matahari terbit dan jalur pejalan kaki di tepi pantai.',
    lat: -8.6783,
    lon: 115.2625,
  ),
  'pantai-indah-bosowa': Wisata(
    id: 'pantai-indah-bosowa',
    nama: 'Pantai Indah Bosowa',
    provinsi: 'Sulawesi Selatan',
    kategori: 'Pantai',
    deskripsi:
        'Pantai di kawasan Metro Tanjung Bunga, Makassar, yang dikenal dengan pemandangan sunset dan fasilitas rekreasi yang lengkap.',
    lat: -5.1905,
    lon: 119.3925,
    populer: true,
  ),
  'pantai-losari': Wisata(
    id: 'pantai-losari',
    nama: 'Pantai Losari',
    provinsi: 'Sulawesi Selatan',
    kategori: 'Pantai',
    deskripsi:
        'Ikon Kota Makassar dengan anjungan tepi laut yang ramai pada sore hari, terkenal akan sunset dan kuliner khasnya.',
    lat: -5.1477,
    lon: 119.4065,
  ),
  'gunung-bromo': Wisata(
    id: 'gunung-bromo',
    nama: 'Gunung Bromo',
    provinsi: 'Jawa Timur',
    kategori: 'Dataran Tinggi',
    deskripsi:
        'Gunung berapi aktif di kawasan Taman Nasional Bromo Tengger Semeru dengan lautan pasir luas dan pemandangan sunrise dari Penanjakan.',
    lat: -7.9425,
    lon: 112.9530,
    populer: true,
  ),
  'dataran-tinggi-dieng': Wisata(
    id: 'dataran-tinggi-dieng',
    nama: 'Dataran Tinggi Dieng',
    provinsi: 'Jawa Tengah',
    kategori: 'Dataran Tinggi',
    deskripsi:
        'Dataran tinggi berhawa sejuk dengan kawah, telaga warna, dan candi-candi tua yang berselimut kabut.',
    lat: -7.2000,
    lon: 109.9167,
  ),
  'danau-toba': Wisata(
    id: 'danau-toba',
    nama: 'Danau Toba',
    provinsi: 'Sumatera Utara',
    kategori: 'Air Terjun & Danau',
    deskripsi:
        'Danau vulkanik terbesar di Asia Tenggara dengan Pulau Samosir di tengahnya serta budaya Batak yang kental.',
    lat: 2.6845,
    lon: 98.8756,
    populer: true,
  ),
  'air-terjun-tumpak-sewu': Wisata(
    id: 'air-terjun-tumpak-sewu',
    nama: 'Air Terjun Tumpak Sewu',
    provinsi: 'Jawa Timur',
    kategori: 'Air Terjun & Danau',
    deskripsi:
        'Air terjun tirai lebar yang jatuh dari tebing melengkung, sering dijuluki Niagara-nya Indonesia.',
    lat: -8.2285,
    lon: 112.9189,
  ),
  'kebun-raya-bogor': Wisata(
    id: 'kebun-raya-bogor',
    nama: 'Kebun Raya Bogor',
    provinsi: 'Jawa Barat',
    kategori: 'Taman',
    deskripsi:
        'Kebun botani tertua di Indonesia dengan ribuan koleksi tumbuhan, taman luas, dan suasana asri di tengah kota.',
    lat: -6.5976,
    lon: 106.7997,
  ),
  'taman-mini-indonesia-indah': Wisata(
    id: 'taman-mini-indonesia-indah',
    nama: 'Taman Mini Indonesia Indah',
    provinsi: 'DKI Jakarta',
    kategori: 'Taman',
    deskripsi:
        'Taman wisata budaya dengan anjungan rumah adat dari seluruh provinsi, museum, dan berbagai wahana keluarga.',
    lat: -6.3025,
    lon: 106.8951,
  ),
  'taman-nasional-komodo': Wisata(
    id: 'taman-nasional-komodo',
    nama: 'Taman Nasional Komodo',
    provinsi: 'Nusa Tenggara Timur',
    kategori: 'Taman',
    deskripsi:
        'Habitat asli komodo yang berpadu dengan pantai pink dan spot snorkeling kelas dunia.',
    lat: -8.5500,
    lon: 119.4833,
    populer: true,
  ),
};