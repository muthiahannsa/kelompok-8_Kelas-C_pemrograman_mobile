class Product {
  String name;
  double price;
  int quantity;

  Product(this.name, this.price, this.quantity);

  double get subtotal => price * quantity;
}

double calculateTotal(List<Product> cart) {
  double total = 0;
  for (Product item in cart) {
    total += item.subtotal;
  }
  return total;
}

double calculateDiscount(double total) {
  if (total >= 500000) {
    return total * 0.10;
  } else {
    return 0;
  }
}

void printCartItems(List<Product> cart) {
  print('Daftar Produk:');
  for (Product item in cart) {
    print('${item.name}');
    print('  Harga    : Rp${item.price.toStringAsFixed(0)}');
    print('  Jumlah   : ${item.quantity}');
    print('  Subtotal : Rp${item.subtotal.toStringAsFixed(0)}');
  }
}

void main() {
  List<Product> cart = [
    Product('Mouse Wireless', 120000, 2),
    Product('Keyboard Mekanik', 350000, 1),
    Product('Headset Gaming', 200000, 1),
  ];

  print('SIMPLE SHOPPING CART\n');

  printCartItems(cart);

  double subtotal = calculateTotal(cart);
  double discount = calculateDiscount(subtotal);
  double totalPayment = subtotal - discount;

  print('\nSubtotal        : Rp${subtotal.toStringAsFixed(0)}');

  if (discount > 0) {
    print('Diskon (10%)    : Rp${discount.toStringAsFixed(0)}');
    print('Status          : Mendapatkan diskon');
  } else {
    print('Diskon          : Rp0');
    print('Status          : Belum memenuhi syarat diskon '
        '(minimal belanja Rp500.000)');
  }

  print('Total Pembayaran: Rp${totalPayment.toStringAsFixed(0)}');
}