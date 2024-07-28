import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _hourlyWeather = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 位置情報サービスが有効かどうかを確認
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _hourlyWeather = [];
      });
      print('Location services are disabled.');
      return;
    }

    // 位置情報の権限を確認
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _hourlyWeather = [];
        });
        print('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _hourlyWeather = [];
      });
      print('Location permissions are permanently denied.');
      return;
    }

    // 現在の位置情報を取得
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _getWeather(position);
    } catch (e) {
      print('Failed to get location: $e');
    }
  }

  Future<void> _getWeather(Position position) async {
    final apiKey =
        '0a0c0fa899d5f49a5288ff7ca7fdd294'; // ここにOpenWeatherMapのAPIキーを入力
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> hourlyWeather = [];
      for (var i = 0; i < 24; i++) {
        final hourData = data['list'][i];
        hourlyWeather.add({
          'time': hourData['dt_txt'],
          'icon': hourData['weather'][0]['icon'],
          'temp': hourData['main']['temp'],
          'pop': hourData['pop'] * 100, // 降水確率は0-1の範囲なので100倍する
        });
      }
      setState(() {
        _hourlyWeather = hourlyWeather;
      });
    } else {
      setState(() {
        _hourlyWeather = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
      body: _hourlyWeather.isEmpty
          ? Center(child: Text('Loading...'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _hourlyWeather.map((weather) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(weather['time']),
                        Image.network(
                          'https://openweathermap.org/img/wn/${weather['icon']}@2x.png',
                        ),
                        Text('${weather['temp']}°C'),
                        Text('降水確率: ${weather['pop']}%'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
