import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import 'gambar_wisata.dart';
import 'kategori.dart';
import 'wisata_model.dart';
import 'wisata_provider.dart';

class EditWisataScreen extends StatefulWidget {
  final Wisata wisata;

  const EditWisataScreen({super.key, required this.wisata});

  @override
  State<EditWisataScreen> createState() => _EditWisataScreenState();
}

class _EditWisataScreenState extends State<EditWisataScreen> {
  // Batas ukuran string gambar agar dokumen Firestore tidak melewati 1 MB
  static const int _maksUkuranGambar = 900000;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _namaController;
  late final TextEditingController _provinsiController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  late String _selectedKategori;

  Uint8List? _fotoBytes; // foto baru yang dipilih dari galeri
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.wisata.nama);
    _provinsiController = TextEditingController(text: widget.wisata.provinsi);
    _deskripsiController = TextEditingController(text: widget.wisata.deskripsi);
    _latController = TextEditingController(text: widget.wisata.lat.toString());
    _lonController = TextEditingController(text: widget.wisata.lon.toString());
    _selectedKategori = KategoriWisata.normalisasi(widget.wisata.kategori);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _provinsiController.dispose();
    _deskripsiController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70, // kecilkan ukuran agar muat di Firestore
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _fotoBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openGoogleMapsHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.map_rounded, color: AppColors.teal),
            SizedBox(width: 8),
            Text(
              'Ambil Koordinat',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cara mendapatkan koordinat dari Google Maps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. Buka Google Maps di browser atau aplikasi'),
              SizedBox(height: 4),
              Text('2. Cari lokasi wisata yang diinginkan'),
              SizedBox(height: 4),
              Text('3. Klik kanan pada titik lokasi (di browser)\n    atau tekan lama (di HP)'),
              SizedBox(height: 4),
              Text('4. Koordinat akan muncul (Latitude, Longitude)'),
              SizedBox(height: 4),
              Text('5. Salin dan tempel ke kolom Latitude & Longitude'),
              SizedBox(height: 16),
              Text(
                'Contoh format:\nLatitude: -7.6079\nLongitude: 110.2038',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanPerubahan() async {
    if (!_formKey.currentState!.validate()) return;

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
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Foto baru diubah ke base64; jika tidak ada foto baru, pakai yang lama
    final gambar = _fotoBytes != null
        ? 'data:image/jpeg;base64,${base64Encode(_fotoBytes!)}'
        : widget.wisata.gambarUrl;

    if (gambar.length > _maksUkuranGambar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto terlalu besar, pilih foto lain.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedWisata = Wisata(
        id: widget.wisata.id,
        nama: _namaController.text.trim(),
        provinsi: _provinsiController.text.trim(),
        kategori: _selectedKategori,
        deskripsi: _deskripsiController.text.trim(),
        gambarUrl: gambar,
        lat: latitude,
        lon: longitude,
        populer: widget.wisata.populer,
      );

      await context.read<WisataProvider>().updateWisata(updatedWisata);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destinasi wisata berhasil diperbarui.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui wisata: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Wisata')),
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
          'Edit Destinasi Wisata',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview foto (foto baru, atau foto lama jika belum diganti)
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
              ),
              clipBehavior: Clip.antiAlias,
              child: _fotoBytes != null
                  ? Image.memory(
                      _fotoBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : gambarWisata(widget.wisata.gambarUrl, height: 180),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isSaving ? null : _pilihFoto,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(
                  (_fotoBytes != null || widget.wisata.gambarUrl.isNotEmpty)
                      ? 'Ganti Foto'
                      : 'Pilih Foto dari Galeri',
                ),
              ),
            ),

            const SizedBox(height: 8),

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

            // Dropdown Kategori
            DropdownButtonFormField<String>(
              initialValue: _selectedKategori,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Kategori',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                for (final kategori in KategoriWisata.semua)
                  DropdownMenuItem(
                    value: kategori,
                    child: Text(kategori),
                  ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedKategori = val);
                }
              },
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _deskripsiController,
              label: 'Deskripsi Wisata',
              hint: 'Masukkan deskripsi destinasi wisata',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 24),

            const Text(
              'Koordinat Lokasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Tombol bantuan Google Maps
            OutlinedButton.icon(
              onPressed: _openGoogleMapsHelp,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Cara Ambil Koordinat dari Google Maps'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                onPressed: _isSaving ? null : _simpanPerubahan,
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
                  _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
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