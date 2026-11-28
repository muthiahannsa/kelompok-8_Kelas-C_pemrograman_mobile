
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import 'weather_model.dart';

class WeatherService extends ChangeNotifier {
  WeatherModel? weather;
  bool isLoading = false;
  String? errorMessage;

  static const String _apiKey = ApiKeys.openWeatherApiKey;

  Future<void> fetchWeather({
    required double lat,
    required double lon,
  }) async {
    isLoading = true;
    errorMessage = null;
    weather = null;
    notifyListeners();

    try {
      if (_apiKey.isEmpty) {
        throw Exception('API Key belum dikonfigurasi.');
      }

      final uri = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/weather',
        {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'appid': _apiKey,
          'units': 'metric',
          'lang': 'id',
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        weather = WeatherModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('API Key tidak valid atau belum aktif.');
      } else if (response.statusCode == 429) {
        throw Exception('Batas permintaan API telah tercapai.');
      } else {
        throw Exception(
          'Gagal mengambil cuaca. Kode: ${response.statusCode}',
        );
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
