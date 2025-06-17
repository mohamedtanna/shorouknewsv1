import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

class WeatherService {
  Future<WeatherInfo?> fetchWeather(double lat, double lon) async {
    final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return WeatherInfo.fromJson(data);
    }
    return null;
  }
}
