import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:st_authenticator/core/theme/app_theme.dart';
import 'package:st_authenticator/features/apps/state/app_scope.dart';
import 'package:st_authenticator/features/apps/ui/screens/app_form_screen.dart';
import 'package:st_authenticator/features/apps/ui/screens/full_screen_code.dart';
import 'package:st_authenticator/features/apps/ui/widgets/code_row.dart';
import 'package:st_authenticator/features/apps/ui/widgets/dialogs.dart';
import 'package:st_authenticator/features/apps/ui/widgets/empty_state.dart';
import 'package:st_authenticator/features/apps/ui/widgets/title_bar_body.dart';
import 'package:st_authenticator/features/apps/ui/widgets/time_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _add(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final colors = context.colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        floatingActionButton: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.apps.isEmpty
              ? const SizedBox.shrink()
              : FloatingActionButton(
                  tooltip: 'Add app',
                  onPressed: () => _add(context),
                  child: const Icon(Icons.add_rounded, size: 30),
                ),
        ),
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final apps = controller.apps;
            final loading = controller.loading;
            final error = controller.error;
            return TitleBarBody(
              title: 'Authenticator',
              trailing: const TimeButton(),
              slivers: [
                if (loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accent,
                      ),
                    ),
                  )
                else if (error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              error,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.secondary),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(140, 50),
                              ),
                              onPressed: controller.load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (apps.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                        Expanded(child: EmptyState(onAdd: () => _add(context))),
                      ],
                    ),
                  )
                else ...[
                  _Subtitle(
                    apps.length == 1
                        ? '1 app · tap a code to copy'
                        : '${apps.length} apps · tap a code to copy',
                    sliver: true,
                  ),
                  SliverReorderableList(
                    itemCount: apps.length,
                    onReorderItem: controller.reorder,
                    onReorderStart: (_) => HapticFeedback.mediumImpact(),
                    proxyDecorator: (child, _, animation) => Material(
                      color: colors.surface,
                      elevation: 4 * Curves.easeOut.transform(animation.value),
                      shadowColor: Colors.black38,
                      borderRadius: BorderRadius.circular(Gap.radius),
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    ),
                    itemBuilder: (context, i) {
                      final app = apps[i];
                      final first = i == 0;
                      final last = i == apps.length - 1;
                      const r = Radius.circular(Gap.radius);
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(app.id),
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Material(
                            color: colors.surface,
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.vertical(
                              top: first ? r : Radius.zero,
                              bottom: last ? r : Radius.zero,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CodeRow(
                                  app: app,
                                  onAction: (a) async {
                                    switch (a) {
                                      case CardAction.fullScreen:
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                FullScreenCode(appId: app.id),
                                          ),
                                        );
                                      case CardAction.edit:
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AppFormScreen(existing: app),
                                          ),
                                        );
                                      case CardAction.delete:
                                        if (await confirmDelete(context, app)) {
                                          await controller.delete(app.id);
                                        }
                                    }
                                  },
                                ),
                                if (!last) const Divider(indent: 16 + 40 + 12),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text, {this.sliver = false});
  final String text;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    final w = Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, color: context.colors.secondary),
      ),
    );
    return sliver ? SliverToBoxAdapter(child: w) : w;
  }
}
