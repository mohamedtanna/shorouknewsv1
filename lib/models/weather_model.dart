class WeatherInfo {
  final double temperature;
  final int weatherCode;

  WeatherInfo({required this.temperature, required this.weatherCode});

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'] as Map<String, dynamic>?;
    return WeatherInfo(
      temperature: (current?['temperature'] ?? 0).toDouble(),
      weatherCode: (current?['weathercode'] ?? 0).toInt(),
    );
  }
}
