import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/weather_model.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherInfo? info;
  const WeatherWidget({super.key, this.info});

  @override
  Widget build(BuildContext context) {
    if (info == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            '${info!.temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
