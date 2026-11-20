
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'rating_provider.dart';

class RatingWidget extends StatefulWidget {
  final String wisataId;

  const RatingWidget({
    super.key,
    required this.wisataId,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  final _ulasanController = TextEditingController();

  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRating();
    });
  }

  Future<void> _loadRating() async {
    final provider = context.read<RatingProvider>();

    await provider.loadRatings(widget.wisataId);

    if (!mounted) return;

    final ratingSaya = provider.ratingSaya;

    if (ratingSaya != null) {
      setState(() {
        _selectedRating = ratingSaya.rating;
        _ulasanController.text = ratingSaya.ulasan;
      });
    }
  }

  @override
  void dispose() {
    _ulasanController.dispose();
    super.dispose();
  }

  // Mengirim rating dan ulasan
  Future<void> _submitRating() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (_ulasanController.text.trim().isEmpty) {
      _showMessage('Ulasan tidak boleh kosong.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await context.read<RatingProvider>().submitRating(
        wisataId: widget.wisataId,
        rating: _selectedRating,
        ulasan: _ulasanController.text,
      );

      if (!mounted) return;

      _showMessage('Rating berhasil disimpan.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal menyimpan rating: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Menghapus rating pengguna
  Future<void> _deleteRating() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Rating'),
          content: const Text(
            'Apakah kamu yakin ingin menghapus rating ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true || !mounted) return;

    try {
      await context.read<RatingProvider>().deleteRating(
        widget.wisataId,
      );

      if (!mounted) return;

      setState(() {
        _selectedRating = 5;
        _ulasanController.clear();
      });

      _showMessage('Rating berhasil dihapus.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal menghapus rating: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Tampilan bintang
  Widget _buildStars({
    required int rating,
    double size = 24,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RatingProvider>(
      builder: (context, provider, child) {
        final ratingSaya = provider.ratingSaya;
        final isLoggedIn =
            FirebaseAuth.instance.currentUser != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dan rata-rata rating
            const Text(
              'Rating dan Ulasan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          provider.rataRataRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStars(
                          rating: provider.rataRataRating.round(),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.jumlahRating} ulasan',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    const Expanded(
                      child: Text(
                        'Penilaian dari pengguna yang telah mengunjungi destinasi ini.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Form rating
            const Text(
              'Berikan Penilaianmu',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (!isLoggedIn)
              const Text(
                'Silakan login untuk memberikan rating dan ulasan.',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              Row(
                children: List.generate(5, (index) {
                  final value = index + 1;

                  return IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _selectedRating = value;
                            });
                          },
                    icon: Icon(
                      value <= _selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),

              Text(
                '$_selectedRating dari 5 bintang',
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _ulasanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tuliskan pengalamanmu mengunjungi tempat ini...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : Text(
                          ratingSaya == null
                              ? 'Kirim Rating'
                              : 'Perbarui Rating',
                        ),
                ),
              ),

              if (ratingSaya != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSubmitting ? null : _deleteRating,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Hapus Rating Saya',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
            ],

            const Divider(height: 32),

            // Daftar ulasan
            const Text(
              'Ulasan Pengguna',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (provider.isLoading && provider.daftarRating.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (provider.errorMessage != null)
              Column(
                children: [
                  Text(provider.errorMessage!),
                  TextButton(
                    onPressed: _loadRating,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              )
            else if (provider.daftarRating.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada ulasan untuk destinasi ini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...provider.daftarRating.map((rating) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pengguna ${rating.uid.substring(0, rating.uid.length > 6 ? 6 : rating.uid.length)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${rating.createdAt.day}/${rating.createdAt.month}/${rating.createdAt.year}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        _buildStars(
                          rating: rating.rating,
                          size: 18,
                        ),

                        const SizedBox(height: 8),

                        Text(rating.ulasan),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
