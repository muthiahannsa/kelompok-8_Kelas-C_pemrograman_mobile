class Mahasiswa {
  String nama;
  List<int> nilaiUjian;
  int persenKehadiran;

  Mahasiswa({
    required this.nama,
    required this.nilaiUjian,
    required this.persenKehadiran,
  });

  // Method di dalam class untuk hitung rata-rata
  double get rataRata {
    double jumlah = 0;
    for (int nilai in nilaiUjian) {
      jumlah += nilai;
    }
    return jumlah / nilaiUjian.length;
  }
}

// Function terpisah untuk menentukan grade (operator perbandingan berjenjang)
String cariGrade(double rataRata) {
  if (rataRata >= 90) {
    return 'A';
  } else if (rataRata >= 78) {
    return 'B';
  } else if (rataRata >= 65) {
    return 'C';
  } else if (rataRata >= 50) {
    return 'D';
  }
  return 'E';
}

// Function untuk menentukan kelulusan
// Syarat: grade bukan E, DAN kehadiran minimal 75%
bool cekKelulusan(String grade, int kehadiran) {
  bool nilaiCukup = grade != 'E';
  bool kehadiranCukup = kehadiran >= 75;
  return nilaiCukup && kehadiranCukup;
}

// Function untuk cetak laporan satu mahasiswa
void cetakLaporan(Mahasiswa mhs) {
  double rata = mhs.rataRata;
  String grade = cariGrade(rata);
  bool lulus = cekKelulusan(grade, mhs.persenKehadiran);

  print('----------------------------');
  print('Nama       : ${mhs.nama}');
  print('Nilai      : ${mhs.nilaiUjian}');
  print('Rata-rata  : ${rata.toStringAsFixed(1)}');
  print('Kehadiran  : ${mhs.persenKehadiran}%');
  print('Grade      : $grade');
  print('Status     : ${lulus ? "LULUS" : "TIDAK LULUS"}');
}

void main() {
  List<Mahasiswa> daftarMahasiswa = [
    Mahasiswa(nama: 'Tara', nilaiUjian: [88, 92, 85], persenKehadiran: 90),
    Mahasiswa(nama: 'Sari', nilaiUjian: [70, 68, 75], persenKehadiran: 80),
    Mahasiswa(nama: 'Dani', nilaiUjian: [60, 55, 58], persenKehadiran: 70),
    Mahasiswa(nama: 'Wulan', nilaiUjian: [45, 50, 40], persenKehadiran: 65),
    Mahasiswa(nama: 'Yusuf', nilaiUjian: [95, 90, 93], persenKehadiran: 85),
  ];

  print('=== LAPORAN NILAI MAHASISWA ===');
  for (var mhs in daftarMahasiswa) {
    cetakLaporan(mhs);
  }

  // Hitung ringkasan total lulus/tidak lulus
  int totalLulus = 0;
  for (var mhs in daftarMahasiswa) {
    String grade = cariGrade(mhs.rataRata);
    if (cekKelulusan(grade, mhs.persenKehadiran)) {
      totalLulus++;
    }
  }

  print('\n=== RINGKASAN ===');
  print('Jumlah mahasiswa      : ${daftarMahasiswa.length}');
  print('Jumlah lulus          : $totalLulus');
  print('Jumlah tidak lulus    : ${daftarMahasiswa.length - totalLulus}');
}