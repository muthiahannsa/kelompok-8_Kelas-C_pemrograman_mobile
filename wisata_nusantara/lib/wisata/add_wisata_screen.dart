
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import 'wisata_model.dart';
import 'wisata_provider.dart';

class AddWisataScreen extends StatefulWidget {
  const AddWisataScreen({super.key});

  @override
  State<AddWisataScreen> createState() => _AddWisataScreenState();
}

class _AddWisataScreenState extends State<AddWisataScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _provinsiController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _gambarUrlController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _namaController.dispose();
    _provinsiController.dispose();
    _deskripsiController.dispose();
    _gambarUrlController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _simpanWisata() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final latitude = double.tryParse(_latController.text.trim());
    final longitude = double.tryParse(_lonController.text.trim());

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Latitude atau longitude tidak valid.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final wisata = Wisata(
        id: '',
        nama: _namaController.text.trim(),
        provinsi: _provinsiController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        gambarUrl: _gambarUrlController.text.trim(),
        lat: latitude,
        lon: longitude,
      );

      await context.read<WisataProvider>().addWisata(wisata);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destinasi wisata berhasil ditambahkan.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan wisata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tambah Wisata'),
        ),
        body: const Center(
          child: Text(
            'Akses ditolak. Halaman ini hanya untuk Admin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Destinasi Wisata',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Informasi Destinasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _buildTextField(
              controller: _namaController,
              label: 'Nama Wisata',
              hint: 'Contoh: Pantai Losari',
              icon: Icons.place_outlined,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _provinsiController,
              label: 'Provinsi',
              hint: 'Contoh: Sulawesi Selatan',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _deskripsiController,
              label: 'Deskripsi Wisata',
              hint: 'Masukkan deskripsi destinasi wisata',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _gambarUrlController,
              label: 'URL Gambar',
              hint: 'https://contoh.com/gambar.jpg',
              icon: Icons.image_outlined,
            ),

            const SizedBox(height: 24),

            const Text(
              'Koordinat Lokasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildTextField(
              controller: _latController,
              label: 'Latitude',
              hint: 'Contoh: -5.1477',
              icon: Icons.my_location,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _lonController,
              label: 'Longitude',
              hint: 'Contoh: 119.4327',
              icon: Icons.explore_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _simpanWisata,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Wisata',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }

        if (label == 'URL Gambar') {
          final uri = Uri.tryParse(value.trim());

          if (uri == null ||
              !uri.hasScheme ||
              (uri.scheme != 'http' && uri.scheme != 'https') ||
              uri.host.isEmpty) {
            return 'Masukkan URL gambar yang valid';
          }
        }

        if (label == 'Latitude' || label == 'Longitude') {
          if (double.tryParse(value.trim()) == null) {
            return 'Masukkan angka yang valid';
          }
        }

        return null;
      },
    );
  }
}
