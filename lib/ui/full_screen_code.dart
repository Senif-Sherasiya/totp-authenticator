import 'package:flutter/material.dart';

import '../core/totp.dart';
import 'app_scope.dart';
import 'code_card.dart';
import 'countdown_ring.dart';
import 'palette.dart';

class FullScreenCode extends StatelessWidget {
  const FullScreenCode({super.key, required this.appId});
  final String appId;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.controller, scope.clock]),
      builder: (context, _) {
        final app = scope.controller.byId(appId);
        if (app == null) {
          // Deleted or renamed away while open.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.maybePop(context);
          });
          return const Scaffold();
        }
        final now = scope.clock.now;
        final left = app.secondsLeftAt(now);
        final accent = Color(app.colorValue);
        final color = urgencyColor(left, accent);
        final expiring = left <= 5;
        return Scaffold(
          appBar: AppBar(title: Text(app.name)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Totp.formatCode(app.codeAt(now)),
                      style: TextStyle(
                        fontSize: 88,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CountdownRing(
                      secondsLeft: left,
                      period: app.periodSeconds,
                      size: 120,
                      color: accent),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: expiring
                        ? Column(children: [
                            Text('Next code',
                                style: Theme.of(context).textTheme.labelMedium),
                            Text(
                              Totp.formatCode(app.codeAt(now, stepOffset: 1)),
                              style: const TextStyle(
                                  fontSize: 20,
                                  letterSpacing: 2,
                                  fontFeatures: [FontFeature.tabularFigures()]),
                            ),
                          ])
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => copyCode(context, app),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
