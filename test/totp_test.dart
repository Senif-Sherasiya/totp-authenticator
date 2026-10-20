import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:st_authenticator/core/totp.dart';

void main() {
  final rfcSecret = Uint8List.fromList(ascii.encode('12345678901234567890'));
  DateTime at(int unix) =>
      DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true);

  group('RFC 6238 Appendix B (SHA-1)', () {
    const vectors = {
      59: '94287082',
      1111111109: '07081804',
      1111111111: '14050471',
      1234567890: '89005924',
      2000000000: '69279037',
      20000000000: '65353130',
    };
    vectors.forEach((unix, code8) {
      test('t=$unix', () {
        expect(Totp.generate(rfcSecret, at(unix), digits: 8), code8);
        expect(Totp.generate(rfcSecret, at(unix)),
            code8.substring(2)); // 6 digits = last 6
      });
    });
  });

  group('time handling', () {
    test('same instant in UTC, +05:30 and -07:00 gives the same code', () {
      final utc = DateTime.parse('2001-09-09T01:46:40Z');
      final plus = DateTime.parse('2001-09-09T07:16:40+05:30');
      final minus = DateTime.parse('2001-09-08T18:46:40-07:00');
      expect(plus.millisecondsSinceEpoch, utc.millisecondsSinceEpoch);
      expect(minus.millisecondsSinceEpoch, utc.millisecondsSinceEpoch);
      final expected = Totp.generate(rfcSecret, utc);
      expect(Totp.generate(rfcSecret, plus), expected);
      expect(Totp.generate(rfcSecret, minus), expected);
      expect(Totp.generate(rfcSecret, utc.toLocal()), expected);
    });

    test('stable within a step, changes at the boundary', () {
      final a = Totp.generate(rfcSecret, at(30)); // step 1 start
      expect(Totp.generate(rfcSecret, at(59)), a);
      expect(Totp.generate(rfcSecret, at(60)), isNot(a));
      expect(Totp.counterFor(at(29)), 0);
      expect(Totp.counterFor(at(30)), 1);
      expect(Totp.secondsRemaining(at(30)), 30);
      expect(Totp.secondsRemaining(at(59)), 1);
    });

    test('non-default digits and period', () {
      final c = Totp.generate(rfcSecret, at(0), digits: 8, periodSeconds: 60);
      expect(c.length, 8);
      expect(Totp.generate(rfcSecret, at(59), digits: 8, periodSeconds: 60), c);
      expect(Totp.generate(rfcSecret, at(60), digits: 8, periodSeconds: 60),
          isNot(c));
      expect(Totp.counterFor(at(119), periodSeconds: 60), 1);
      expect(Totp.generate(rfcSecret, at(0), digits: 7).length, 7);
    });
  });

  group('Base32', () {
    test('decodes RFC 4648 vector', () {
      expect(utf8.decode(Totp.decodeBase32('MZXW6YTBOI======')), 'foobar');
    });
    test('accepts lowercase, spaces, hyphens, no padding', () {
      expect(utf8.decode(Totp.decodeBase32('mzxw 6ytb-oi')), 'foobar');
    });
    test('invalid characters throw', () {
      expect(() => Totp.decodeBase32('MZXW1YTB'), throwsFormatException);
      expect(() => Totp.decodeBase32('MZXW6YT!'), throwsFormatException);
      expect(() => Totp.decodeBase32(''), throwsFormatException);
      expect(Totp.isValidBase32('MZXW6YTBOI'), isTrue);
      expect(Totp.isValidBase32('8888'), isFalse);
    });
    test('base32 secret yields the RFC code', () {
      // Base32 of "12345678901234567890"
      final key = Totp.decodeBase32('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');
      expect(Totp.generate(key, at(59), digits: 8), '94287082');
    });
  });

  test('formatCode groups digits', () {
    expect(Totp.formatCode('123456'), '123 456');
    expect(Totp.formatCode('12345678'), '1234 5678');
  });
}
