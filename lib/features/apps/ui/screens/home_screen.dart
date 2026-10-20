import 'package:flutter/material.dart';

import 'package:st_authenticator/features/apps/state/app_scope.dart';
import 'package:st_authenticator/features/apps/ui/screens/app_form_screen.dart';
import 'package:st_authenticator/features/apps/ui/widgets/code_card.dart';
import 'package:st_authenticator/features/apps/ui/widgets/dialogs.dart';
import 'package:st_authenticator/features/apps/ui/screens/full_screen_code.dart';
import 'package:st_authenticator/features/apps/ui/widgets/time_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _add(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AppFormScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Authenticator')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Add app'),
      ),
      body: Column(
        children: [
          const TimeBanner(),
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(controller.error!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: controller.load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final apps = controller.apps;
                if (apps.isEmpty)
                  return _EmptyState(onAdd: () => _add(context));
                return ReorderableListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 96),
                  itemCount: apps.length,
                  onReorderItem: controller.reorder,
                  itemBuilder: (context, i) {
                    final app = apps[i];
                    return CodeCard(
                      key: ValueKey(app.id),
                      app: app,
                      onAction: (a) async {
                        switch (a) {
                          case CardAction.fullScreen:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenCode(appId: app.id),
                              ),
                            );
                          case CardAction.edit:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppFormScreen(existing: app),
                              ),
                            );
                          case CardAction.delete:
                            if (await confirmDelete(context, app)) {
                              await controller.delete(app.id);
                            }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Add your first app',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter an app name and its secret, or scan its otpauth:// QR code.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add app'),
            ),
          ],
        ),
      ),
    );
  }
}
