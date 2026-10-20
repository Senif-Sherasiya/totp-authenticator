import 'package:flutter/material.dart';

import 'app_scope.dart';

class TimeBanner extends StatelessWidget {
  const TimeBanner({super.key});

  static String _fmt(DateTime t) {
    final u = t.toUtc();
    String p(int v) => v.toString().padLeft(2, '0');
    return '${u.year}-${p(u.month)}-${p(u.day)} '
        '${p(u.hour)}:${p(u.minute)}:${p(u.second)} UTC';
  }

  @override
  Widget build(BuildContext context) {
    final clock = AppScope.of(context).clock;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListenableBuilder(
        listenable: clock,
        builder: (context, _) => Row(
          children: [
            Icon(Icons.schedule, size: 18, color: scheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'Device time: ${_fmt(clock.now)}\n',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const TextSpan(
                      text: 'Codes depend on an accurate clock. Enable '
                          'automatic date & time in Android settings.'),
                ]),
                style: TextStyle(
                    fontSize: 12, color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
