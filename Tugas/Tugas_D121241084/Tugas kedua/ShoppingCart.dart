import 'dart:async';
import 'dart:ffi';
import 'dart:io';

void main(){
  List<Map<String, dynamic>> keranjang = [
    {'nama':'buku tuliss', 'harga':5000,'jumlah':3 },
    {'nama':'pensil', 'harga':2000,'jumlah':5 },
    {'nama':'penghapus', 'harga':1500,'jumlah':2},
  ];

  int totalbelanja = 0;

  print('--== ANU DAFTAR PRODUK ==--');
   for (var produk in keranjang) {
    int subtotal = hitungsubtotal(produk['harga'],produk['jumlah']);
    totalbelanja += subtotal;

    print('${produk['nama']}- Rp${produk['harga']} x ${produk['jumlah']}= Rp$subtotal');
}

double persendiskon = hitungdiskon(totalbelanja);
int nominaldiskon = (totalbelanja * persendiskon).toInt();
int totalpembayaran = totalbelanja - nominaldiskon;

print('- - - - - - - - - - - - - - - - -');
print('subtotal       : Rp$totalbelanja');
print('diskon (${(persendiskon * 100).toInt()}%)   :Rp$nominaldiskon');
print('total pembayaran   : Rp$totalpembayaran');

}

int hitungsubtotal(int harga, int jumlah){
  return harga * jumlah;
}

double hitungdiskon(int total){
  if (total >= 50000){
    return 0.10;
  } else {
    return 0.0;
  }
}