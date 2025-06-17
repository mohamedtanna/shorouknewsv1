import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

class WeatherService {
  Future<WeatherInfo?> fetchWeather(double lat, double lon) async {

    final forecastUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&daily=weathercode,temperature_2m_max,temperature_2m_min&forecast_days=5');
    final forecastRes = await http.get(forecastUri);
    if (forecastRes.statusCode != 200) return null;
    final data = json.decode(forecastRes.body) as Map<String, dynamic>;

    String? locationName;
    try {
      final nameUri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');
      final nameRes = await http.get(nameUri, headers: {'User-Agent': 'shorouk_news'});
      if (nameRes.statusCode == 200) {
        final loc = json.decode(nameRes.body) as Map<String, dynamic>;
        final address = loc['address'] as Map<String, dynamic>?;
        locationName = address?['city'] ?? address?['town'] ?? address?['village'] ?? address?['state'];
      }
    } catch (_) {
      // ignore errors getting name
    }

    data['location_name'] = locationName;
    return WeatherInfo.fromJson(data);
=======
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
