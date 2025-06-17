import 'package:flutter/material.dart';

import 'package:intl/intl.dart';



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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info!.locationName != null) ...[
            Text(
              info!.locationName!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
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
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: info!.forecast.length,
              itemBuilder: (context, index) {
                final day = info!.forecast[index];
                final label = DateFormat.E('ar').format(day.date);
                return Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.maxTemp.round()}°/${day.minTemp.round()}°',
                        style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                );
              },

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
