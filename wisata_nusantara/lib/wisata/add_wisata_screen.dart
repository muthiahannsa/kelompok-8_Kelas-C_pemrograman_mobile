import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../theme/app_theme.dart';
import 'gambar_wisata.dart';
import 'kategori.dart';
import 'map_picker_screen.dart';
import 'wisata_model.dart';
import 'wisata_provider.dart';

/// Form tambah destinasi. Bila [wisata] diisi, form berubah menjadi mode Edit.
class AddWisataScreen extends StatefulWidget {
  const AddWisataScreen({super.key, this.wisata});

  final Wisata? wisata;

  @override
  State<AddWisataScreen> createState() => _AddWisataScreenState();
}

class _AddWisataScreenState extends State<AddWisataScreen> {
  static const List<String> _daftarProvinsi = [
    'Aceh',
    'Sumatera Utara',
    'Sumatera Barat',
    'Riau',
    'Kepulauan Riau',
    'Jambi',
    'Sumatera Selatan',
    'Kepulauan Bangka Belitung',
    'Bengkulu',
    'Lampung',
    'DKI Jakarta',
    'Banten',
    'Jawa Barat',
    'Jawa Tengah',
    'DI Yogyakarta',
    'Jawa Timur',
    'Bali',
    'Nusa Tenggara Barat',
    'Nusa Tenggara Timur',
    'Kalimantan Barat',
    'Kalimantan Tengah',
    'Kalimantan Selatan',
    'Kalimantan Timur',
    'Kalimantan Utara',
    'Sulawesi Utara',
    'Gorontalo',
    'Sulawesi Tengah',
    'Sulawesi Barat',
    'Sulawesi Selatan',
    'Sulawesi Tenggara',
    'Maluku',
    'Maluku Utara',
    'Papua',
    'Papua Barat',
    'Papua Barat Daya',
    'Papua Selatan',
    'Papua Tengah',
    'Papua Pegunungan',
  ];

  // Batas ukuran string gambar agar dokumen Firestore tidak melewati 1 MB
  static const int _maksUkuranGambar = 900000;

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  final _picker = ImagePicker();
  Uint8List? _fotoBytes; // foto baru yang dipilih dari galeri

  String? _provinsi;
  String _kategori = KategoriWisata.lainnya;
  bool _populer = false;
  bool _isSaving = false;

  bool get _isEdit => widget.wisata != null;

  @override
  void initState() {
    super.initState();
    final w = widget.wisata;
    if (w != null) {
      _namaController.text = w.nama;
      _deskripsiController.text = w.deskripsi;
      _latController.text = w.lat.toString();
      _lonController.text = w.lon.toString();
      _provinsi = w.provinsi.isEmpty ? null : w.provinsi;
      _kategori = w.kategori;
      _populer = w.populer;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
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
      _snack('Gagal memilih foto: $e', isError: true);
    }
  }

  Future<void> _pilihDiPeta() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    final initial = (lat != null && lon != null) ? LatLng(lat, lon) : null;

    final hasil = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => MapPickerScreen(initial: initial)),
    );

    if (hasil == null || !mounted) return;
    setState(() {
      _latController.text = hasil.latitude.toStringAsFixed(6);
      _lonController.text = hasil.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final latitude = double.tryParse(_latController.text.trim());
    final longitude = double.tryParse(_lonController.text.trim());

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _snack('Lokasi belum valid. Pilih lokasi di peta.', isError: true);
      return;
    }

    // Foto baru diubah ke base64; jika tidak ada foto baru, pakai yang lama
    final gambar = _fotoBytes != null
        ? 'data:image/jpeg;base64,${base64Encode(_fotoBytes!)}'
        : (widget.wisata?.gambarUrl ?? '');

    if (gambar.length > _maksUkuranGambar) {
      _snack('Foto terlalu besar, pilih foto lain.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final wisata = Wisata(
        id: widget.wisata?.id ?? '',
        nama: _namaController.text.trim(),
        provinsi: _provinsi ?? '',
        kategori: _kategori,
        deskripsi: _deskripsiController.text.trim(),
        gambarUrl: gambar,
        lat: latitude,
        lon: longitude,
        populer: _populer,
      );

      final provider = context.read<WisataProvider>();
      if (_isEdit) {
        await provider.updateWisata(wisata);
      } else {
        await provider.addWisata(wisata);
      }

      if (!mounted) return;

      _snack(
        _isEdit
            ? 'Perubahan berhasil disimpan.'
            : 'Destinasi wisata berhasil ditambahkan.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack(
        'Gagal menyimpan: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tambah Wisata')),
        body: const Center(
          child: Text(
            'Akses ditolak. Halaman ini hanya untuk Admin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Pastikan provinsi lama (bila tidak ada di daftar) tetap bisa dipilih
    final itemsProvinsi = [
      ..._daftarProvinsi,
      if (_provinsi != null && !_daftarProvinsi.contains(_provinsi))
        _provinsi!,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Destinasi' : 'Tambah Destinasi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _FormSection('Informasi Destinasi'),
            TextFormField(
              controller: _namaController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Nama wisata, mis. Pantai Losari',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _provinsi,
              isExpanded: true,
              menuMaxHeight: 320,
              decoration: const InputDecoration(
                hintText: 'Pilih provinsi',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: [
                for (final p in itemsProvinsi)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) => setState(() => _provinsi = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Provinsi wajib dipilih' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final k in KategoriWisata.semua)
                  DropdownMenuItem(
                    value: k,
                    child: Row(
                      children: [
                        Icon(KategoriWisata.ikon(k),
                            size: 18, color: AppColors.teal),
                        const SizedBox(width: 10),
                        Text(k),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) =>
                  setState(() => _kategori = v ?? KategoriWisata.lainnya),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _deskripsiController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Deskripsi destinasi wisata',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(Icons.description_outlined),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Deskripsi wajib diisi'
                  : null,
            ),
            const SizedBox(height: 22),
            const _FormSection('Foto Destinasi'),
            _buildFotoField(),
            const SizedBox(height: 22),
            const _FormSection('Lokasi di Peta'),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pilihDiPeta,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.map_rounded),
              label: Text(
                _latController.text.isEmpty
                    ? 'Pilih lokasi di peta'
                    : 'Ubah lokasi di peta',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _koordinatField(_latController, 'Latitude')),
                const SizedBox(width: 12),
                Expanded(child: _koordinatField(_lonController, 'Longitude')),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: SwitchListTile(
                value: _populer,
                onChanged: (v) => setState(() => _populer = v),
                activeThumbColor: AppColors.teal,
                title: const Text(
                  'Tampilkan di Rekomendasi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Muncul di carousel halaman utama'),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _simpan,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving
                      ? 'Menyimpan...'
                      : (_isEdit ? 'Simpan Perubahan' : 'Simpan Wisata'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoField() {
    final urlLama = widget.wisata?.gambarUrl ?? '';
    final adaFoto = _fotoBytes != null || urlLama.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: _fotoBytes != null
                ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                : gambarWisata(urlLama, height: 180),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _pilihFoto,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.teal,
            side: const BorderSide(color: AppColors.teal, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            adaFoto ? 'Ganti foto' : 'Pilih foto dari galeri',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _koordinatField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(hintText: label),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return 'Pilih lokasi';
        if (double.tryParse(value) == null) return 'Angka tidak valid';
        return null;
      },
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }
}