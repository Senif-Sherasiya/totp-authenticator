import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:st_authenticator/core/theme/app_theme.dart';
import 'package:st_authenticator/features/apps/models/auth_app.dart';

Future<bool> confirmDelete(BuildContext context, AuthApp app) async {
  HapticFeedback.mediumImpact();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete "${app.name}"?'),
      content: const Text(
        'The secret will be permanently removed from this device. Unless '
        'you have it saved somewhere else, you will not be able to '
        'generate codes for this app again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: ctx.colors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<bool> confirmReplaceSecret(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Replace secret?'),
      content: const Text(
        'Changing the secret, digits or period means codes made with the '
        'old settings will stop working in the app. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Replace'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<void> showCameraSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Camera access needed'),
      content: const Text(
        'Camera permission is turned off for this app. Open Settings and '
        'allow camera access to scan QR codes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
