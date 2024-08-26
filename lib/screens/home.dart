import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../main.dart' as main;

class WeatherData {
  final String cityName;
  final List<WeatherForecast> forecasts;

  WeatherData({required this.cityName, required this.forecasts});
}

class WeatherForecast {
  final DateTime dateTime;
  final int weatherCode;
  final double temperature;
  final double precipitationProbability;

  WeatherForecast({
    required this.dateTime,
    required this.weatherCode,
    required this.temperature,
    required this.precipitationProbability,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  WeatherData? _weatherData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
        main.uid = user?.uid ?? '';
      });
      _fetchWeatherData();
    });
  }

  Future<void> _fetchWeatherData() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('位置情報の権限が拒否されました');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('位置情報の権限が永久に拒否されています。設定から変更してください。');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('Position: ${position.latitude}, ${position.longitude}');

      final weatherData = await getWeatherData(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _weatherData = weatherData;
        _errorMessage = '';
      });
    } catch (e) {
      print('Error in _fetchWeatherData: $e');
      setState(() {
        _errorMessage = '天気情報の取得に失敗しました: $e';
      });
    }
  }

  Future<WeatherData> getWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    const apiUrl = 'https://api.openweathermap.org/data/2.5/forecast';
    const apiKey = '0a0c0fa899d5f49a5288ff7ca7fdd294';

    final response = await http.get(Uri.parse(
      '$apiUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
    ));
    print('API Response: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final cityName = data['city']['name'];
      final forecasts = <WeatherForecast>[];
      for (final item in data['list']) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        final weatherCode = item['weather'][0]['id'] as int;
        final temperature = (item['main']['temp'] as num).toDouble();
        final precipitationProbability = (item['pop'] as num).toDouble() * 100;
        forecasts.add(WeatherForecast(
          dateTime: dateTime,
          weatherCode: weatherCode,
          temperature: temperature,
          precipitationProbability: precipitationProbability,
        ));
      }
      return WeatherData(cityName: cityName, forecasts: forecasts);
    } else {
      throw Exception('Failed to fetch weather data: ${response.statusCode}');
    }
  }

  Widget getWeatherIcon(int weatherCode) {
    Color iconColor;
    IconData iconData;

    switch (weatherCode) {
      case 200:
      case 201:
      case 202:
      case 210:
      case 211:
      case 212:
      case 221:
      case 230:
      case 231:
      case 232:
        iconColor = Colors.yellow[700]!;
        iconData = Icons.thunderstorm;
        break;
      case 300:
      case 301:
      case 302:
      case 310:
      case 311:
      case 312:
      case 313:
      case 314:
      case 321:
        iconColor = Colors.blue[600]!;
        iconData = Icons.water_drop;
        break;
      case 500:
      case 501:
      case 502:
      case 503:
      case 504:
      case 511:
      case 520:
      case 521:
      case 522:
      case 531:
        iconColor = Colors.blue[800]!;
        iconData = Icons.umbrella;
        break;
      case 600:
      case 601:
      case 602:
      case 611:
      case 612:
      case 613:
      case 615:
      case 616:
      case 620:
      case 621:
      case 622:
        iconColor = Colors.white;
        iconData = Icons.ac_unit;
        break;
      case 701:
      case 711:
      case 721:
      case 731:
      case 741:
      case 751:
      case 761:
      case 762:
      case 771:
      case 781:
        iconColor = Colors.grey[600]!;
        iconData = Icons.air;
        break;
      case 800:
        iconColor = Colors.yellow[600]!;
        iconData = Icons.wb_sunny;
        break;
      case 801:
      case 802:
      case 803:
      case 804:
        iconColor = Colors.grey[700]!;
        iconData = Icons.cloud;
        break;
      default:
        iconColor = Colors.grey[600]!;
        iconData = Icons.help;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 64,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ようこそ、${_user?.email ?? 'ゲスト'}さん'),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            if (_weatherData != null) ...[
              Text(
                '${_weatherData!.cityName}の天気予報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weatherData!.forecasts.length,
                  itemBuilder: (context, index) {
                    final forecast = _weatherData!.forecasts[index];
                    final formattedDate =
                        DateFormat('MM月dd日 HH').format(forecast.dateTime);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(formattedDate),
                          getWeatherIcon(forecast.weatherCode),
                          Text('${forecast.temperature.toStringAsFixed(1)}°C'),
                          Text(
                              '${forecast.precipitationProbability.toStringAsFixed(0)}%'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}