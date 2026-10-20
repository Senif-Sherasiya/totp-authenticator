import 'package:flutter/material.dart';

import 'package:st_authenticator/features/apps/models/auth_app.dart';

Future<bool> confirmDelete(BuildContext context, AuthApp app) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
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
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
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
      icon: const Icon(Icons.key),
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
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Replace'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
