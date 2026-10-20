import 'package:flutter/material.dart';

const accentColors = <Color>[
  Color(0xFF1E88E5),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFFD81B60),
  Color(0xFFE53935),
  Color(0xFFF4511E),
  Color(0xFF6D4C41),
  Color(0xFF3949AB),
  Color(0xFF546E7A),
];

/// Amber in the last 5 seconds, red in the last 3.
Color urgencyColor(int secondsLeft, Color normal) {
  if (secondsLeft <= 3) return Colors.red.shade600;
  if (secondsLeft <= 5) return Colors.amber.shade700;
  return normal;
}
