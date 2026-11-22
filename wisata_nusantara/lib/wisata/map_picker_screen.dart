import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

/// Halaman pemilih lokasi. Mengembalikan [LatLng] lewat Navigator.pop.
///
/// Memakai peta OpenStreetMap (gratis, tanpa API key). Pengguna dapat
/// mengetuk peta untuk menaruh pin, atau mencari nama tempat.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _PlaceResult {
  const _PlaceResult({required this.name, required this.point});

  final String name;
  final LatLng point;
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _centerIndonesia = LatLng(-2.5, 118.0);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _picked;
  bool _isSearching = false;
  String? _searchError;
  List<_PlaceResult> _results = [];

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _searchError = null;
      _results = [];
    });

    try {
      // Geocoding gratis dari OpenStreetMap (Nominatim)
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'id',
      });

      final response = await http
          .get(uri, headers: {'Accept-Language': 'id'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Kode ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final hasil = data.map((item) {
        final map = item as Map<String, dynamic>;
        return _PlaceResult(
          name: map['display_name'] as String? ?? '',
          point: LatLng(
            double.parse(map['lat'] as String),
            double.parse(map['lon'] as String),
          ),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _results = hasil;
        if (hasil.isEmpty) _searchError = 'Lokasi tidak ditemukan.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Pencarian gagal. Periksa koneksi internet.';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectResult(_PlaceResult result) {
    setState(() {
      _picked = result.point;
      _results = [];
    });
    _mapController.move(result.point, 15);
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initial ?? _centerIndonesia,
              initialZoom: widget.initial != null ? 14 : 4.6,
              minZoom: 3,
              maxZoom: 18,
              onTap: (tapPosition, point) => setState(() {
                _picked = point;
                _results = [];
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.wisata_nusantara',
              ),
              if (picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: picked,
                      width: 52,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 52,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Kolom pencarian + hasil
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Cari tempat, mis. Pantai Losari',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Cari',
                              icon: const Icon(Icons.arrow_forward_rounded),
                              onPressed: _search,
                            ),
                    ),
                  ),
                ),
                if (_searchError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _searchError!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                if (_results.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.place_outlined,
                              color: AppColors.teal,
                            ),
                            title: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectResult(item),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Panel bawah
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            picked == null
                                ? 'Ketuk peta untuk menaruh pin lokasi'
                                : '${picked.latitude.toStringAsFixed(6)}, '
                                    '${picked.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: picked == null
                                  ? AppColors.muted
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: picked == null
                          ? null
                          : () => Navigator.pop(context, picked),
                      child: const Text('Gunakan Lokasi Ini'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Peta © OpenStreetMap contributors',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}