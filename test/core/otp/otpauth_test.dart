import 'package:flutter_test/flutter_test.dart';
import 'package:st_authenticator/core/otp/otpauth.dart';

void main() {
  test('parses the basic form', () {
    final d = OtpAuthParser.parse(
      'otpauth://totp/Name?secret=GEZDGNBVGY3TQOJQ&digits=8&period=60',
    );
    expect(d.name, 'Name');
    expect(d.secret, 'GEZDGNBVGY3TQOJQ');
    expect(d.digits, 8);
    expect(d.periodSeconds, 60);
  });

  test('defaults and issuer/label handling', () {
    final d = OtpAuthParser.parse(
      'otpauth://totp/Acme%20Co:bob@x.com?secret=GEZDGNBVGY3TQOJQ',
    );
    expect(d.name, 'Acme Co');
    expect(d.digits, 6);
    expect(d.periodSeconds, 30);
    expect(
      OtpAuthParser.parse('otpauth://totp/x?secret=ABCDEFGH&issuer=Foo').name,
      'Foo',
    );
  });

  test('rejects bad input', () {
    for (final bad in [
      'https://example.com',
      'otpauth://hotp/N?secret=ABCDEFGH',
      'otpauth://totp/N',
      'otpauth://totp/N?secret=ABCDEFGH&algorithm=SHA256',
      'otpauth://totp/N?secret=ABCDEFGH&digits=9',
      'otpauth://totp/N?secret=ABCDEFGH&period=5',
    ]) {
      expect(
        () => OtpAuthParser.parse(bad),
        throwsFormatException,
        reason: bad,
      );
    }
  });
}
