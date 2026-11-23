import 'dart:async';   
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _role = 'user'; // Default role untuk Authorization
  bool _isLoading = false;
  StreamSubscription<User?>? _authSub;

  User? get user => _user;
  String get role => _role;
  bool get isLoading => _isLoading;
  bool get isAdmin => _role == 'admin';

  AuthProvider() {
    _authSub = _auth.authStateChanges().listen((user) async {
      _user = user;
      if (user == null) {
        _role = 'user';
      } else {
        try {
          final doc =
              await _firestore.collection('users').doc(user.uid).get();
          _role = (doc.data()?['role'] as String?) ?? 'user';
        } catch (_) {
          _role = 'user';
        }
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // Fungsi Register (Membuat akun baru + menyimpan role di Firestore)
  Future<String?> register({
    required String email,
    required String password,
    required String role, // 'admin' atau 'user'
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan data role ke Firestore untuk keperluan Authorization
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _user = cred.user;
      _role = role;
      return null; // Berhasil (tidak ada pesan error)
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi Login (Cek email/password + ambil role dari Firestore)
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ambil role user dari Firestore (Authorization)
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(cred.user!.uid).get();

      _user = cred.user;
      if (doc.exists && doc.data() != null) {
        _role = (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
      }

      return null; // Berhasil
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _role = 'user';
    notifyListeners();
  }
}