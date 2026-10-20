import 'dart:typed_data';

import '../core/totp.dart';

class AuthApp {
  const AuthApp({
    required this.id,
    required this.name,
    required this.secretBase32,
    this.digits = Totp.defaultDigits,
    this.periodSeconds = Totp.defaultPeriodSeconds,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String secretBase32;
  final int digits;
  final int periodSeconds;
  final int colorValue;
  final DateTime createdAt;

  AuthApp copyWith({
    String? name,
    String? secretBase32,
    int? digits,
    int? periodSeconds,
    int? colorValue,
  }) =>
      AuthApp(
        id: id,
        name: name ?? this.name,
        secretBase32: secretBase32 ?? this.secretBase32,
        digits: digits ?? this.digits,
        periodSeconds: periodSeconds ?? this.periodSeconds,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
      );

  Uint8List get _key => Totp.decodeBase32(secretBase32);

  String codeAt(DateTime time, {int stepOffset = 0}) => Totp.generate(
        _key,
        stepOffset == 0
            ? time
            : time.add(Duration(seconds: stepOffset * periodSeconds)),
        digits: digits,
        periodSeconds: periodSeconds,
      );

  int secondsLeftAt(DateTime time) =>
      Totp.secondsRemaining(time, periodSeconds: periodSeconds);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'secret': secretBase32,
        'digits': digits,
        'period': periodSeconds,
        'color': colorValue,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory AuthApp.fromJson(Map<String, dynamic> j) => AuthApp(
        id: j['id'] as String,
        name: j['name'] as String,
        secretBase32: j['secret'] as String,
        digits: (j['digits'] as num?)?.toInt() ?? Totp.defaultDigits,
        periodSeconds:
            (j['period'] as num?)?.toInt() ?? Totp.defaultPeriodSeconds,
        colorValue: (j['color'] as num).toInt(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
