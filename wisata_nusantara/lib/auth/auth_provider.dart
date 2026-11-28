import 'dart:async';   
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_sanitizer.dart';

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

  // Fungsi Register (Membuat akun baru + menyimpan role di Firestore)
Future<String?> register({
  required String email,
  required String password,
  required String role,
}) async {
  final cleanEmail = InputSanitizer.sanitizeEmail(email);

  if (!InputSanitizer.isValidEmail(cleanEmail)) {
    return 'Format email tidak valid';
  }

  try {
    _isLoading = true;
    notifyListeners();

    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    // Kirim email verifikasi
    await cred.user!.sendEmailVerification();

    // Simpan data pengguna ke Firestore
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': cleanEmail,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Keluar sementara sampai email diverifikasi
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

  // Fungsi Login (Cek email/password + ambil role dari Firestore)
  

Future<String?> login({
  required String email,
  required String password,
}) async {
  final cleanEmail = InputSanitizer.sanitizeEmail(email);

  if (!InputSanitizer.isValidEmail(cleanEmail)) {
    return 'Format email tidak valid';
  }

  try {
    _isLoading = true;
    notifyListeners();

    UserCredential cred = await _auth.signInWithEmailAndPassword(
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
      // Kirim ulang email verifikasi
      await currentUser.sendEmailVerification();

      await _auth.signOut();

      _user = null;
      _role = 'user';

      return 'Email belum diverifikasi. Link verifikasi telah dikirim ulang. Periksa inbox email kamu.';
    }

    // Ambil role pengguna dari Firestore
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(currentUser.uid).get();

    _user = currentUser;

    if (doc.exists && doc.data() != null) {
      _role = (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
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

  // Fungsi Logout
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _role = 'user';
    notifyListeners();
  }
}