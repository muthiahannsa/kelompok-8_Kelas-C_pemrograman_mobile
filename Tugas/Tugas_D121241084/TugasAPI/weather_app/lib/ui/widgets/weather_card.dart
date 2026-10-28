import 'package:flutter/material.dart';

import '../../models/weather.dart';
import 'info_tile.dart';
import 'weather_visuals.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final color = WeatherVisuals.color(weather.code);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weather.city,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Icon(WeatherVisuals.icon(weather.code), size: 80, color: color),
            Text(
              '${weather.temperature.toStringAsFixed(1)} °C',
              style: const TextStyle(fontSize: 48),
            ),
            Text(
              WeatherVisuals.description(weather.code),
              style: const TextStyle(fontSize: 20),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InfoTile(
                  icon: Icons.water_drop_outlined,
                  label: 'Kelembapan',
                  value: '${weather.humidity}%',
                ),
                InfoTile(
                  icon: Icons.air,
                  label: 'Angin',
                  value: '${weather.windSpeed} km/j',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}