import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

/// Error dengan pesan yang siap ditampilkan ke pengguna.
class WeatherException implements Exception {
  const WeatherException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  Future<Weather> fetchWeather(String city) async {
    try {
      // 1. Cari koordinat kota
      final geoUrl = Uri.https(
        'geocoding-api.open-meteo.com',
        '/v1/search',
        {'name': city, 'count': '1'},
      );
      final geoRes = await _client.get(geoUrl).timeout(_timeout);
      if (geoRes.statusCode != 200) {
        throw const WeatherException(
          'Server pencarian kota bermasalah. Coba lagi nanti.',
        );
      }

      final geoData = jsonDecode(geoRes.body) as Map<String, dynamic>;
      final results = geoData['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        throw WeatherException('Kota "$city" tidak ditemukan.');
      }

      final place = results.first as Map<String, dynamic>;

      // 2. Ambil cuaca berdasarkan koordinat
      final weatherUrl = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': place['latitude'].toString(),
        'longitude': place['longitude'].toString(),
        'current':
            'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
      });
      final weatherRes = await _client.get(weatherUrl).timeout(_timeout);
      if (weatherRes.statusCode != 200) {
        throw const WeatherException(
          'Gagal mengambil data cuaca. Coba lagi nanti.',
        );
      }

      final weatherData = jsonDecode(weatherRes.body) as Map<String, dynamic>;
      return Weather.fromJson(place['name'] as String, weatherData);
    } on WeatherException {
      rethrow;
    } on TimeoutException {
      throw const WeatherException(
        'Koneksi terlalu lama. Periksa internet kamu.',
      );
    } on http.ClientException {
      throw const WeatherException(
        'Tidak dapat terhubung ke internet. Periksa koneksi kamu.',
      );
    } on FormatException {
      throw const WeatherException('Data dari server tidak dapat dibaca.');
    }
  }
}