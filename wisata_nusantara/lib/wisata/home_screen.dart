
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'wisata_model.dart';
import 'wisata_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wisata Nusantara',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Consumer<WisataProvider>(
        builder: (context, provider, child) {
          final daftarWisata = provider.filteredWisata;
          final error = provider.errorMessage;

          return Column(
            children: [
              // Bagian pencarian
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: provider.searchWisata,
                  decoration: InputDecoration(
                    hintText: 'Cari destinasi wisata...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Filter provinsi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: provider.selectedProvinsi == ''
                      ? null
                      : provider.selectedProvinsi,
                  decoration: InputDecoration(
                    labelText: 'Filter Provinsi',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Semua Provinsi'),
                    ),
                    ...provider.daftarProvinsi.map(
                      (provinsi) => DropdownMenuItem<String>(
                        value: provinsi,
                        child: Text(provinsi),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null || value.isEmpty) {
                      provider.resetFilter();
                    } else {
                      provider.filterByProvinsi(value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Judul daftar wisata
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Jelajahi Destinasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Konten daftar wisata
              Expanded(
                child: _buildContent(
                  provider,
                  daftarWisata,
                  error,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    WisataProvider provider,
    List<Wisata> daftarWisata,
    String? error,
  ) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null && error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (daftarWisata.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada destinasi wisata.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daftarWisata.length,
      itemBuilder: (context, index) {
        final wisata = daftarWisata[index];

        return _buildWisataCard(
          context,
          provider,
          wisata,
        );
      },
    );
  }

  Widget _buildWisataCard(
    BuildContext context,
    WisataProvider provider,
    Wisata wisata,
  ) {
    final isFavorite = provider.isFavorite(wisata.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar wisata
          if (wisata.gambarUrl.isNotEmpty)
            Image.network(
              wisata.gambarUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _imagePlaceholder();
              },
            )
          else
            _imagePlaceholder(),

          // Informasi wisata
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wisata.nama,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              wisata.provinsi,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        wisata.deskripsi,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Tombol favorit
                IconButton(
                  tooltip: isFavorite
                      ? 'Hapus dari favorit'
                      : 'Tambahkan ke favorit',
                  onPressed: () {
                    provider.toggleFavorite(wisata.id);
                  },
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 50,
        color: Colors.grey,
      ),
    );
  }
}
