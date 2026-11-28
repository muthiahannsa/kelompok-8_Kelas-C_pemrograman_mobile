import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../utils/input_sanitizer.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _fieldFill = Color(0xFFF7FAF9);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // FR-05: kolom kosong -> Snackbar
    if (email.isEmpty || password.isEmpty) {
      _showSnack('Email dan password wajib diisi!', isError: true);
      return;
    }

    // Validasi format (inline di bawah kolom)
    if (!_formKey.currentState!.validate()) return;

    String? errorMessage;
    if (_isLoginMode) {
      errorMessage = await authProvider.login(
        email: email,
        password: password,
      );
    } else {
      errorMessage = await authProvider.register(
        email: email,
        password: password,
      );
    }

    if (!mounted) return;

    if (errorMessage != null) {
      _showSnack('Gagal: $errorMessage', isError: true);
    } else {
      _showSnack('Berhasil masuk sebagai ${authProvider.role.toUpperCase()}!');
    }
  }

  if (!mounted) return;

  if (errorMessage != null) {
  _showSnack('Gagal: $errorMessage', isError: true);
} else if (_isLoginMode) {
  _showSnack(
    'Berhasil masuk sebagai ${authProvider.role.toUpperCase()}!'
  );
} else {
  _showSnack(
    'Registrasi berhasil! Silakan periksa email untuk verifikasi.'
  );
}
}

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.sand,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.46,
            child: const _HeroBackground(),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _FadeSlideIn(
                    child: Column(
                      children: [
                        _buildBrand(),
                        const SizedBox(height: 28),
                        _buildFormCard(isLoading),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.explore_rounded,
            size: 42,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Wisata Nusantara',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isLoginMode
                ? 'Selamat datang kembali, traveler!'
                : 'Yuk, mulai petualanganmu!',
            key: ValueKey(_isLoginMode),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeToggle(
              isLogin: _isLoginMode,
              onChanged: (value) => setState(() => _isLoginMode = value),
            ),
            const SizedBox(height: 22),
            Text(
              _isLoginMode ? 'Masuk ke akunmu' : 'Buat akun baru',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isLoginMode
                  ? 'Temukan destinasi & cek cuacanya sebelum berangkat.'
                  : 'Simpan destinasi favoritmu di mana saja.',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'Email',
                fillColor: _fieldFill,
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = InputSanitizer.sanitizeEmail(value ?? '');

                if (email.isEmpty) {
                  return 'Email tidak boleh kosong';
                  }

                if (!InputSanitizer.isValidEmail(email)) {
                  return 'Format email tidak valid';
                  }

                return null;
                  },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Password',
                fillColor: _fieldFill,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Tampilkan password'
                      : 'Sembunyikan password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (!_isLoginMode && v.length < 6) {
                  return 'Password minimal 6 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isLoginMode ? 'Masuk' : 'Buat Akun'),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode
                      ? 'Belum punya akun? Daftar di sini'
                      : 'Sudah punya akun? Masuk di sini',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget pendukung (private)
// ---------------------------------------------------------------------------

class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.08);
    final icon = Colors.white.withValues(alpha: 0.14);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -60, right: -40, child: _Circle(size: 200, color: soft)),
          Positioned(top: 130, left: -60, child: _Circle(size: 150, color: soft)),
          Positioned(
            top: 64,
            left: 28,
            child: Icon(Icons.wb_sunny_rounded, size: 34, color: icon),
          ),
          Positioned(
            top: 90,
            right: 34,
            child: Icon(Icons.cloud_rounded, size: 40, color: icon),
          ),
          Positioned(
            bottom: 56,
            left: 36,
            child: Icon(Icons.sailing_rounded, size: 40, color: icon),
          ),
          Positioned(
            bottom: 40,
            right: 28,
            child: Icon(Icons.landscape_rounded, size: 64, color: icon),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Toggle pill "Masuk | Daftar" dengan indikator yang bergeser halus.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ToggleLabel(
                  label: 'Masuk',
                  selected: isLogin,
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _ToggleLabel(
                  label: 'Daftar',
                  selected: !isLogin,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  const _ToggleLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.teal : AppColors.muted,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Animasi masuk: fade + geser ke atas saat halaman pertama dibuka.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}