/// Parsed `otpauth://totp/...` URI (Google Authenticator key-URI format).
class OtpAuthData {
  const OtpAuthData({
    required this.name,
    required this.secret,
    this.digits = 6,
    this.periodSeconds = 30,
  });

  /// Issuer if present, otherwise the label (account part is dropped when the
  /// label is "Issuer:account" and no issuer parameter exists).
  final String name;

  /// Secret exactly as found in the URI (not normalised).
  final String secret;
  final int digits;
  final int periodSeconds;
}

class OtpAuthParser {
  OtpAuthParser._();

  /// Throws [FormatException] with a user-presentable message.
  static OtpAuthData parse(String input) {
    final Uri uri;
    try {
      uri = Uri.parse(input.trim());
    } on FormatException {
      throw const FormatException('Not a valid otpauth:// link');
    }
    if (uri.scheme.toLowerCase() != 'otpauth') {
      throw const FormatException('Not an otpauth:// link');
    }
    if (uri.host.toLowerCase() != 'totp') {
      throw const FormatException('Only time-based (totp) links are supported');
    }
    final params = uri.queryParameters;
    final secret = params['secret'];
    if (secret == null || secret.trim().isEmpty) {
      throw const FormatException('The link has no secret');
    }
    final algorithm = (params['algorithm'] ?? 'SHA1').toUpperCase();
    if (algorithm != 'SHA1') {
      throw FormatException('Unsupported algorithm $algorithm (only SHA1)');
    }
    final digits = _intParam(params, 'digits', 6, 6, 8);
    final period = _intParam(params, 'period', 30, 15, 60);

    var label = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    try {
      label = Uri.decodeComponent(label);
    } on ArgumentError {
      // keep raw label
    }
    label = label.trim();
    final issuer = params['issuer']?.trim();
    var name = issuer != null && issuer.isNotEmpty ? issuer : label;
    if (issuer == null || issuer.isEmpty) {
      final colon = label.indexOf(':');
      if (colon > 0) name = label.substring(0, colon).trim();
    }
    return OtpAuthData(
      name: name,
      secret: secret,
      digits: digits,
      periodSeconds: period,
    );
  }

  static int _intParam(
      Map<String, String> p, String key, int fallback, int min, int max) {
    final raw = p[key];
    if (raw == null) return fallback;
    final v = int.tryParse(raw);
    if (v == null || v < min || v > max) {
      throw FormatException('"$key" must be between $min and $max');
    }
    return v;
  }
}
