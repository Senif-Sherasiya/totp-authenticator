import 'package:flutter/material.dart';

import 'package:st_authenticator/core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(child: _PlaceholderRow()),
              const SizedBox(height: 32),
              Text(
                'No apps yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add an app to see its verification codes here. You can scan '
                'its QR code or enter the secret key.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 50)),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Add app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A faint skeleton of a code row, hinting at what will appear here.
class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Gap.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(72, 10), const SizedBox(height: 12), bar(150, 22)],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
              color: colors.accent.withValues(alpha: 0.5),
              backgroundColor: colors.divider,
            ),
          ),
        ],
      ),
    );
  }
}
