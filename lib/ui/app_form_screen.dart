import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/otpauth.dart';
import '../core/totp.dart';
import '../data/app_repository.dart';
import '../models/auth_app.dart';
import 'app_scope.dart';
import 'dialogs.dart';
import 'palette.dart';
import 'scan_screen.dart';

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
    final data = await Navigator.push<OtpAuthData>(
        context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (data != null && mounted) _apply(data);
  }

  String? _validateName(String? v) {
    final name = (v ?? '').trim();
    if (name.isEmpty) return 'App name is required';
    if (AppScope.of(context)
        .controller
        .isNameTaken(name, exceptId: widget.existing?.id)) {
      return 'An app with this name already exists';
    }
    return _nameError;
  }

  String? _validateSecret(String? v) {
    final s = Totp.normalizeBase32(v ?? '');
    if (s.isEmpty) return 'Secret is required';
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
    if (!_formKey.currentState!.validate()) return;
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
        await _showTestCode(app);
      } else {
        await controller.update(old.copyWith(
          name: name,
          secretBase32: secret,
          digits: _digits,
          periodSeconds: _period,
          colorValue: _color.toARGB32(),
        ));
      }
      if (mounted) Navigator.pop(context);
    } on DuplicateNameException {
      setState(() {
        _saving = false;
        _nameError = 'An app with this name already exists';
      });
      _formKey.currentState!.validate();
    } catch (e) {
      setState(() => _saving = false);
      _snack('Could not save: $e');
    }
  }

  Future<void> _showTestCode(AuthApp app) {
    final clock = AppScope.of(context).clock;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ListenableBuilder(
        listenable: clock,
        builder: (ctx, _) => AlertDialog(
          title: Text('${app.name} added'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Test code — check it works in your app:'),
              const SizedBox(height: 12),
              Text(Totp.formatCode(app.codeAt(clock.now)),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('${app.secondsLeftAt(clock.now)} s left'),
            ],
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit app' : 'Add app'),
        actions: [
          if (!_editing)
            IconButton(
              tooltip: 'Scan QR code',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scan,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'App name', border: OutlineInputBorder()),
              validator: _validateName,
              onChanged: (_) => _nameError = null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _secret,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              enableInteractiveSelection: !_obscure,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Secret (Base32)',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Paste',
                      icon: const Icon(Icons.content_paste),
                      onPressed: _paste,
                    ),
                    IconButton(
                      tooltip: _obscure ? 'Show secret' : 'Hide secret',
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
              ),
              validator: _validateSecret,
            ),
            const SizedBox(height: 20),
            Text('Accent color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in accentColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: c,
                      child: c.toARGB32() == _color.toARGB32()
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Advanced'),
              subtitle: Text('$_digits digits · $_period s · SHA-1'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Digits',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 6, label: Text('6')),
                    ButtonSegment(value: 7, label: Text('7')),
                    ButtonSegment(value: 8, label: Text('8')),
                  ],
                  selected: {_digits},
                  onSelectionChanged: (s) => setState(() => _digits = s.first),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Period: $_period seconds',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                Slider(
                  min: 15,
                  max: 60,
                  divisions: 45,
                  value: _period.toDouble(),
                  label: '$_period',
                  onChanged: (v) => setState(() => _period = v.round()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_editing ? 'Save changes' : 'Add app'),
            ),
          ],
        ),
      ),
    );
  }
}
