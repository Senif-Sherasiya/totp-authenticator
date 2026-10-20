import 'package:flutter/material.dart';

import 'package:st_authenticator/core/theme/app_theme.dart';
import 'package:st_authenticator/features/apps/state/app_scope.dart';

String _fmt(DateTime t) {
  final u = t.toUtc();
  String p(int v) => v.toString().padLeft(2, '0');
  return '${u.year}-${p(u.month)}-${p(u.day)} '
      '${p(u.hour)}:${p(u.minute)}:${p(u.second)} UTC';
}

/// App-bar icon that shows the device time on tap, since codes depend on it.
class TimeButton extends StatelessWidget {
  const TimeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Device time',
      icon: Icon(Icons.info_outline_rounded, color: context.colors.accent),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const _TimeDialog(),
      ),
    );
  }
}

class _TimeDialog extends StatelessWidget {
  const _TimeDialog();

  @override
  Widget build(BuildContext context) {
    final clock = AppScope.of(context).clock;
    final colors = context.colors;
    return AlertDialog(
      title: const Text('Device time'),
      content: ListenableBuilder(
        listenable: clock,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fmt(clock.now),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.label,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Codes need an accurate clock. Keep automatic date & time on.',
              style: TextStyle(fontSize: 13, color: colors.tertiary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
