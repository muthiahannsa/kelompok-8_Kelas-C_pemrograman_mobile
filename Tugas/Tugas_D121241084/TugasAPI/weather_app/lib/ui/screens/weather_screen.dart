import 'package:flutter/material.dart';

import '../../models/weather.dart';
import '../../services/weather_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/weather_card.dart';
import '../widgets/weather_visuals.dart';

enum _Status { loading, success, error }

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _service = WeatherService();
  final TextEditingController _controller = TextEditingController();

  // STATE
  _Status _status = _Status.loading;
  Weather? _weather;
  String _errorMessage = '';
  String _city = 'Makassar';

  @override
  void initState() {
    super.initState();
    _load(); // data langsung dimuat saat halaman dibuka
  }

  Future<void> _load() async {
    setState(() {
      _status = _Status.loading;
    });

    try {
      final result = await _service.fetchWeather(_city);
      if (!mounted) return;
      setState(() {
        _weather = result;
        _status = _Status.success;
      });
    } on WeatherException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _status = _Status.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan yang tidak diketahui.';
        _status = _Status.error;
      });
    }
  }

  void _search() {
    final city = _controller.text.trim();
    if (city.isEmpty) return;
    FocusScope.of(context).unfocus();
    _city = city;
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color? get _backgroundColor {
    final weather = _weather;
    if (_status != _Status.success || weather == null) return null;
    return WeatherVisuals.color(weather.code).withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cuaca Hari Ini',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Cari kota',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _search,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // Memilih tampilan sesuai state saat ini
  Widget _buildBody() {
    final weather = _weather;

    return switch (_status) {
      _Status.loading => const LoadingView(),
      _Status.error => ErrorView(message: _errorMessage, onRetry: _load),
      _Status.success when weather != null => Center(
          child: SingleChildScrollView(
            child: WeatherCard(weather: weather),
          ),
        ),
      _Status.success => const LoadingView(),
    };
  }
}