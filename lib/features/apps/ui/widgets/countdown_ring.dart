import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:st_authenticator/core/theme/app_theme.dart';
import 'package:st_authenticator/core/theme/palette.dart';

/// Thin ring that drains continuously across each second. The shared clock only
/// ticks once per second, so every tick animates from the current fraction to
/// the next one over a linear second, which reads as smooth motion.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.secondsLeft,
    required this.period,
    this.size = 28,
    this.strokeWidth,
    this.showLabel = false,
  });

  final int secondsLeft;
  final int period;
  final double size;
  final double? strokeWidth;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final urgent = secondsLeft <= urgentSeconds;
    final color = urgent ? colors.warning : colors.accent;
    final from = secondsLeft / period;
    final to = math.max(secondsLeft - 1, 0) / period;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: '$secondsLeft seconds remaining',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(secondsLeft),
              tween: Tween(begin: reduceMotion ? to : from, end: to),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(seconds: 1),
              curve: Curves.linear,
              builder: (_, value, _) => CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  progress: value,
                  color: color,
                  track: colors.divider,
                  stroke: strokeWidth ?? math.max(2, size / 12),
                ),
              ),
            ),
            if (showLabel)
              Text(
                '$secondsLeft',
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w500,
                  color: urgent ? colors.warning : colors.label,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0.0, 1.0),
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
