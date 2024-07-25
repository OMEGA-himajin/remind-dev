import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://weather.tsukumijima.net/api/forecast';

  Future<Map<String, dynamic>> getWeather(String cityId) async {
    final response = await http.get(Uri.parse('$_baseUrl/city/$cityId'));

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
