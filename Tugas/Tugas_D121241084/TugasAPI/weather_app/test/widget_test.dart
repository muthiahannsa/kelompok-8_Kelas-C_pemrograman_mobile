import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/weather.dart';
import 'package:weather_app/ui/widgets/error_view.dart';
import 'package:weather_app/ui/widgets/weather_card.dart';

void main() {
  testWidgets('ErrorView menampilkan pesan dan tombol Coba lagi',
      (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Kota tidak ditemukan.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Kota tidak ditemukan.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
  });

  testWidgets('WeatherCard menampilkan data cuaca', (tester) async {
    const weather = Weather(
      city: 'Makassar',
      temperature: 30.7,
      humidity: 48,
      windSpeed: 5.6,
      code: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WeatherCard(weather: weather)),
      ),
    );

    expect(find.text('Makassar'), findsOneWidget);
    expect(find.text('30.7 °C'), findsOneWidget);
    expect(find.text('Berawan'), findsOneWidget);
    expect(find.text('48%'), findsOneWidget);
  });
}