import 'package:flutter/material.dart';

import 'package:st_authenticator/core/theme/app_theme.dart';

/// An inset rounded group of rows with hairline dividers, with an optional
/// small header above and footnote below.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
  });

  final List<Widget> children;
  final String? header;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              header!.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0.2,
                color: colors.secondary,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Gap.radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: 52),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              footer!,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: colors.secondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// A row with a small accent icon in a tinted square, then [child].
class FormRow extends StatelessWidget {
  const FormRow({super.key, this.icon, required this.child});

  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            SizedBox(
              height: 52,
              child: Center(child: Icon(icon, size: 22, color: colors.accent)),
            ),
          if (icon != null) const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}
