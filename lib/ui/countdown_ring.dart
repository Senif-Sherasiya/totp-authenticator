import 'package:flutter/material.dart';

import 'palette.dart';

class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.secondsLeft,
    required this.period,
    this.size = 44,
    this.color,
  });

  final int secondsLeft;
  final int period;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = urgencyColor(secondsLeft, color ?? scheme.primary);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: secondsLeft / period,
              strokeWidth: size / 11,
              color: c,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          Text('$secondsLeft',
              style: TextStyle(
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w600,
                  color: c)),
        ],
      ),
    );
  }
}
