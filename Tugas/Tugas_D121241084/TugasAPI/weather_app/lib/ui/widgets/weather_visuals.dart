import 'package:flutter/material.dart';

class WeatherVisuals {
  const WeatherVisuals._();

  static String description(int code) {
    if (code == 0) return 'Cerah';
    if (code <= 3) return 'Berawan';
    if (code <= 48) return 'Berkabut';
    if (code <= 67) return 'Hujan';
    if (code <= 77) return 'Salju';
    if (code <= 82) return 'Hujan deras';
    return 'Badai petir';
  }

  static IconData icon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 48) return Icons.foggy;
    if (code <= 82) return Icons.water_drop;
    return Icons.thunderstorm;
  }

  static Color color(int code) {
    if (code == 0) return Colors.orange;
    if (code <= 3) return Colors.blueGrey;
    if (code <= 48) return Colors.grey;
    if (code <= 82) return Colors.indigo;
    return Colors.deepPurple;
  }
}