
import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String uid;
  final int rating;
  final String ulasan;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rating({
    required this.uid,
    required this.rating,
    required this.ulasan,
    required this.createdAt,
    required this.updatedAt,
  });

  // Mengubah data Firestore menjadi objek Rating
  factory Rating.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return Rating(
      uid: uid,
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      ulasan: data['ulasan'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  // Mengubah objek Rating menjadi data untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'rating': rating,
      'ulasan': ulasan,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
