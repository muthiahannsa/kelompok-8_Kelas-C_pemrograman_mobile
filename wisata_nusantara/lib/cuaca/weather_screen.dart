
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Sesuaikan path import ini dengan lokasi rating_widget.dart
import '../wisata/rating_widget.dart';

import 'weather_service.dart';

class WeatherScreen extends StatefulWidget {
  final String wisataId;
  final String nama;
  final String provinsi;
  final String deskripsi;
  final String gambarUrl;
  final double lat;
  final double lon;

  const WeatherScreen({
    super.key,
    required this.wisataId,
    required this.nama,
    required this.provinsi,
    required this.deskripsi,
    required this.gambarUrl,
    required this.lat,
    required this.lon,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<WeatherService>().fetchWeather(
        lat: widget.lat,
        lon: widget.lon,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Wisata'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar wisata
            Image.network(
              widget.gambarUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi wisata
                  Text(
                    widget.nama,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(widget.provinsi),
                  const SizedBox(height: 16),

                  const Text(
                    'Deskripsi Wisata',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(widget.deskripsi),
                  const SizedBox(height: 16),

                  Text('Latitude: ${widget.lat}'),
                  Text('Longitude: ${widget.lon}'),

                  const SizedBox(height: 24),

                  // Informasi cuaca
                  const Text(
                    'Informasi Cuaca Real-Time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Consumer<WeatherService>(
                    builder: (context, service, child) {
                      if (service.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (service.errorMessage != null) {
                        return Column(
                          children: [
                            Text(service.errorMessage!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                service.fetchWeather(
                                  lat: widget.lat,
                                  lon: widget.lon,
                                );
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        );
                      }

                      final weather = service.weather;

                      if (weather == null) {
                        return const Text(
                          'Data cuaca belum tersedia.',
                        );
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Image.network(
                                'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                                width: 90,
                                height: 90,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(
                                  Icons.cloud,
                                  size: 60,
                                ),
                              ),
                              Text(
                                '${weather.temperature.toStringAsFixed(1)} °C',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(weather.description),
                              const Divider(height: 28),
                              Text(
                                'Kelembapan: ${weather.humidity}%',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kecepatan Angin: ${weather.windSpeed} m/s',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Rating wisata dari Anggota 2
                  const Text(
                    'Rating dan Ulasan Wisata',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  RatingWidget(
                    wisataId: widget.wisataId,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
