
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Timer? _timer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // Periksa status verifikasi setiap 3 detik.
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkVerification(),
    );

    _checkVerification();
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        _timer?.cancel();

        // userChanges() pada AuthWrapper akan mengarahkan
        // pengguna ke Home secara otomatis.
      }
    } catch (e) {
      debugPrint('Gagal memeriksa verifikasi: $e');
    }
  }

  Future<void> _resendEmail() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await user.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verifikasi berhasil dikirim ulang.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim email: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: Colors.teal,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verifikasi Email Kamu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kami telah mengirimkan link verifikasi ke:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Silakan buka email dan klik link verifikasi. '
                  'Setelah berhasil, aplikasi akan otomatis '
                  'mengarahkan kamu ke halaman Home.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _isSending ? null : _resendEmail,
                  child: Text(
                    _isSending
                        ? 'Mengirim...'
                        : 'Kirim Ulang Email Verifikasi',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Halaman ini akan memeriksa status verifikasi secara otomatis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
