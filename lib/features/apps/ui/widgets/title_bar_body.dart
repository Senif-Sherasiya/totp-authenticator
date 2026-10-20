import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:st_authenticator/core/theme/app_theme.dart';

/// A scroll view under a fixed large-title bar. The title never moves or
/// shrinks; the content scrolls behind a translucent, blurred bar, and a
/// hairline fades in once the content is underneath it.
class TitleBarBody extends StatefulWidget {
  const TitleBarBody({
    super.key,
    required this.title,
    required this.slivers,
    this.trailing,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;

  @override
  State<TitleBarBody> createState() => _TitleBarBodyState();
}

class _TitleBarBodyState extends State<TitleBarBody> {
  static const _titleArea = 64.0;

  final _scroll = ScrollController();
  bool _under = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final under = _scroll.hasClients && _scroll.offset > 0.5;
      if (under != _under) setState(() => _under = under);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = MediaQuery.paddingOf(context).top + _titleArea;
    return Stack(
      children: [
        SafeArea(
          top: false,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: height)),
              ...widget.slivers,
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background.withValues(alpha: 0.85),
                  border: Border(
                    bottom: BorderSide(
                      color: _under ? colors.divider : Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.page,
                      0,
                      Gap.page,
                      8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                                color: colors.label,
                              ),
                            ),
                          ),
                        ),
                        if (widget.trailing != null) widget.trailing!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
