import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Pure-Dart RFC 6238 TOTP (HMAC-SHA1) on top of RFC 4226 HOTP.
/// No Flutter imports, so it can be unit-tested with plain `dart test`.
class Totp {
  Totp._();

  static const int defaultDigits = 6;
  static const int defaultPeriodSeconds = 30;
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Time step index: floor(unixSeconds / period). Uses the epoch only, so the
  /// device time zone (or [DateTime.isUtc]) cannot influence the result.
  static int counterFor(
    DateTime time, {
    int periodSeconds = defaultPeriodSeconds,
  }) {
    _checkPeriod(periodSeconds);
    return _floorDiv(
      _floorDiv(time.millisecondsSinceEpoch, 1000),
      periodSeconds,
    );
  }

  /// Whole seconds left in the current step, in 1..[periodSeconds].
  static int secondsRemaining(
    DateTime time, {
    int periodSeconds = defaultPeriodSeconds,
  }) {
    _checkPeriod(periodSeconds);
    final unix = _floorDiv(time.millisecondsSinceEpoch, 1000);
    return periodSeconds - (unix % periodSeconds);
  }

  /// TOTP code for [time]. [secret] is the raw key (Base32-decoded bytes).
  static String generate(
    Uint8List secret,
    DateTime time, {
    int digits = defaultDigits,
    int periodSeconds = defaultPeriodSeconds,
  }) {
    return hotp(
      secret,
      counterFor(time, periodSeconds: periodSeconds),
      digits: digits,
    );
  }

  /// RFC 4226 HOTP with HMAC-SHA1.
  static String hotp(
    Uint8List secret,
    int counter, {
    int digits = defaultDigits,
  }) {
    if (digits < 1 || digits > 9) {
      throw ArgumentError.value(digits, 'digits', 'must be between 1 and 9');
    }
    final counterBytes = Uint8List(8)
      ..buffer.asByteData().setUint64(0, counter, Endian.big);
    final hash = Hmac(sha1, secret).convert(counterBytes).bytes; // 20 bytes
    final offset = hash[19] & 0x0f;
    final binary =
        ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);
    var mod = 1;
    for (var i = 0; i < digits; i++) {
      mod *= 10;
    }
    return (binary % mod).toString().padLeft(digits, '0');
  }

  /// Upper-cases and strips whitespace, hyphens and '=' padding.
  /// Also drops invisible characters (NBSP, zero-width, BOM) that clipboards
  /// and keyboards sometimes add.
  static String normalizeBase32(String input) => input
      .replaceAll(RegExp(r'[\s\-=\p{Z}\p{Cf}]', unicode: true), '')
      .toUpperCase();

  /// First character outside the Base32 alphabet, or null if all are valid.
  static String? firstInvalidChar(String input) {
    for (final r in normalizeBase32(input).runes) {
      final c = String.fromCharCode(r);
      if (!_alphabet.contains(c)) return c;
    }
    return null;
  }

  /// Decodes RFC 4648 Base32. Throws [FormatException] on empty input or any
  /// character outside A-Z / 2-7 (after normalisation).
  static Uint8List decodeBase32(String input) {
    final s = normalizeBase32(input);
    if (s.isEmpty) throw const FormatException('Base32 string is empty');
    final out = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final unit in s.codeUnits) {
      final value = _alphabet.indexOf(String.fromCharCode(unit));
      if (value < 0) {
        throw FormatException(
          'Invalid Base32 character "${String.fromCharCode(unit)}"',
        );
      }
      buffer = (buffer << 5) | value;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buffer >> bits) & 0xff);
        buffer &= (1 << bits) - 1;
      }
    }
    return Uint8List.fromList(out);
  }

  static bool isValidBase32(String input) {
    try {
      decodeBase32(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// "123456" -> "123 456", "12345678" -> "1234 5678".
  static String formatCode(String code) {
    if (code.length < 4) return code;
    final split = code.length ~/ 2;
    return '${code.substring(0, split)} ${code.substring(split)}';
  }

  static int _floorDiv(int a, int b) => (a - (a % b)) ~/ b;

  static void _checkPeriod(int period) {
    if (period < 1) {
      throw ArgumentError.value(period, 'periodSeconds', 'must be >= 1');
    }
  }
}
