import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:st_authenticator/core/otp/otpauth.dart';
import 'package:st_authenticator/core/otp/totp.dart';
import 'package:st_authenticator/features/apps/data/app_repository.dart';
import 'package:st_authenticator/features/apps/models/auth_app.dart';
import 'package:st_authenticator/features/apps/state/app_scope.dart';
import 'package:st_authenticator/core/theme/app_theme.dart';
import 'package:st_authenticator/features/apps/ui/widgets/countdown_ring.dart';
import 'package:st_authenticator/features/apps/ui/widgets/dialogs.dart';
import 'package:st_authenticator/features/apps/ui/widgets/form_section.dart';
import 'package:st_authenticator/core/theme/palette.dart';
import 'package:st_authenticator/features/apps/ui/screens/scan_screen.dart';

/// Add (existing == null) or edit an app.
class AppFormScreen extends StatefulWidget {
  const AppFormScreen({super.key, this.existing});
  final AuthApp? existing;

  @override
  State<AppFormScreen> createState() => _AppFormScreenState();
}

class _AppFormScreenState extends State<AppFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _secret;
  bool _obscure = true;
  bool _advanced = false;
  bool _saving = false;
  late int _digits;
  late int _period;
  late Color _color;
  String? _nameError;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _secret = TextEditingController(text: e?.secretBase32 ?? '');
    _digits = e?.digits ?? Totp.defaultDigits;
    _period = e?.periodSeconds ?? Totp.defaultPeriodSeconds;
    _color = e != null ? Color(e.colorValue) : accentColors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  void _apply(OtpAuthData d) {
    setState(() {
      if (_name.text.trim().isEmpty) _name.text = d.name;
      _secret.text = d.secret;
      _digits = d.digits;
      _period = d.periodSeconds;
    });
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty) return _snack('Clipboard is empty');
    if (text.toLowerCase().startsWith('otpauth://')) {
      try {
        _apply(OtpAuthParser.parse(text));
      } on FormatException catch (e) {
        _snack(e.message);
      }
    } else {
      setState(() => _secret.text = text);
    }
  }

  Future<void> _scan() async {
    var status = await Permission.camera.status;
    if (!status.isGranted && !status.isPermanentlyDenied) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await showCameraSettingsDialog(context);
      return;
    }
    if (!status.isGranted) return;
    final data = await Navigator.push<OtpAuthData>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (data != null && mounted) _apply(data);
  }

  String? _validateName(String? v) {
    final name = (v ?? '').trim();
    if (name.isEmpty) return 'Enter a name for this app';
    if (AppScope.of(context).controller
        .isNameTaken(name, exceptId: widget.existing?.id)) {
      return 'You already have an app with this name';
    }
    return _nameError;
  }

  String? _validateSecret(String? v) {
    final s = Totp.normalizeBase32(v ?? '');
    if (s.isEmpty) return 'Enter the secret key from your provider';
    if (!Totp.isValidBase32(s)) {
      final bad = Totp.firstInvalidChar(s)!;
      return 'Invalid character "$bad" (U+${bad.runes.first.toRadixString(16).toUpperCase()}). '
          'Only letters A–Z and digits 2–7 are allowed';
    }
    if (s.length < 16) {
      return 'Secret must be at least 16 characters (now ${s.length})';
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _nameError = null);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    final controller = AppScope.of(context).controller;
    final name = _name.text.trim();
    final secret = Totp.normalizeBase32(_secret.text);
    final old = widget.existing;

    if (old != null &&
        (secret != old.secretBase32 ||
            _digits != old.digits ||
            _period != old.periodSeconds)) {
      if (!await confirmReplaceSecret(context)) return;
      if (!mounted) return;
    }

    setState(() => _saving = true);
    try {
      if (old == null) {
        final app = await controller.add(
          name: name,
          secretBase32: secret,
          digits: _digits,
          periodSeconds: _period,
          colorValue: _color.toARGB32(),
        );
        if (!mounted) return;
        HapticFeedback.lightImpact();
        await _showTestCode(app);
      } else {
        await controller.update(
          old.copyWith(
            name: name,
            secretBase32: secret,
            digits: _digits,
            periodSeconds: _period,
            colorValue: _color.toARGB32(),
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } on DuplicateNameException {
      setState(() {
        _saving = false;
        _nameError = 'You already have an app with this name';
      });
      _formKey.currentState!.validate();
    } catch (e) {
      setState(() => _saving = false);
      _snack('Could not save: $e');
    }
  }

  Future<void> _showTestCode(AuthApp app) {
    final clock = AppScope.of(context).clock;
    final colors = context.colors;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ListenableBuilder(
        listenable: clock,
        builder: (ctx, _) {
          final left = app.secondsLeftAt(clock.now);
          return AlertDialog(
            title: Text('${app.name} added', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Check this code works in your app:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  Totp.formatCode(app.codeAt(clock.now)),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                    color: colors.label,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 16),
                CountdownRing(
                  secondsLeft: left,
                  period: app.periodSeconds,
                  size: 36,
                  showLabel: true,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  static const _fieldStyle = TextStyle(fontSize: 17, height: 1.3);

  InputDecoration _bare(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.fromLTRB(0, 15, suffix == null ? 16 : 0, 15),
    suffixIcon: suffix,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit app' : 'Add app')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SafeArea(
          top: false,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (!_editing) ...[
                FormSection(
                  children: [
                    InkWell(
                      onTap: _scan,
                      highlightColor: colors.fill,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 22,
                              color: colors.accent,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Scan QR code',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.tertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
              FormSection(
                header: 'App details',
                footer:
                    'Your key is stored encrypted on this device and never '
                    'leaves it.',
                children: [
                  FormRow(
                    icon: Icons.apps_rounded,
                    child: TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: _fieldStyle,
                      decoration: _bare('App name'),
                      validator: _validateName,
                      onChanged: (_) => _nameError = null,
                    ),
                  ),
                  FormRow(
                    icon: Icons.key_rounded,
                    child: TextFormField(
                      controller: _secret,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableInteractiveSelection: !_obscure,
                      keyboardType: TextInputType.visiblePassword,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        letterSpacing: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: _bare(
                        'Secret key',
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Paste',
                              icon: const Icon(Icons.content_paste_rounded),
                              onPressed: _paste,
                            ),
                            IconButton(
                              tooltip: _obscure ? 'Show secret' : 'Hide secret',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _obscure = !_obscure);
                              },
                            ),
                          ],
                        ),
                      ),
                      validator: _validateSecret,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FormSection(
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _advanced = !_advanced);
                    },
                    highlightColor: colors.fill,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Advanced',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: colors.label,
                                  ),
                                ),
                                Text(
                                  '$_digits digits · $_period s · SHA-1',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: _advanced ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: colors.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_advanced)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Digits',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: colors.label,
                                ),
                              ),
                              const Spacer(),
                              SegmentedButton<int>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(value: 6, label: Text('6')),
                                  ButtonSegment(value: 7, label: Text('7')),
                                  ButtonSegment(value: 8, label: Text('8')),
                                ],
                                selected: {_digits},
                                onSelectionChanged: (s) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _digits = s.first);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Period',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: colors.label,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$_period seconds',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: colors.secondary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            min: 15,
                            max: 60,
                            divisions: 45,
                            value: _period.toDouble(),
                            label: '$_period',
                            onChanged: (v) =>
                                setState(() => _period = v.round()),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_editing ? 'Save changes' : 'Add app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
