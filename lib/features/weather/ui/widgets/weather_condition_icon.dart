import 'package:flutter/material.dart';

class WeatherConditionIcon extends StatelessWidget {
  const WeatherConditionIcon({
    super.key,
    required this.conditionCode,
    this.size = 24,
  });

  final int conditionCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCode(conditionCode);
    return Icon(icon, size: size);
  }

  IconData _iconForCode(int code) {
    if (code >= 200 && code < 300) return Icons.thunderstorm_outlined;
    if (code >= 300 && code < 400) return Icons.grain;
    if (code >= 500 && code < 600) return Icons.umbrella_outlined;
    if (code >= 600 && code < 700) return Icons.ac_unit;
    if (code >= 700 && code < 800) return Icons.foggy;
    if (code == 800) return Icons.wb_sunny_outlined;
    if (code > 800 && code < 900) return Icons.cloud_outlined;
    return Icons.help_outline;
  }
}

