class WeatherInfo {
  final double temperature;
  final int weatherCode;
  final String? locationName;
  final List<DailyForecast> forecast;

  WeatherInfo({
    required this.temperature,
    required this.weatherCode,
    this.locationName,
    required this.forecast,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'] as Map<String, dynamic>?;
    final daily = json['daily'] as Map<String, dynamic>?;
    final List<DailyForecast> forecast = [];
    if (daily != null) {
      final times = daily['time'] as List<dynamic>?;
      final minTemps = daily['temperature_2m_min'] as List<dynamic>?;
      final maxTemps = daily['temperature_2m_max'] as List<dynamic>?;
      final codes = daily['weathercode'] as List<dynamic>?;
      final int count = [times?.length ?? 0, minTemps?.length ?? 0, maxTemps?.length ?? 0, codes?.length ?? 0].reduce((a, b) => a < b ? a : b);
      for (int i = 0; i < count && i < 5; i++) {
        forecast.add(DailyForecast(
          date: DateTime.tryParse(times![i].toString()) ?? DateTime.now(),
          minTemp: (minTemps![i] ?? 0).toDouble(),
          maxTemp: (maxTemps![i] ?? 0).toDouble(),
          weatherCode: (codes![i] ?? 0).toInt(),
        ));
      }
    }
    return WeatherInfo(
      temperature: (current?['temperature'] ?? 0).toDouble(),
      weatherCode: (current?['weathercode'] ?? 0).toInt(),
      locationName: json['location_name'] as String?,
      forecast: forecast,
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.weatherCode,
  });
}
=======

  WeatherInfo({required this.temperature, required this.weatherCode});

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final current = json['current_weather'] as Map<String, dynamic>?;
    return WeatherInfo(
      temperature: (current?['temperature'] ?? 0).toDouble(),
      weatherCode: (current?['weathercode'] ?? 0).toInt(),
    );
  }
}

