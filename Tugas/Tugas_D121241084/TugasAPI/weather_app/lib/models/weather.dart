class Weather {
  const Weather({
    required this.city,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.code,
  });

  final String city;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int code;

  factory Weather.fromJson(String city, Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return Weather(
      city: city,
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      code: (current['weather_code'] as num).toInt(),
    );
  }
}