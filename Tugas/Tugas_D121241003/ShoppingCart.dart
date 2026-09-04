class Produk {
  String namaProduk;
  double hargaSatuan;
  int jumlahBeli;

  Produk({
    required this.namaProduk,
    required this.hargaSatuan,
    required this.jumlahBeli,
  });

  // Subtotal per produk = harga x jumlah (operator perkalian)
  double get subtotalProduk => hargaSatuan * jumlahBeli;
}

// FUNCTION 1: menghitung total belanja (looping semua produk)
double hitungTotalBelanja(List<Produk> daftarProduk) {
  double total = 0;
  for (Produk produk in daftarProduk) {
    total += produk.subtotalProduk;
  }
  return total;
}

// FUNCTION 2: menentukan diskon berdasarkan ketentuan (if/else)
double hitungDiskon(double totalBelanja) {
  if (totalBelanja >= 750000) {
    return totalBelanja * 0.20; // diskon 20% belanja >= 750rb
  } else if (totalBelanja >= 300000) {
    return totalBelanja * 0.10; // diskon 10% belanja >= 300rb
  } else {
    return 0; // tidak dapat diskon
  }
}

// FUNCTION 3: menampilkan daftar produk (dipanggil dalam loop)
void tampilkanProduk(Produk produk) {
  print('${produk.namaProduk}');
  print('  Harga     : Rp${produk.hargaSatuan.toStringAsFixed(0)}');
  print('  Jumlah    : ${produk.jumlahBeli}');
  print('  Subtotal  : Rp${produk.subtotalProduk.toStringAsFixed(0)}');
}

void main() {
  // 1. Menyimpan beberapa produk (nama, harga, jumlah pembelian)
  List<Produk> daftarProduk = [
    Produk(namaProduk: 'Sepatu Sneakers', hargaSatuan: 250000, jumlahBeli: 2),
    Produk(namaProduk: 'Tas Ransel', hargaSatuan: 180000, jumlahBeli: 1),
    Produk(namaProduk: 'Topi', hargaSatuan: 50000, jumlahBeli: 3),
  ];

  print('=== SIMPLE SHOPPING CART ===\n');

  // Loop untuk menampilkan daftar produk
  print('Daftar Produk:');
  for (Produk produk in daftarProduk) {
    tampilkanProduk(produk);
  }

  // 2. Menghitung subtotal & total pembayaran
  double totalBelanja = hitungTotalBelanja(daftarProduk);
  double diskon = hitungDiskon(totalBelanja);
  double totalPembayaran = totalBelanja - diskon;

  // 5. Output: subtotal, diskon, total pembayaran
  print('\n--------------------------');
  print('Total Belanja    : Rp${totalBelanja.toStringAsFixed(0)}');

  // 3. Menentukan status diskon (if/else)
  if (diskon > 0) {
    print('Diskon           : Rp${diskon.toStringAsFixed(0)}');
    print('Status           : Mendapatkan diskon');
  } else {
    print('Diskon           : Rp0');
    print('Status           : Belum memenuhi syarat diskon');
  }

  print('Total Pembayaran : Rp${totalPembayaran.toStringAsFixed(0)}');
}