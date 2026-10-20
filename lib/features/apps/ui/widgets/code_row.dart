import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:st_authenticator/core/otp/totp.dart';
import 'package:st_authenticator/core/theme/app_theme.dart';
import 'package:st_authenticator/core/theme/palette.dart';
import 'package:st_authenticator/features/apps/models/auth_app.dart';
import 'package:st_authenticator/features/apps/state/app_scope.dart';
import 'package:st_authenticator/features/apps/ui/widgets/countdown_ring.dart';

enum CardAction { edit, delete, fullScreen }

/// Copies the current code and gives a light haptic tap. Visual confirmation
/// is up to the caller (see [CodeRow] and the full-screen view).
Future<void> copyCode(BuildContext context, AuthApp app) async {
  final code = app.codeAt(AppScope.of(context).clock.now);
  HapticFeedback.lightImpact();
  await Clipboard.setData(ClipboardData(text: code));
}

class CodeRow extends StatefulWidget {
  const CodeRow({super.key, required this.app, required this.onAction});

  final AuthApp app;
  final void Function(CardAction) onAction;

  @override
  State<CodeRow> createState() => _CodeRowState();
}

class _CodeRowState extends State<CodeRow> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await copyCode(context, widget.app);
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final clock = AppScope.of(context).clock;
    final colors = context.colors;

    return InkWell(
      onTap: _copy,
      highlightColor: colors.fill,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: ListenableBuilder(
          listenable: clock,
          builder: (context, _) {
            final now = clock.now;
            final left = app.secondsLeftAt(now);
            final urgent = left <= urgentSeconds;
            return Row(
              children: [
                _Monogram(name: app.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _copied
                              ? Row(
                                  key: const ValueKey('copied'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: colors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copied',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: colors.accent,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  app.name,
                                  key: const ValueKey('name'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.secondary,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.5,
                            height: 1.15,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: urgent ? colors.warning : colors.label,
                          ),
                          child: Text(Totp.formatCode(app.codeAt(now))),
                        ),
                      ],
                    ),
                  ),
                ),
                CountdownRing(secondsLeft: left, period: app.periodSeconds),
                const SizedBox(width: 2),
                RowMenu(onSelected: widget.onAction),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        name.characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colors.accent,
        ),
      ),
    );
  }
}

/// The overflow ("more") button with Show full-screen / Edit / Delete.
class RowMenu extends StatelessWidget {
  const RowMenu({super.key, required this.onSelected});
  final void Function(CardAction) onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<CardAction>(
      tooltip: 'More',
      icon: Icon(Icons.more_horiz_rounded, color: colors.tertiary),
      onOpened: HapticFeedback.selectionClick,
      onSelected: onSelected,
      offset: const Offset(0, 40),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      constraints: const BoxConstraints(minWidth: 210),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.divider),
      ),
      itemBuilder: (_) => [
        _item(CardAction.fullScreen, Icons.fullscreen_rounded,
            'Show full-screen', colors.label, colors.secondary),
        _item(CardAction.edit, Icons.edit_outlined, 'Edit', colors.label,
            colors.secondary),
        const PopupMenuDivider(height: 8),
        _item(CardAction.delete, Icons.delete_outline_rounded, 'Delete',
            colors.danger, colors.danger),
      ],
    );
  }

  PopupMenuItem<CardAction> _item(
    CardAction value,
    IconData icon,
    String label,
    Color textColor,
    Color iconColor,
  ) {
    return PopupMenuItem(
      value: value,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
