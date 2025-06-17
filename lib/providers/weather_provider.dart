import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  WeatherInfo? _info;
  bool _isLoading = false;

  WeatherInfo? get info => _info;
  bool get isLoading => _isLoading;

  Future<void> requestWeatherForCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }
      _isLoading = true;
      notifyListeners();
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      _info = await _service.fetchWeather(
          position.latitude, position.longitude);
    } catch (_) {
      // ignore errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
