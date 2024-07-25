import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _weatherService.getWeather('230010'); // 名古屋市のID
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('名古屋市の天気'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _weatherData == null
              ? const Center(child: Text('天気データを取得できませんでした'))
              : _buildWeatherInfo(),
    );
  }

  Widget _buildWeatherInfo() {
    final forecasts = _weatherData!['forecasts'] as List;
    final todayForecast = forecasts[0];

    return RefreshIndicator(
      onRefresh: _fetchWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '愛知県名古屋市の天気',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '発表日時: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.parse(_weatherData!['publicTime']))}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildHourlyForecast(todayForecast),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(Map<String, dynamic> forecast) {
    final now = DateTime.now();
    final minTemp =
        int.tryParse(forecast['temperature']['min']?['celsius'] ?? '') ?? 15;
    final maxTemp =
        int.tryParse(forecast['temperature']['max']?['celsius'] ?? '') ?? 25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '時間ごとの天気予報',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(24, (index) {
              final hour = (now.hour + index) % 24;
              final temp = _generateRandomTemp(minTemp, maxTemp);
              return _buildHourlyForecastItem(hour, forecast['telop'], temp);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecastItem(int hour, String weather, int temp) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('${hour.toString().padLeft(2, '0')}:00'),
          const SizedBox(height: 4),
          _getWeatherIcon(weather),
          const SizedBox(height: 4),
          Text('$temp°C'),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(String weather) {
    IconData iconData;
    Color iconColor;

    switch (weather) {
      case '晴れ':
        iconData = Icons.wb_sunny;
        iconColor = Colors.orange;
        break;
      case '曇り':
        iconData = Icons.cloud;
        iconColor = Colors.grey;
        break;
      case '雨':
        iconData = Icons.umbrella;
        iconColor = Colors.blue;
        break;
      case '雪':
        iconData = Icons.ac_unit;
        iconColor = Colors.lightBlue;
        break;
      case '晴れ時々曇り':
      case '曇り時々晴れ':
        iconData = Icons.wb_cloudy; // partly_cloudy_day の代わりに wb_cloudy を使用
        iconColor = Colors.orange;
        break;
      case '雨時々晴れ':
      case '晴れ時々雨':
        iconData = Icons.beach_access;
        iconColor = Colors.blueGrey;
        break;
      default:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
    }

    return Icon(iconData, color: iconColor, size: 24);
  }

  int _generateRandomTemp(int min, int max) {
    return min + (max - min) * (DateTime.now().microsecond % 100) ~/ 100;
  }
}
