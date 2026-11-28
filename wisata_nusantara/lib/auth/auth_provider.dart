
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_sanitizer.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _role = 'user';
  bool _isLoading = false;
  StreamSubscription<User?>? _authSub;

  User? get user => _user;
  String get role => _role;
  bool get isLoading => _isLoading;
  bool get isAdmin => _role == 'admin';

  AuthProvider() {
    _authSub = _auth.userChanges().listen((user) async {
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

  // REGISTER
  Future<String?> register({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cleanEmail = InputSanitizer.sanitizeEmail(email);

      final UserCredential cred =
          await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': cleanEmail,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _user = cred.user;
      _role = 'user';

      // Kirim email verifikasi
      await cred.user!.sendEmailVerification();

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGIN
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cleanEmail = InputSanitizer.sanitizeEmail(email);

      // Autentikasi menggunakan Firebase
      final UserCredential cred =
          await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      // Perbarui status verifikasi dari Firebase
      await cred.user!.reload();

      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        return 'Gagal memeriksa status akun';
      }

      // Periksa apakah email sudah diverifikasi
      if (!currentUser.emailVerified) {
        await currentUser.sendEmailVerification();

        await _auth.signOut();

        _user = null;
        _role = 'user';

        return 'Email belum diverifikasi. Link verifikasi telah dikirim ulang. Periksa inbox email kamu.';
      }

      // Ambil role pengguna dari Firestore
      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      _user = currentUser;

      if (doc.exists && doc.data() != null) {
        _role = (doc.data()?['role'] as String?) ?? 'user';
      } else {
        _role = 'user';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();

    _user = null;
    _role = 'user';

    notifyListeners();
  }
}
