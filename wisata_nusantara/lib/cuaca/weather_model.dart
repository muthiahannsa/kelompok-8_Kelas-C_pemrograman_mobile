class WeatherModel {
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;

  const WeatherModel({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'] as List<dynamic>;

    return WeatherModel(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: weather.isNotEmpty
          ? weather[0]['description'] as String
          : 'Tidak diketahui',
      icon: weather.isNotEmpty
          ? weather[0]['icon'] as String
          : '01d',
      humidity: (json['main']['humidity'] as num).toInt(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),      
    );
  }

  Map<String, dynamic> toJson() => {
        'main': {'temp': temperature, 'humidity': humidity},
        'weather': [
          {'description': description, 'icon': icon}
        ],
        'wind': {'speed': windSpeed},
      };
}