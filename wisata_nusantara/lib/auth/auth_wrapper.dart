import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
// import '../wisata/home_screen.dart'; // <-- Aktifkan nanti setelah Orang 2 merge ke main

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Halaman sementara khusus untuk tes Login & Logout Orang 1.
          // Nanti setelah digabung, hapus Scaffold ini dan ganti dengan: return const HomeScreen();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tes Berhasil Login'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                ),
              ],
            ),
            body: Center(
              child: Text('Berhasil masuk sebagai:\n${snapshot.data?.email ?? "User"}'),
            ),
          );
        }

        return const LoginScreen();
      },
    );
  }
}