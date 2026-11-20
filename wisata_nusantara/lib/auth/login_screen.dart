import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  String _selectedRole = 'user';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi!')),
      );
      return;
    }

    String? errorMessage;
    if (_isLoginMode) {
      errorMessage = await authProvider.login(email: email, password: password);
    } else {
      errorMessage = await authProvider.register(
        email: email,
        password: password,
        role: _selectedRole,
      );
    }

    if (!mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $errorMessage'), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil masuk sebagai ${authProvider.role.toUpperCase()}!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login Wisata Nusantara' : 'Daftar Akun Baru'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isLoginMode)
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Daftar Sebagai (Authorization Role)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Pengunjung Biasa (User)')),
                  DropdownMenuItem(value: 'admin', child: Text('Pengelola Wisata (Admin)')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val ?? 'user'),
              ),
            const SizedBox(height: 24),
            auth.isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isLoginMode ? 'LOGIN' : 'REGISTER'),
                    ),
                  ),
            TextButton(
              onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
              child: Text(_isLoginMode
                  ? 'Belum punya akun? Daftar di sini'
                  : 'Sudah punya akun? Login di sini'),
            ),
          ],
        ),
      ),
    );
  }
}