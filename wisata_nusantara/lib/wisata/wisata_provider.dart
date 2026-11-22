import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'wisata_model.dart';
import 'wisata_seed.dart';

class WisataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Menyimpan daftar wisata dari Firestore
  List<Wisata> _daftarWisata = [];

  // Menyimpan ID wisata yang difavoritkan
  Set<String> _favoriteIds = {};

  // Pencarian dan filter
  String _searchQuery = '';
  String? _selectedProvinsi;
  String? _selectedKategori;

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _wisataSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _favoriteSubscription;

  StreamSubscription<User?>? _authSubscription;

  WisataProvider() {
    _listenWisata();

    // Mengikuti perubahan status login pengguna
    _authSubscription = _auth.authStateChanges().listen((user) {
      _listenFavorites(user?.uid);
    });
  }

  // GETTER
  List<Wisata> get daftarWisata => _daftarWisata;

  Set<String> get favoriteIds => _favoriteIds;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  String? get selectedProvinsi => _selectedProvinsi;

  String? get selectedKategori => _selectedKategori;

  // Daftar wisata yang sudah difilter
  List<Wisata> get filteredWisata {
    return _daftarWisata.where((wisata) {
      final cocokNama =
          wisata.nama.toLowerCase().contains(_searchQuery.toLowerCase());

      final cocokProvinsi = _selectedProvinsi == null ||
          _selectedProvinsi!.isEmpty ||
          wisata.provinsi == _selectedProvinsi;

      final cocokKategori = _selectedKategori == null ||
          _selectedKategori!.isEmpty ||
          wisata.kategori == _selectedKategori;

      return cocokNama && cocokProvinsi && cocokKategori;
    }).toList();
  }

  // Daftar provinsi yang tersedia
  List<String> get daftarProvinsi {
    final provinsi = _daftarWisata
        .map((wisata) => wisata.provinsi)
        .where((nama) => nama.isNotEmpty)
        .toSet()
        .toList();

    provinsi.sort();
    return provinsi;
  }

  // 1. Mengambil data wisata secara realtime
  void _listenWisata() {
    _isLoading = true;

    _wisataSubscription = _firestore.collection('wisata').snapshots().listen(
      (snapshot) {
        _daftarWisata = snapshot.docs.map((doc) {
          return Wisata.fromFirestore(doc.id, doc.data());
        }).toList();

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Gagal mengambil data wisata: $error';
        notifyListeners();
      },
    );
  }

  // 2. Mencari wisata berdasarkan nama
  void searchWisata(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // 3. Memfilter wisata berdasarkan provinsi
  void filterByProvinsi(String? provinsi) {
    _selectedProvinsi = provinsi;
    notifyListeners();
  }

  // 3b. Memfilter wisata berdasarkan kategori
  void filterByKategori(String? kategori) {
    _selectedKategori = kategori;
    notifyListeners();
  }

  // Menghapus pencarian dan semua filter
  void resetFilter() {
    _searchQuery = '';
    _selectedProvinsi = null;
    _selectedKategori = null;
    notifyListeners();
  }

  // Memastikan pengguna yang melakukan perubahan adalah Admin
  Future<void> _requireAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    final role = userDoc.data()?['role'];

    if (role != 'admin') {
      throw Exception('Akses ditolak. Hanya Admin yang diizinkan.');
    }
  }

  // 4. Menambahkan data wisata (Admin)
  Future<void> addWisata(Wisata wisata) async {
    await _requireAdmin();
    await _firestore.collection('wisata').add(wisata.toMap());
  }

  // 4b. Memperbarui data wisata (Admin) — dipakai menu Edit
  Future<void> updateWisata(Wisata wisata) async {
    await _requireAdmin();
    await _firestore.collection('wisata').doc(wisata.id).update(
          wisata.toMap(),
        );
  }

  // 5. Menghapus data wisata (Admin)
  Future<void> deleteWisata(String wisataId) async {
    await _requireAdmin();
    await _firestore.collection('wisata').doc(wisataId).delete();
  }

  // 5b. Mengisi data contoh destinasi terkenal (Admin).
  // Hanya menambahkan yang belum ada; mengembalikan jumlah yang ditambahkan.
  Future<int> isiDataContoh() async {
    await _requireAdmin();

    final koleksi = _firestore.collection('wisata');
    final existing = await koleksi.get();
    final existingIds = existing.docs.map((doc) => doc.id).toSet();

    final batch = _firestore.batch();
    var jumlah = 0;

    wisataContoh.forEach((id, wisata) {
      if (!existingIds.contains(id)) {
        batch.set(koleksi.doc(id), wisata.toMap());
        jumlah++;
      }
    });

    if (jumlah > 0) {
      await batch.commit();
    }
    return jumlah;
  }

  // 6. Mengikuti perubahan data favorit secara realtime
  void _listenFavorites(String? uid) {
    _favoriteSubscription?.cancel();
    _favoriteIds = {};

    if (uid == null) {
      notifyListeners();
      return;
    }

    _favoriteSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .listen(
      (snapshot) {
        _favoriteIds = snapshot.docs.map((doc) => doc.id).toSet();
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Gagal mengambil data favorit: $error';
        notifyListeners();
      },
    );
  }

  // 7. Memeriksa apakah wisata sudah difavoritkan
  bool isFavorite(String wisataId) {
    return _favoriteIds.contains(wisataId);
  }

  // 8. Menambah atau menghapus favorit
  Future<void> toggleFavorite(String wisataId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Silakan login untuk menggunakan favorit.');
    }

    final favoriteRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(wisataId);

    try {
      if (isFavorite(wisataId)) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({
          'wisataId': wisataId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      throw Exception('Gagal memperbarui favorit: $error');
    }
  }

  @override
  void dispose() {
    _wisataSubscription?.cancel();
    _favoriteSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}