import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:st_authenticator/core/otp/totp.dart';
import 'package:st_authenticator/features/apps/models/auth_app.dart';
import 'package:st_authenticator/features/apps/state/app_scope.dart';
import 'package:st_authenticator/features/apps/ui/widgets/countdown_ring.dart';
import 'package:st_authenticator/core/theme/palette.dart';

enum CardAction { edit, delete, fullScreen }

Future<void> copyCode(BuildContext context, AuthApp app) async {
  final scope = AppScope.of(context);
  final code = app.codeAt(scope.clock.now);
  await Clipboard.setData(ClipboardData(text: code));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('${app.name} code copied')));
}

class CodeCard extends StatelessWidget {
  const CodeCard({super.key, required this.app, required this.onAction});

  final AuthApp app;
  final void Function(CardAction) onAction;

  @override
  Widget build(BuildContext context) {
    final clock = AppScope.of(context).clock;
    final accent = Color(app.colorValue);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => copyCode(context, app),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: ListenableBuilder(
            listenable: clock,
            builder: (context, _) {
              final now = clock.now;
              final left = app.secondsLeftAt(now);
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    child: Text(app.name.characters.first.toUpperCase()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Totp.formatCode(app.codeAt(now)),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: urgencyColor(left, accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CountdownRing(
                    secondsLeft: left,
                    period: app.periodSeconds,
                    color: accent,
                  ),
                  PopupMenuButton<CardAction>(
                    onSelected: onAction,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: CardAction.fullScreen,
                        child: Text('Show full-screen'),
                      ),
                      PopupMenuItem(
                        value: CardAction.edit,
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: CardAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
