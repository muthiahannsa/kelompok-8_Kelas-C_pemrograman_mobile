
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'rating_model.dart';

class RatingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Rating> _daftarRating = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Rating> get daftarRating => _daftarRating;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Menghitung rata-rata rating
  double get rataRataRating {
    if (_daftarRating.isEmpty) return 0;

    final total = _daftarRating.fold<int>(
      0,
      (total, item) => total + item.rating,
    );

    return total / _daftarRating.length;
  }

  // Menghitung jumlah rating
  int get jumlahRating => _daftarRating.length;

  // Mengambil rating milik pengguna yang sedang login
  Rating? get ratingSaya {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return null;

    try {
      return _daftarRating.firstWhere(
        (rating) => rating.uid == uid,
      );
    } catch (_) {
      return null;
    }
  }

  // Mengambil seluruh rating suatu destinasi wisata
  Future<void> loadRatings(String wisataId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('wisata')
          .doc(wisataId)
          .collection('ratings')
          .get();

      _daftarRating = snapshot.docs.map((doc) {
        return Rating.fromFirestore(
          doc.id,
          doc.data(),
        );
      }).toList();

      _daftarRating.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );
    } catch (e) {
      _errorMessage = 'Gagal mengambil rating: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menambahkan atau memperbarui rating pengguna
  Future<void> submitRating({
    required String wisataId,
    required int rating,
    required String ulasan,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating harus antara 1 sampai 5.');
    }

    if (ulasan.trim().isEmpty) {
      throw Exception('Ulasan tidak boleh kosong.');
    }

    final ratingRef = _firestore
        .collection('wisata')
        .doc(wisataId)
        .collection('ratings')
        .doc(user.uid);

    try {
      final existingRating = await ratingRef.get();
      final now = DateTime.now();

      final data = Rating(
        uid: user.uid,
        rating: rating,
        ulasan: ulasan.trim(),
        createdAt: existingRating.exists
            ? (existingRating.data()?['createdAt'] as Timestamp?)
                    ?.toDate() ??
                now
            : now,
        updatedAt: now,
      );

      await ratingRef.set(data.toMap());

      await loadRatings(wisataId);
    } catch (e) {
      throw Exception('Gagal menyimpan rating: $e');
    }
  }

  // Menghapus rating pengguna sendiri
  Future<void> deleteRating(String wisataId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    try {
      await _firestore
          .collection('wisata')
          .doc(wisataId)
          .collection('ratings')
          .doc(user.uid)
          .delete();

      await loadRatings(wisataId);
    } catch (e) {
      throw Exception('Gagal menghapus rating: $e');
    }
  }
}
