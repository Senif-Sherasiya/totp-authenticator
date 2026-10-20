import 'dart:async';

import 'package:flutter/material.dart';

import 'package:st_authenticator/core/otp/totp.dart';
import 'package:st_authenticator/core/theme/app_theme.dart';
import 'package:st_authenticator/core/theme/palette.dart';
import 'package:st_authenticator/features/apps/models/auth_app.dart';
import 'package:st_authenticator/features/apps/state/app_scope.dart';
import 'package:st_authenticator/features/apps/ui/widgets/code_row.dart';
import 'package:st_authenticator/features/apps/ui/widgets/countdown_ring.dart';

class FullScreenCode extends StatefulWidget {
  const FullScreenCode({super.key, required this.appId});
  final String appId;

  @override
  State<FullScreenCode> createState() => _FullScreenCodeState();
}

class _FullScreenCodeState extends State<FullScreenCode> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy(AuthApp app) async {
    await copyCode(context, app);
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final colors = context.colors;
    return ListenableBuilder(
      listenable: Listenable.merge([scope.controller, scope.clock]),
      builder: (context, _) {
        final app = scope.controller.byId(widget.appId);
        if (app == null) {
          // Deleted or renamed away while open.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.maybePop(context);
          });
          return const Scaffold();
        }
        final now = scope.clock.now;
        final left = app.secondsLeftAt(now);
        final expiring = left <= urgentSeconds;
        return Scaffold(
          appBar: AppBar(title: Text(app.name)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Gap.page),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 84,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: expiring ? colors.warning : colors.label,
                      ),
                      child: Text(Totp.formatCode(app.codeAt(now))),
                    ),
                  ),
                  const SizedBox(height: 40),
                  CountdownRing(
                    secondsLeft: left,
                    period: app.periodSeconds,
                    size: 96,
                    strokeWidth: 4,
                    showLabel: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: expiring ? 1 : 0,
                      child: Column(
                        children: [
                          Text(
                            'Next code',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.secondary,
                            ),
                          ),
                          Text(
                            Totp.formatCode(app.codeAt(now, stepOffset: 1)),
                            style: TextStyle(
                              fontSize: 22,
                              letterSpacing: 2,
                              color: colors.secondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    onPressed: () => _copy(app),
                    icon: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 20,
                    ),
                    label: Text(_copied ? 'Copied' : 'Copy'),
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
